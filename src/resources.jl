using PortAudio: stop, close
using LibSndFile
using SampledSignals

"""
    play_music(filename::String, loops::Integer=0, volume::Real=1.0)
play_sound(filename::String, loops::Integer, volume::Real)

Plays a sound effect from the `sounds` subdirectory. It will play the specified number of times. If not specified, it will default to once.
"""

MUSIC_STREAM = Ref{Any}(nothing)


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

    Threads.@spawn begin
        for _ in 0:loops
            stream = PortAudioStream(0, nchannels(buf); samplerate=samplerate(buf))
            MUSIC_STREAM[] = stream  # Save the stream object
            write(stream, buf)
            close(stream)
            MUSIC_STREAM[] = nothing  # Clear after closing
        end
    end
end

function stop_music()
    if MUSIC_STREAM[] !== nothing && MUSIC_STREAM[] isa PortAudioStream
        close(MUSIC_STREAM[])
        MUSIC_STREAM[] = nothing
    end
end

const resource_ext = Dict(
    :images=>"[png|jpg|jpeg]",
    :sounds=>"[mp3|ogg|wav]",
    :music=>"[mp3|ogg|wav]"
)

# Add a resource cache to prevent reloading the same assets
const RESOURCE_CACHE = Dict{String, Any}()

function image_surface(img_path::String)
    # Check cache first
    if haskey(RESOURCE_CACHE, img_path)
        return RESOURCE_CACHE[img_path]
    end
    
    sf = IMG_Load(img_path)
    if sf == C_NULL
        throw("Error loading $img_path")
    end
    
    # Cache the surface
    RESOURCE_CACHE[img_path] = sf
    return sf
end

function file_path(name::String, subdir::Symbol)
    path = joinpath(game[].location, String(subdir))
    @assert isdir(path)
    allfiles = readdir(path)
    allexts = resource_ext[subdir]
    validate_name(name)

    for x in allfiles

        if occursin(Regex("$(name)(\\.$(allexts))?", "i"), x)
            return joinpath(path, x)
        end
    end

    # We try to return helpful messages if the file could not be found
    for x in allfiles

        if basename(x) == name
            @warn "Did you mean $x? We can only handle the follwing extensions: $allexts"
        end

        if edit_distance(x, name) / length(name) <= .5
            @warn "Did you mean $x instead of $names. Please check your spelling."
        end

    throw(ArgumentError("No file: $name in $path")); end
end

# Add a cleanup function
function clear_resource_cache!()
    for (_, resource) in RESOURCE_CACHE
        if resource isa Ptr{SDL_Surface}
            SDL_FreeSurface(resource)
        elseif resource isa Ptr{SDL_Texture}
            SDL_DestroyTexture(resource)
        end
    end
    empty!(RESOURCE_CACHE)
end
