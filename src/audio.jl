"""
    play_music(filename::String, loops::Integer=0, volume::Real=1.0)
play_sound(filename::String, loops::Integer, volume::Real)

Plays a sound effect from the `sounds` subdirectory. It will play the specified number of times. If not specified, it will default to once.
"""

const MUSIC_STREAM = Ref{Any}(nothing)

const MUSIC_STOP_REQUESTED = Ref(false)

# Preload sounds at startup
const SOUND_CACHE = Dict{String, SampleBuf}()

function play_sound(sound_path::String; loops=0, volume=1.0)
    buf = load(sound_path)  # LibSndFile returns a SampleBuf
    # Adjust volume
    buf = buf * volume
    Threads.@spawn begin
        for _ in 0:loops
            stream = PortAudioStream(0, nchannels(buf); samplerate=samplerate(buf))
            write(stream, buf)
            close(stream)
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

# Ensure audio cleanup during precompilation
function __init__()
    atexit(() -> begin
        # Stop any playing music during shutdown
        stop_music()
        # Clear sound cache to free memory
        empty!(SOUND_CACHE)
    end)
end
