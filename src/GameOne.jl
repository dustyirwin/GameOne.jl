module GameOne

using Reexport: @reexport

# Base imports (keep these)
@reexport using LinearAlgebra: I, cross, dot, norm, normalize
#@reexport using FixedPointNumbers
@reexport using Logging: @debug, @info, @warn, @error, @logmsg
@reexport using Colors: FixedPointNumbers, @colorant_str, ARGB, RGBA, Colorant, red, green, blue, alpha
@reexport using Base.Threads: @threads, @spawn, Atomic, SpinLock
@reexport using Dates: Date, Millisecond, now, today
@reexport using Random: rand, randstring, shuffle, shuffle!
@reexport using DataStructures: OrderedDict, counter, @enum
@reexport using Serialization: serialize, deserialize

# File I/O
@reexport using DelimitedFiles: readlines, write
@reexport using RelocatableFolders: @path, abspath

# 
@reexport using UUIDs: uuid4
@reexport using Sockets: TCPSocket, listen, accept, close, connect, isopen
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
@reexport using PortAudio: nchannels, samplerate, PortAudioStream, write, close
@reexport using LibSndFile

@reexport using FileIO
@reexport using ImageIO
@reexport using JSON

# WebP support
@reexport using libwebp_jll: webpmux, dwebp, webpinfo

# StatsBase for statistics
@reexport using StatsBase: mean, median, std, minimum, maximum, quantile

# ImageCore 
@reexport using ImageCore: channelview, permutedims, reshape, float

# Modern exports
export game, draw, render, flush!, scheduler, schedule_once, schedule_interval, schedule_unique, unschedule,
    collide, angle, distance, play_music, stop_music, play_sound, line, clear, rungame, game_include,
    window_paused, start_text_input, update_text_actor!, create_gl_context, draw_background,
    load_texture, create_shader, compile_shader, use_shader, bind_texture, imgui_preinit, move!,
    draw_text, load_texture, load_animated_textures
export load_gl_img, process_webp, create_sprite_animation, update!
export Game, Shader, Texture, RGBA
export Actor, ImageActor, SpriteAnimation, AnimatedActor
export Line, Rect, Triangle, Circle
export KeyState, MouseState, ShaderWatcher

# Core includes
include("math.jl")                  # Matrix math utilities
include("keyboard.jl")              # GLFW keyboard handling
include("timer.jl")                 # Keep as-is
include("texture.jl")               # Texture loading and management
include("sprites.jl")               # Sprite animation system
include("shader.jl")                # Shader compilation and management
include("game.jl")                  # Game main loop 
include("actor.jl")                 # Modern actor system
include("resources.jl")             # Resource management
include("audio.jl")                 # Audio playback system

end # module
