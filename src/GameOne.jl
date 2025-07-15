module GameOne

using Reexport: @reexport

# Add Revise for hot-reloading development
@reexport using Revise

# Base imports (keep these)
@reexport using Logging: @debug, @info, @warn, @error, @logmsg
@reexport using Colors: FixedPointNumbers, @colorant_str, ARGB, Colorant, red, green, blue, alpha
@reexport using Base.Threads: @threads, @spawn, Atomic, SpinLock
@reexport using Dates: now, Millisecond
@reexport using Random: rand, randstring, shuffle, shuffle!
@reexport using DataStructures: OrderedDict, counter, @enum
@reexport using Sockets
@reexport using Printf: @sprintf

# Modern OpenGL/GLFW stack
@reexport using GLFW
@reexport using ModernGL
@reexport using LinearAlgebra: I, cross, dot, norm, normalize
@reexport using StaticArrays: SVector, SMatrix, @SVector, @SMatrix
@reexport using GeometryBasics: Point2f, Vec2f, Vec3f, Vec4f, Mat4f, Rect2f

# ImGui with GLFW+OpenGL3 backend
@reexport using CImGui
@reexport using CImGui.CSyntax
@reexport using CImGui.CSyntax.CStatic
@reexport using CImGui: ImVec2, ImVec4, IM_COL32, ImS32, ImU32, ImS64, ImU64

# Audio (lightweight)
@reexport using PortAudio
#@reexport using FileIO
@reexport using LibSndFile

# WebP support
@reexport using WebP

# ImageCore 
@reexport using ImageCore: channelview, permutedims, reshape, float

# Modern exports
export game, draw, render, flush!, scheduler, schedule_once, schedule_interval, schedule_unique, unschedule,
    collide, angle, distance, play_music, play_sound, line, clear, rungame, game_include,
    window_paused, start_text_input, update_text_actor!, create_gl_context,
    load_texture, create_shader, compile_shader, use_shader, bind_texture, my_imgui_preinit,
    begin_batch, end_batch, draw_quad, draw_sprite, draw_text, create_screen, load_animated_textures, move!
export Game, Screen, GLContext, Renderer, Shader, Texture, BatchRenderer
export Actor, TextActor, ImageActor 
export Line, Rect, Triangle, Circle
export KeyState, MouseState

# Core data structures
mutable struct GLContext
    window::GLFW.Window
    width::Int32
    height::Int32
    title::String
    vsync::Bool
    samples::Int32
    monitor::GLFW.Monitor
    #windowhint::GLFW.WindowHint
    #framebuffer_size_callback::Function
    #error_callback::Function
    
    GLContext() = new()
end

mutable struct Shader
    program::GLuint
    vertex_shader::GLuint
    fragment_shader::GLuint
    uniforms::Dict{String, GLint}
    path::String  # For hot-reloading
    last_modified::Float64
    
    Shader() = new(0, 0, 0, Dict{String, GLint}(), "", 0.0)
end

mutable struct Texture
    id::GLuint
    width::Int32
    height::Int32
    channels::Int32
    format::GLenum
    path::String
    compressed::Bool
    
    Texture() = new(0, 0, 0, 0, GL_RGBA, "", false)
end

include("shader.jl")               # Shader compilation and management
include("renderer.jl")             # Modern OpenGL batch renderer

mutable struct Renderer
    context::GLContext
    batch_renderer::BatchRenderer
    sprite_shader::Shader
    text_shader::Shader
    line_shader::Shader
    white_texture::Texture
    clear_color::Vec4f
    wireframe::Bool
    
    Renderer() = new()
end

mutable struct Screen
    context::GLContext
    renderer::Renderer
    background_color::Vec4f
    
    Screen() = new()
end

# Input handling
mutable struct KeyState
    keys::Dict{GLFW.Key, Bool}
    key_pressed::Dict{GLFW.Key, Bool}
    key_released::Dict{GLFW.Key, Bool}
    
    KeyState() = new(Dict{GLFW.Key, Bool}(), Dict{GLFW.Key, Bool}(), Dict{GLFW.Key, Bool}())
end

mutable struct MouseState
    position::Vec2f
    delta::Vec2f
    buttons::Dict{GLFW.MouseButton, Bool}
    button_pressed::Dict{GLFW.MouseButton, Bool}
    button_released::Dict{GLFW.MouseButton, Bool}
    scroll::Vec2f
    
    MouseState() = new(Vec2f(0), Vec2f(0), Dict{GLFW.MouseButton, Bool}(), 
                      Dict{GLFW.MouseButton, Bool}(), Dict{GLFW.MouseButton, Bool}(), Vec2f(0))
end

# Modern Game structure
mutable struct Game
    screen::Screen
    location::String
    game_module::Module
    keyboard::KeyState
    mouse::MouseState
    delta_time::Float32
    frame_count::Int64
    fps::Float32
    render_function::Function
    update_function::Function
    onkey_function::Union{Function, Nothing}
    onmousedown_function::Union{Function, Nothing}
    onmouseup_function::Union{Function, Nothing}
    onmousemove_function::Union{Function, Nothing}
    imgui_function::Union{Function, Nothing}
    imgui_settings::Union{Dict{String,Any}, Nothing}
    imgui_preinit_function::Union{Function, Nothing}
    state::Vector{Dict{String,Any}}
    socket::Vector{TCPSocket}
end

# Core includes
include("math.jl")                  # Matrix math utilities
include("keyboard.jl")              # GLFW keyboard handling
include("timer.jl")                 # Keep as-is
include("glcontext.jl")            # GLFW window management
include("texture.jl")              # Texture loading and management
include("screen.jl")               # OpenGL screen management
include("event.jl")                # GLFW event handling
#include("audio.jl")                # PortAudio backend
include("animation.jl")
include("actor.jl")                # Modern actor system
include("resources.jl")             # Resource management
include("game.jl")                  # Game main loop 

export ShaderWatcher

# Game constants
const timer = WallTimer()
const game = Ref{Game}()
const playing = Ref{Bool}(false)
const paused = Ref{Bool}(false)
const window_paused = Ref{Int32}(0)

# Hot-reloading shader cache
const SHADER_CACHE = Dict{String, Shader}()
const SHADER_WATCH_LIST = Set{String}()

struct QuitException <: Exception end

end # module
