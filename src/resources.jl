
"""
play_sound(filename::String, loops::Integer)

Plays a sound effect from the `sounds` subdirctory. It will play the specified number of times. If not specified, it will default to once.
"""
function play_sound(sound_path::String, loops=0, volume=Int32(128))
    sample=Mix_LoadWAV_RW(SDL_RWFromFile(sound_path, "rb"), 1);
    if sample == C_NULL
        @warn "Could not load sound file: $sound_path\n$(getSDLError())"
    end

    r = Mix_PlayChannelTimed(Int32(-1), sample, Int32(loops), Int32(-1))
    if r == -1
        @warn "Unable to play sound $sound_path\n$(getSDLError())"
    end

    Mix_Volume(r, volume)
end

function play_music(music_path::String, loops=-1)
    music = Mix_LoadMUS(music_path)
    Mix_PlayMusic( music, Int32(loops) )
end

const resource_ext = Dict(
    :images=>"[png|jpg|jpeg]",
    :sounds=>"[mp3|ogg|wav]",
    :music=>"[mp3|ogg|wav]"
)

function image_surface(img_path::String)
    sf = IMG_Load(img_path)

    if sf == C_NULL
        throw("Error loading $img_path")
    end

    sf
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

"""
Simplistic string edit distance method
"""

function edit_distance(x, y)
    #Convert strings to char arrays so that we can index into it
    xx = [i for i in x]
    yy = [i for i in y]

    m=length(xx)
    n=length(yy)

    r = zeros(Int, m+1, n+1)

    # Iterate through substrings
    for i in 1:(m + 1)

        for j in 1:(n + 1)

            if i == 1
                r[i, j] = j
            elseif j == 1
                r[i, j] = i
            elseif xx[i-1] == yy[j-1]
                r[i, j] = r[i-1, j-1]
            else
                r[i, j] = 1 + min(r[i, j-1], r[i-1, j],  r[i-1, j-1])
            end
        end
    end

    r[m+1, n+1]
end

function validate_name(name::String)
    if occursin(' ', name)
        @warn("Do not use spaces in resource names. It may cause problems when moving accross platforms: $name")
    end

    if lowercase(name) != name
        @warn("Use lowercases names for resource files. It is safer when moving between windows and unix: $name")
    end
end
