using Colors
using .GameOne: load_texture, load_animated_textures, SpriteAnimation

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

# Basic 2D actor for images or sprites
mutable struct Actor
    id::String
    label::String
    position::Rect
    size::Vec2f
    angle::Float64
    alpha::Float32
    texture::Union{Nothing, GLuint}
    animation::Union{Nothing, SpriteAnimation}
    color::Vec4f
    data::Dict{Symbol,Any}
end

function ImageActor(path::String; id=randstring(10), x=0, y=0, w=0, h=0, color=colorant"white")
    texid = load_texture(path)
    # You may want to query the texture size here
    Actor(
        id,
        basename(path),
        Rect(x, y, w, h),
        Vec2f(w, h),
        0.0,
        1.0,
        texid,
        nothing,
        color_to_vec4f(color),
        Dict(:type=>"image")
    )
end

function AnimatedActor(paths::Vector{String}, frame_times::Vector{Float64}; id=randstring(10), x=0, y=0, color=colorant"white")
    frames = [load_texture(p) for p in paths]
    anim = SpriteAnimation(frames, frame_times)
    # You may want to query the texture size here
    Actor(
        id,
        "anim",
        Rect(x, y, 0, 0),
        Vec2f(0, 0),
        0.0,
        1.0,
        nothing,
        anim,
        color_to_vec4f(color),
        Dict(:type=>"anim")
    )
end

# Drawing: Use batch renderer
function draw(screen::Screen, a::Actor)
    pos = Vec2f(a.position.x, a.position.y)
    size = a.size
    color = a.color
    if a.texture !== nothing
        draw_textured_quad!(screen.renderer.batch_renderer, pos, size, a.texture, color)
    elseif a.animation !== nothing
        tex = current_texture(a.animation)
        draw_textured_quad!(screen.renderer.batch_renderer, pos, size, tex, color)
    else
        draw_colored_quad!(screen.renderer.batch_renderer, pos, size, color)
    end
end

# Animation update
function update!(a::Actor, dt::Float64)
    if a.animation !== nothing
        update!(a.animation, dt)
    end
end

# TextActor: stub for now (replace with OpenGL text rendering later)
function TextActor(text::String, font_path::String; id=randstring(10), x=0, y=0, pt_size=24, color=colorant"white")
    # TODO: Implement OpenGL text rendering
    Actor(
        id,
        text,
        Rect(x, y, 0, 0),
        Vec2f(0, 0),
        0.0,
        1.0,
        nothing,
        nothing,
        color_to_vec4f(color),
        Dict(:type=>"text", :font_path=>font_path, :pt_size=>pt_size)
    )
end