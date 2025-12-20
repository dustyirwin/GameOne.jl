"""
    play_music(filename::String, loops::Integer=0, volume::Real=1.0)
play_sound(filename::String, loops::Integer, volume::Real)

Plays a sound effect from the `sounds` subdirectory. It will play the specified number of times. If not specified, it will default to once.
"""

const MUSIC_STREAM = Ref{Any}(nothing)

const MUSIC_STOP_REQUESTED = Ref(false)

# Preload sounds at startup
const SOUND_CACHE = Dict{String, SampleBuf}()

# Preload a sound into cache (non-blocking when called in a task)
function preload_sound(sound_path::String)
    if !haskey(SOUND_CACHE, sound_path)
        try
            buf = load(sound_path)
            SOUND_CACHE[sound_path] = buf
        catch e
            @warn "Failed to preload sound $sound_path: $e"
        end
    end
end

# Play a sound effect. Uses a cache when available to avoid blocking disk I/O.
function play_sound(sound_path::String; loops=0, volume=1.0)
    if haskey(SOUND_CACHE, sound_path)
        buf = SOUND_CACHE[sound_path] * volume
        @spawn :interactive begin
            for _ in 0:loops
                stream = PortAudioStream(0, nchannels(buf); samplerate=samplerate(buf))
                write(stream, buf)
                close(stream)
            end
        end
    else
        # Load and play asynchronously so the calling thread (UI/game loop) isn't blocked
        @spawn :interactive try
            buf = load(sound_path)
            SOUND_CACHE[sound_path] = buf
            buf = buf * volume
            for _ in 0:loops
                stream = PortAudioStream(0, nchannels(buf); samplerate=samplerate(buf))
                write(stream, buf)
                close(stream)
            end
        catch e
            @warn "Failed to load/play sound $sound_path: $e"
        end
    end
end

function play_music(music_path::String; loops=0, volume=1.0)
    buf = load(music_path)
    buf = buf * volume
    chunk_size = 16384  # Number of samples per chunk, adjust as needed

    Threads.@spawn begin
        for _ in 0:loops
            stream = PortAudioStream(0, nchannels(buf); samplerate=samplerate(buf))
            MUSIC_STREAM[] = stream
            idx = 1
            while idx <= length(buf)
                end_idx = min(idx + chunk_size - 1, length(buf))
                write(stream, buf[idx:end_idx])
                idx = end_idx + 1
                yield()  # Allow other threads to run
            end
            close(stream)
            MUSIC_STREAM[] = nothing
        end
    end
end

function stop_music()
    if MUSIC_STREAM[] !== nothing && MUSIC_STREAM[] isa PortAudioStream
        try
            close(MUSIC_STREAM[])
        catch e
            @warn "Error closing music stream: $e"
        end
        MUSIC_STREAM[] = nothing
    end
    MUSIC_STOP_REQUESTED[] = false
end


export play_music, stop_music, play_sound, preload_sound, SOUND_CACHE, MUSIC_STREAM, MUSIC_STOP_REQUESTED