
mutable struct Actor
    id::String
    label::String
    surfaces::Vector{Ptr{SDL_Surface}}
    textures::Vector{Ptr{SDL_Texture}}
    position::SDL_Rect
    scale::Vector{Float32}
    rotate_center::Union{Vector{Int32},Ptr{Nothing}}
    angle::Float64
    alpha::UInt8
    data::Dict{Symbol,Any}
end

function ImageActor(img_name::String, img; x=0, y=0, kv...) 
    img = ARGB.(transpose(img))
    w, h = Int32.(size(img))
    sf = SDL_CreateRGBSurfaceWithFormatFrom(
        img,
        w,
        h,
        Int32(32),
        Int32(4w),
        SDL_PIXELFORMAT_ARGB32,
    )

    r = SDL_Rect(x, y, w, h)
    a = Actor(
        randstring(10),
        img_name,
        [sf],
        [],
        r,
        [1.,1.],
        C_NULL,
        0,
        255,
        Dict(
            :anim => false,
            :label=>img_name,
            :img=>img,
            :sz=>[w,h],
            :fade_in=>false,           #  change to fade_in? remove anim-specific keys (add k,v when anim is run?)
            :fade_out=>false,
            :spin=>false,
            :spin_cw=>true,
            :shake=>false,
            :mouse_offset=>Int32[0,0],
        )
    )

    for (k, v) in kv
        setproperty!(a, k, v)
    end
    return a
end

function TextActor(text::String, font_path::String; x = 0, y = 0, pt_size = 24,
    font_color = Int[255, 255, 255, 255], outline_color = Int[0, 0, 0, 225],
    wrap_length = 800, outline_size = 0, kv...)

    text_font = TTF_OpenFont(font_path, pt_size)
    fg = TTF_RenderText_Blended_Wrapped(text_font, text, SDL_Color(font_color...), UInt32(wrap_length))
    w, h = size(fg)
    r = SDL_Rect(x, y, w, h)
    
    fg = if outline_size > 0
        outline_font = TTF_OpenFont(font_path, pt_size)
        TTF_SetFontOutline(outline_font, Int32(outline_size))
        bg = TTF_RenderText_Blended_Wrapped(outline_font, text, SDL_Color(outline_color...), UInt32(wrap_length))
        SDL_UpperBlitScaled(fg, C_NULL, bg, Int32[outline_size,outline_size, w, h])
        bg
    else
        fg
    end

    TTF_CloseFont(text_font)

    a = Actor(
        randstring(10),
        text,
        [fg],
        [],
        r,
        [1., 1.],
        C_NULL,
        0,
        255,
        Dict(
            :sz => [w, h],
            :fade_in => false,
            :fade_out => false,
            :spin => false,
            :spin_cw => true,
            :shake => false,
            :next_frame => false,
            :font_path => font_path,
            :pt_size => pt_size,
            :outline_size => outline_size,
            :outline_color => outline_color,
            :wrap_length => wrap_length,
            :mouse_offset => Int32[0, 0],
            :font_color => font_color,
            )
        )
    
    for (k, v) in kv
        setproperty!(a, k, v)
    end

    return a
end

function update_text_actor!(a::Actor, new_text::String)
    font = TTF_OpenFont(a.data[:font_path], a.data[:pt_size])

    fg = TTF_RenderText_Blended_Wrapped(
        font, new_text, SDL_Color(a.data[:font_color]...), UInt32(a.data[:wrap_length]))
    
    w, h = size(fg)
    
    fg = if a.data[:outline_size] > 0
        outline_font = TTF_OpenFont(a.data[:font_path], a.data[:pt_size])
        TTF_SetFontOutline(outline_font, Int32(a.data[:outline_size]))
        bg = TTF_RenderText_Blended_Wrapped(
            outline_font, new_text, SDL_Color(a.data[:outline_color]...), UInt32(a.data[:wrap_length]))
        SDL_UpperBlitScaled(fg, C_NULL, bg, Int32[a.data[:outline_size], a.data[:outline_size], w, h])
        bg
    else
        fg
    end

    a.surfaces = [fg]
    a.w, a.h = size(a.surfaces[begin])
    a.textures = []
    a.label = new_text
    return a
end

LoadBMP(src::String) = SDL_LoadBMP_RW(src, 1)

function ImageFileAnimActor(anim_name::String, img_fns::Vector{String}; x=0, y=0, frame_delays=[], kv...)
    n = Int32.(length(img_fns))
    frame_delays = isempty(frame_delays) ? [ Millisecond(100) for _ in 1:n ] : frame_delays
    surfaces = [ IMG_Load(fn) for fn in img_fns ]
    w, h = Int32.(size(surfaces[begin]))
    
    r = SDL_Rect(x, y, w, h)
    a = Actor(
        randstring(10),
        anim_name,
        surfaces,
        [],
        r,
        [1,1],
        C_NULL,
        0,
        255,
        Dict(
            :anim => true,
            :label => anim_name,
            :img_fns => img_fns,
            :sz => [w, h],
            :fade_in => false,
            :fade_out => false,
            :spin => false,
            :spin_cw => true,
            :shake => false,
            :then => now(),
            :next_frame => false,
            :frame_delays => frame_delays,
            :mouse_offset => Int32[0, 0],
        )
    )


    for (k, v) in kv
        setproperty!(a, k, v)
    end
    return a
end

function WebpAnimActor(anim_name::String, webp_fn::String; x=0, y=0, kv...)
    if !isdir(joinpath(tempdir(),"anim_$anim_name"))
        mkdir(joinpath(tempdir(),"anim_$anim_name"))
    end

    webp_txt = joinpath(tempdir(), "anim_$anim_name", "webp_info_$anim_name.txt")
    
    webpmux() do webpmux
        redirect_stdio(stdout=webp_txt) do
            run(`$webpmux -info $webp_fn`)
        end
    end
    
    webp_info = readlines(webp_txt)

    w = [ parse(Int32, split(ln)[3]) |> Int32 for ln in webp_info if occursin("Canvas size:", ln) ][1]
    h = [ parse(Int32, split(ln)[5]) |> Int32 for ln in webp_info if occursin("Canvas size:", ln) ][1]
    n = [ parse(Int32, split(ln)[4]) |> Int32 for ln in webp_info if occursin("frames:", ln) ][1]
    
    frame_data = webp_info[6:end]
    frames = Dict()
    
    for i in 1:n
        d = Dict(
            :width => parse(Int32, split(frame_data[i])[2]),
            :height => parse(Int32, split(frame_data[i])[3]),
            :x_offset => parse(Int32, split(frame_data[i])[5]),
            :y_offset => parse(Int32, split(frame_data[i])[6]),
            :duration => parse(Int32, split(frame_data[i])[7]),
            :dispose => split(frame_data[i])[8],
        )
        
        frames[i] = d
    end
    
    frame_delays = [ Millisecond(v[:duration]) for (k,v) in sort(frames) ]

    # exporting each webp frame as a keyframe
    for i in 1:n
        tmp_png = joinpath(tempdir(), "anim_$anim_name", "frame_$i.png")
        tmp_webp = joinpath(tempdir(), "anim_$anim_name", "frame_$i.webp")
        
        if !isfile(tmp_png)
            
            if !isfile(tmp_webp)
                webpmux() do webpmux
                    run(`$webpmux -get frame $i $webp_fn -o $tmp_webp`)
                end
            end

            dwebp() do dwebp
                run(`$dwebp -quiet $tmp_webp -o $tmp_png`)
            end

            # TESTING 
            # rm(tmp_webp)
        end
    end

    surfaces = Dict()
    
    for i in 1:n

        # handling all frames as key frames
        surfaces[i] = IMG_Load(joinpath(tempdir(), "anim_$anim_name", "frame_$i.png"))
        
        #=  THIS IS NOT WORKING YET
        if i == 1
             
        
        # handling frame dispose "none"
        elseif frames[i-1][:dispose] == "none"
            # creating empty surface to blit on
            surfaces[i] = SDL_CreateRGBSurface(0, w, h, 32, 0, 0, 0, 0)
            #SDL_FillRect(surfaces[i], C_NULL, 0x00000000)  # fill with black color

            # filling empty surface with previous frame
            SDL_BlitSurface(
                surfaces[i-1],      # source surface
                C_NULL,
                surfaces[i],        # destination surface
                Int32[ frames[i][:x_offset], frames[i][:y_offset], 0, 0 ]
            )

            # blitting current frame on top of previous frame
            IMG_Load(joinpath(tempdir(), "anim_$anim_name", "frame_$i.png"))
            SDL_BlitSurface(
                IMG_Load(joinpath(tempdir(), "anim_$anim_name", "frame_$i.png")),
                C_NULL,
                surfaces[i],
                Int32[ frames[i][:x_offset], frames[i][:y_offset], 0, 0 ]
            )
        
        # handling frame dispose "background"
        elseif frames[i-1][:dispose] == "background"
            surfaces[i] = IMG_Load(joinpath(tempdir(), "anim_$anim_name", "frame_1.png"))
            SDL_BlitSurface(
                IMG_Load(joinpath(tempdir(), "anim_$anim_name", "frame_$i.png")),
                C_NULL,
                surfaces[i],
                Int32[ frames[i][:x_offset], frames[i][:y_offset], 0, 0 ]
            )
        
        # handling frame dispose "replace"
        elseif frames[i-1][:dispose] == "replace"
            sf = IMG_Load(joinpath(tempdir(), "anim_$anim_name", "frame_$i.png"))
            surfaces[i] = sf
        
        else
            sf = IMG_Load(joinpath(tempdir(), "$anim_name-frame_$i.png"))
            surfaces[i] = SDL_CreateRGBSurface(0, w, h, 32, 0x00ff0000, 0x0000ff00, 0x000000ff, 0xff000000)
            SDL_FillRect(surfaces[i], C_NULL, 0x00000000)
            SDL_BlitSurface(
                sf,
                C_NULL,
                surfaces[i],
                Int32[ frames[i][:x_offset], frames[i][:y_offset], 0, 0 ]
            )
        end
        =#
    end

    w, h = Int32.(size(surfaces[1]))
    r = SDL_Rect(x, y, w, h)
    a = Actor(
        randstring(10),
        anim_name,
        [values(sort(surfaces))...],
        [],
        r,
        [1,1],
        C_NULL,
        0,
        255,
        Dict(
            :anim => true,
            :label => anim_name,
            :img_fn => webp_fn,
            :sz => [w, h],
            :fade_in => false,
            :fade_out => false,
            :spin => false,
            :spin_cw => true,
            :shake => false,
            :then => now(),
            :next_frame => false,
            :frame_delays => frame_delays,
            :mouse_offset => Int32[0, 0],
        )
    )
            
    for (k, v) in kv
        setproperty!(a, k, v)
    end
    
    return a
end

function draw(a::Actor, s::Screen=game[].screen[begin])
    
    if isempty(a.textures)
        
        for (i, sf) in enumerate(a.surfaces)
            tx = SDL_CreateTextureFromSurface(s.renderer, sf)

            if tx == C_NULL
                @warn "Failed to create texture $i for $(a.label)! Fall back to CPU?"
            end

            push!(a.textures, tx)
        end

        for sf in a.surfaces
            SDL_FreeSurface(sf)
        end
    end

    if a.alpha < 255
        SDL_SetTextureBlendMode(a.textures[begin], SDL_BLENDMODE_BLEND)
        SDL_SetTextureAlphaMod(a.textures[begin], a.alpha)
    end

    flip = if a.w < 0 && a.h < 0
        SDL_FLIP_BOTH
    elseif a.h < 0
        SDL_FLIP_VERTICAL
    elseif a.w < 0
        SDL_FLIP_HORIZONTAL
    else
        SDL_FLIP_NONE
    end

    SDL_RenderCopyEx(
        s.renderer,
        a.textures[begin],
        C_NULL,
        Ref(SDL_Rect(Int32[ a.x, a.y, ceil(a.w * a.scale[1]), ceil(a.h * a.scale[2]) ]...)),
        a.angle,
        a.rotate_center,
        flip,
    )
    #=
    if length(a.textures) == 1
        SDL_DestroyTexture(a.textures[begin])
    end
    =#
end

function Base.setproperty!(s::Actor, p::Symbol, x)
    
    if hasfield(Actor, p)
        setfield!(s, p, convert(fieldtype(Actor, p), x))
    else
        position = getfield(s, :position)
        v = getproperty(position, p)

        if v !== nothing
            setproperty!(position, p, x)

        else
            getfield(s, :data)[p] = x
        end
    end
end

function Base.getproperty(s::Actor, p::Symbol)
    if hasfield(Actor, p)
        getfield(s, p)

    else
        position = getfield(s, :position)
        v = getproperty(position, p)

        if v !== nothing
            return v
        else
            data = getfield(s, :data)

            if haskey(data, p)
                return data[p]
            else
                @warn "Unknown data $p requested from Actor($(s.label))"
                return nothing
            end
        end
    end
end

"""Angle to the horizontal, of the line between two actors, in degrees"""
function Base.angle(a::Actor, target::Actor)
    angle(a, a.pos...)
end

Base.angle(a::Actor, txy::Tuple) = angle(a, txy[1], txy[2])

"""Angle to the horizontal, of the line between an actor and a point in space, in degrees"""
function Base.angle(a::Actor, tx, ty)
    myx, myy = a.pos
    dx = tx - myx
    dy = myy - ty
    return deg2rad(atan(dy/dx))
end

"""Distance in pixels between two actors"""
function distance(a::Actor, target::Actor)
    distance(a, target.pos...)
end

"""Distance in pixels between an actor and a point in space"""
function distance(a::Actor, tx, ty)
    myx, myy = a.pos
    dx = tx - myx
    dy = ty - myy
    return sqrt(dx * dx + dy * dy)
end

atan2(y, x) = pi - pi/2 * (1 + sign(x)) * (1 - sign(y^2)) - pi/4 * (2 + sign(x)) * sign(y) -
                            sign(x*y) * atan((abs(x) - abs(y)) / (abs(x) + abs(y)))


function Base.size(s::Ptr{SDL_Surface})
    ss = unsafe_load(s)
    (ss.w, ss.h)
end

function collide(a, x::Integer, y::Integer)
    a=rect(a)
    a.x <= x < (a.x + a.w) && a.y <= y < (a.y + a.h)
end

collide(a, pos::Tuple) = collide(a, pos[1], pos[2])

function collide(c, d)
    a=rect(c)
    b=rect(d)

    return a.x < b.x + b.w &&
        a.y < b.y + b.h &&
        a.x + a.w > b.x &&
        a.y + a.h > b.y
end

rect(a::Actor) = a.position
