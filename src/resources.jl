using PortAudio: close
using LibSndFile
using SampledSignals
using Base.Sys

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

# detect if OS is Microsoft Windows 10
function is_windows_10()
    return Sys.iswindows() && Sys.windows_version() >= v"10.0"
end

export is_windows_10