

mutable struct Actor
    label::String
    surfaces::Vector{Ptr{SDL2.Surface}}
    textures::Vector{Ptr{SDL2.Texture}}
    position::SDL2.Rect
    scale::Vector{Float32}
    rotate_center::Union{Vector{Int32},Ptr{Nothing}}
    angle::Float64
    alpha::UInt8
    data::Dict{Symbol,Any}
end


function Image(img_name::String, img; x=0, y=0, kv...)
    @show img_name
    img = ARGB.(transpose(img))
    w, h = Int32.(size(img))
    sf = SDL2.CreateRGBSurfaceWithFormatFrom(
        img,
        w,
        h,
        Int32(32),
        Int32(4w),
        SDL2.PIXELFORMAT_ARGB32,
    )

    r = SDL2.Rect(x, y, w, h)
    a = Actor(
        img_name,
        [sf],
        [],
        r,
        [1,1],
        C_NULL,
        0,
        255,
        Dict(
            :img=>img,
            :label=>img_name,
            :sz=>[w,h],
            :fade=>false,
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


function draw(a::Actor)
    if isempty(a.textures)
        SDL2.SetHint(SDL2.HINT_RENDER_SCALE_QUALITY, "best")

        for (i, sf) in enumerate(a.surfaces)
            tx = SDL2.CreateTextureFromSurface(game[].screen.renderer, sf)

            if tx == SDL2.C_NULL
                @warn "Failed to create texture $i for $(a.label)! Fall back to CPU?"
            end

            push!(a.textures, tx)
        end

        for sf in a.surfaces
            SDL2.FreeSurface(sf)
        end
    end

    if a.alpha < 255
        SDL2.SetTextureBlendMode(a.textures[begin], SDL2.BLENDMODE_BLEND)
        SDL2.SetTextureAlphaMod(a.textures[begin], a.alpha)
    end

    flip = if a.w < 0 && a.h < 0
        SDL2.FLIP_HORIZONTAL | SDL2.FLIP_VERTICAL

    elseif a.h < 0
        SDL2.FLIP_VERTICAL

    elseif a.w < 0
        SDL2.FLIP_HORIZONTAL

    else
        SDL2.FLIP_NONE
    end

    SDL2.RenderCopyEx(
        game[].screen.renderer,
        a.textures[begin],
        C_NULL,
        Ref(SDL2.Rect(Int32[ a.x, a.y, ceil(a.w * a.scale[1]), ceil(a.h * a.scale[2]) ]...)),
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


function Base.size(s::Ptr{SDL2.Surface})
    ss = SDL2.unsafe_load(s)
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
