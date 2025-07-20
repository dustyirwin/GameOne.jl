using Colors
using .GameOne: load_texture, load_animated_textures, SpriteAnimation


# Basic 2D actor for images or sprites

# New Position struct for Actor
@kwdef mutable struct Position
    x::Int32 = 0
    y::Int32 = 0
    w::Int32 = 100
    h::Int32 = 100
end

@kwdef mutable struct Actor
    id::String = randstring(10)
    label::String = ""
    imgpath::Union{String, Vector{String}, Nothing}  # single img, animation, or text (nothing)
    position::Position = Position()
    scale::Vector{Float32} = [1.0, 1.0]  # scale in x and y
    z::Int32 = 0
    angle::Float64 = 0.0
    alpha::Float32 = 1.0
    texture::Union{Nothing, GLuint} = nothing
    animation::Union{Nothing, SpriteAnimation} = nothing
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



function ImageActor(path::String; id=randstring(10), x=Int32(1), y=Int32(1), 
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


function AnimatedActor(paths::Vector{String}, frame_times::Vector{Float64}; id=randstring(10), x=0, y=0, w=0, h=0,
    color=colorant"white", alpha=1.0)::Actor
    frames = [load_texture(p) for p in paths]
    anim = SpriteAnimation(frames, frame_times)
    # You may want to query the texture size here
    Actor(
        id,
        "anim",
        paths,
        Position(x=x, y=y, w=w, h=h),
        1,
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
    size = (a.position.w, a.position.h)
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

#= TextActor: stub for now (replace with OpenGL text rendering later)
function TextActor(text::String, font_path::String; id=randstring(10), x=0, y=0, pt_size=24, color=colorant"white")
    # Implement OpenGL text rendering
    

end
=#

function move!(actor, dx, dy)
    org = actor.position.origin
    new_x = first(org) + dx
    new_y = last(org) + dy
    actor.position = HyperRectangle(new_x, new_y, first(org), last(org))
end