using Colors
using .GameOne: load_texture, load_animated_textures, SpriteAnimation

# Basic 2D actor for images or sprites
@kwdef mutable struct Position
    x::Int32 = 0
    y::Int32 = 0
    w::Int32 = 100
    h::Int32 = 100
end

@kwdef mutable struct Actor
    const id::String = randstring(8)
    const label::String = ""
    const img_paths::Union{String, Vector{String}, Nothing}  # single img, animation, or text (nothing)
    position::Position = Position()
    scale::Vector{Float32} = [1.0, 1.0]  # scale in x and y
    z::Int32 = 0
    angle::Float64 = 0.0
    alpha::Float32 = 1.0
    texture::Union{Nothing, GLuint} = nothing
    anim::Union{Nothing, SpriteAnimation} = nothing
    color::Vec4f = Vec4f(1.0, 1.0, 1.0, 1.0)
    data::Dict{Symbol,Any} = Dict()
end

# Use a memory pool for frequently created/destroyed actors
mutable struct ActorPool{T}
    active::Vector{T}
    inactive::Vector{T}
    max_size::Int
end

function ActorPool(T::Type, max_size::Int=1000)
    ActorPool(T[], T[], max_size)
end

function get_actor(pool::ActorPool{T}) where T
    if !isempty(pool.inactive)
        actor = pop!(pool.inactive)
        push!(pool.active, actor)
        return actor
    elseif length(pool.active) < pool.max_size
        actor = T()  # Assuming default constructor exists
        push!(pool.active, actor)
        return actor
    end
    return nothing  # Pool is full
end

function release_actor!(pool::ActorPool, actor)
    idx = findfirst(==(actor), pool.active)
    if idx !== nothing
        deleteat!(pool.active, idx)
        push!(pool.inactive, actor)
    end
end

function ImageActor(path::String; id=randstring(16), x=Int32(1), y=Int32(1), 
    color=colorant"white", alpha=1.0, w::Union{Nothing, Int32}=nothing, h::Union{Nothing, Int32}=nothing)::Actor
    texid = load_texture(path)
    if w === nothing || h === nothing
        # Query texture size if not provided
        width = Ref{Int32}()
        height = Ref{Int32}()
        ModernGL.glGetTexLevelParameteriv(GL_TEXTURE_2D, 0, GL_TEXTURE_WIDTH, width)
        ModernGL.glGetTexLevelParameteriv(GL_TEXTURE_2D, 0, GL_TEXTURE_HEIGHT, height)
        w = width[]
        h = height[]
    end

    Actor(
        id,
        basename(path),
        path,
        Position(x=x, y=y, w=w, h=h),
        [1.0, 1.0],  # Default scale
        1,
        0.0,
        1.0,
        texid,
        nothing,
        color_to_vec4f(color),
        Dict(
            :type=>"image", 
            :mouse_offset => Vec2f(0, 0),
            :anim=>false,
            )
    )
end


function AnimatedActor(webp_path::String, fps=14; 
    id=randstring(16), x=0, y=0, color=colorant"white", alpha=1.0)::Actor

    tmp_anim_folder = joinpath(tempdir(), basename(webp_path))
    process_webp(webp_path, id, tmp_anim_folder)
    frame_paths = [ fn for fn in sort(readdir(tmp_anim_folder; join=true)) if endswith(lowercase(fn), ".png") ]
    frame_count = length(frame_paths)
    frame_delays = fill(1/fps, frame_count)
    frame_ids = [ randstring(16) for _ in 1:frame_count ]
    first_frame, w, h = load_gl_img(frame_paths[1])
    frame_data = [ load_gl_img(fp)[1] for fp in frame_paths ]

    anim = SpriteAnimation(
        frame_data, 
        frame_delays,
        frame_ids,
        w, 
        h,
        1,
        0.,
        true  # Looping by default
    )
    # You may want to query the texture size here
    Actor(
        id,
        basename(webp_path),
        webp_path,
        Position(x=x, y=y, w=w, h=h),
        [1.0, 1.0],  # Default scale
        1,
        0.0,
        1.0,
        nothing,
        anim,
        color_to_vec4f(color),
        Dict(:type=>"anim")
    )
end

# Animation update
function update!(a::Actor, dt::Float64)
    if a.animation !== nothing
        update!(a.animation, dt)
    end
end

function move!(a::Actor, dx::Real, dy::Real)
    pos = a.position
    new_x = pos.x + dx
    new_y = pos.y + dy
    a.position = Position(new_x, new_y, pos.w, pos.h)
end