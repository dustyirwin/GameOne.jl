
mutable struct Actor
    const id::String
    label::String
    surfaces::Vector{Ptr{SDL2.SDL_Surface}}
    textures::Vector{Ptr{SDL2.SDL_Texture}}
    position::SDL2.SDL_Rect
    scale::Vector{Float32}
    rotate_center::Union{Vector{Int32},Ptr{Nothing}}
    angle::Float64
    alpha::UInt8
    data::Dict{Symbol,Any}
end

function ImageActor(img_name::String, img; x=0, y=0, kv...) 
    img = ARGB.(transpose(img))
    w, h = Int32.(size(img))
    sf = SDL2.SDL_CreateRGBSurfaceWithFormatFrom(
        img,
        w,
        h,
        Int32(32),
        Int32(4w),
        SDL2.SDL_PIXELFORMAT_ARGB32,
    )

    r = SDL2.SDL_Rect(x, y, w, h)
    a = Actor(
        randstring(10),
        img_name,
        [sf],
        [],
        r,
        [1,1],
        C_NULL,
        0,
        255,
        Dict(
            :anim => false,
            :label=>img_name,
            :img=>img,
            :sz=>[w,h],
            :fade=>false,           #  change to fade_in? remove anim-specific keys (add k,v when anim is run?)
            :fade_out=>true,
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

    text_font = SDL2.TTF_OpenFont(font_path, pt_size)
    fg = SDL2.TTF_RenderText_Blended_Wrapped(text_font, text, SDL2.SDL_Color(font_color...), UInt32(wrap_length))
    w, h = size(fg)
    r = SDL2.SDL_Rect(x, y, w, h)
    
    fg = if outline_size > 0
        outline_font = SDL2.TTF_OpenFont(font_path, pt_size)
        SDL2.TTF_SetFontOutline(outline_font, Int32(outline_size))
        bg = SDL2.TTF_RenderText_Blended_Wrapped(outline_font, text, SDL2.SDL_Color(outline_color...), UInt32(wrap_length))
        SDL2.SDL_UpperBlitScaled(fg, C_NULL, bg, Int32[outline_size,outline_size, w, h])
        bg
    else
        fg
    end

    a = Actor(
        randstring(10),
        text,
        [fg],
        [],
        r,
        [1, 1],
        C_NULL,
        0,
        255,
        Dict(
            :sz => [w, h],
            :fade => false,
            :fade_out => true,
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
    font = SDL2.TTF_OpenFont(a.data[:font_path], a.data[:pt_size])
    fg = SDL2.TTF_RenderText_Blended_Wrapped(font, new_text,
        SDL2.SDL_Color(a.data[:font_color]...), UInt32(a.data[:wrap_length]))
    w, h = size(fg)
    fg = if a.data[:outline_size] > 0
        outline_font = SDL2.TTF_OpenFont(a.data[:font_path], a.data[:pt_size])
        SDL2.TTF_SetFontOutline(outline_font, Int32(a.data[:outline_size]))
        bg = SDL2.TTF_RenderText_Blended_Wrapped(outline_font, new_text, SDL2.SDL_Color(a.data[:outline_color]...), UInt32(a.data[:wrap_length]))
        SDL2.SDL_UpperBlitScaled(fg, C_NULL, bg, Int32[a.data[:outline_size], a.data[:outline_size], w, h])
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

LoadBMP(src::String) = SDL2.SDL_LoadBMP_RW(src, 1)

function AnimActorBMP(anim_name::String, bmp_fns; x=0, y=0, frame_delay=Millisecond(120), kv...)
    n = Int32.(length(bmp_fns))
    frame_delays = [ frame_delay for _ in 1:n ]
    surfaces = [ SDL2.IMG_Load(bmp_fn) for bmp_fn in bmp_fns ]
    w, h = Int32.(size(surfaces[begin]))
    
    r = SDL2.SDL_Rect(x, y, w, h)
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
            :sz => [w, h],
            :fade => false,
            :fade_out => true,
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

function draw(a::Actor)
    if isempty(a.textures)

        for (i, sf) in enumerate(a.surfaces)
            tx = SDL2.SDL_CreateTextureFromSurface(game[].screen.renderer, sf)

            if tx == C_NULL
                @warn "Failed to create texture $i for $(a.label)! Fall back to CPU?"
            end

            push!(a.textures, tx)
        end

        for sf in a.surfaces
            SDL2.SDL_FreeSurface(sf)
        end
    end

    if a.alpha < 255
        SDL2.SDL_SetTextureBlendMode(a.textures[begin], SDL2.SDL_BLENDMODE_BLEND)
        SDL2.SDL_SetTextureAlphaMod(a.textures[begin], a.alpha)
    end

    flip = if a.w < 0 && a.h < 0
        SDL2.SDL_FLIP_HORIZONTAL | SDL2.SDL_FLIP_VERTICAL

    elseif a.h < 0
        SDL2.SDL_FLIP_VERTICAL

    elseif a.w < 0
        SDL2.SDL_FLIP_HORIZONTAL

    else
        SDL2.SDL_FLIP_NONE
    end

    SDL2.SDL_RenderCopyEx(
        game[].screen.renderer,
        a.textures[begin],
        C_NULL,
        Ref(SDL2.SDL_Rect(Int32[ a.x, a.y, ceil(a.w * a.scale[1]), ceil(a.h * a.scale[2]) ]...)),
        a.angle,
        a.rotate_center,
        flip,
    )
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
    sqrt(dx * dx + dy * dy)
end

atan2(y, x) = pi - pi/2 * (1 + sign(x)) * (1 - sign(y^2)) - pi/4 * (2 + sign(x)) * sign(y) -
                            sign(x*y) * atan((abs(x) - abs(y)) / (abs(x) + abs(y)))


function Base.size(s::Ptr{SDL2.SDL_Surface})
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

    a.x < b.x + b.w &&
    a.y < b.y + b.h &&
    a.x + a.w > b.x &&
    a.y + a.h > b.y
end

rect(a::Actor) = a.position
