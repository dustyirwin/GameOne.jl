using GeometryBasics
using Colors
using .GameOne: ImGuiContext, Renderer, BatchRenderer, create_gl_context, BatchRenderer, clear_screen!
using CImGui.lib
using CImGui

mutable struct Screen
    window::GLFW.Window
    width::Int32
    height::Int32
    context::Ptr{CImGui.ImGuiContext}
    renderer::Renderer
    background_color::Vec4f
    
    Screen() = new()
end

# Create a new Screen (window + renderer)
function create_screen(name::String, width::Int32, height::Int32; vsync=true, samples=Int32(4), background=colorant"black", fullscreen::Bool=false)
    ctx, win = create_gl_context(width, height, name; vsync=vsync, samples=samples, fullscreen=fullscreen)
    # You must create your shader watcher and batch renderer here
    sprite_shader = ShaderWatcher(joinpath(dirname(@__FILE__),"..","shaders/sprite.vert"), joinpath(dirname(@__FILE__),"..","shaders/sprite.frag"))
    batch = BatchRenderer(sprite_shader)
    # For now, we'll leave these as placeholders:
    renderer = Renderer()
    renderer.context = ctx
    renderer.batch_renderer = batch
    renderer.clear_color = color_to_vec4f(background)
    scr = Screen()
    scr.window = win
    scr.context = ctx
    scr.width = width
    scr.height = height
    scr.renderer = renderer
    scr.background_color = color_to_vec4f(background)
    return scr
end

# Clear the screen to its background color
function clear(s::Screen)
    clear_screen!(s.renderer.clear_color)
end

# Resize the screen (window and OpenGL viewport)
function resize_screen!(s::Screen, width::Int32, height::Int32)
    resize_gl_context!(s.context, width, height)
    # Update projection matrix if needed
    # s.renderer.batch_renderer.projection_matrix = ...
end

# Present the frame (swap buffers)
function present(s::Screen)
    present!(s.window)
end

# Example: draw a colored quad (replace with batch renderer usage)
function draw(s::Screen, r::Rect; c::Colorant=colorant"black", fill=true)
    color = color_to_vec4f(c)
    pos = Vec2f(r.x, r.y)
    size = Vec2f(r.w, r.h)
    draw_colored_quad!(s.renderer.batch_renderer, pos, size, color)
end

# Example: draw a line (replace with batch renderer usage)
function draw(s::Screen, l::Line; c::Colorant=colorant"black")
    # For now, just draw a thin quad as a line
    color = color_to_vec4f(c)
    p1 = Vec2f(l.x1, l.y1)
    p2 = Vec2f(l.x2, l.y2)
    dir = p2 - p1
    length = norm(dir)
    angle = atan(dir[2], dir[1])
    thickness = 2.0f0
    # You can implement a draw_line! helper in your renderer
    # draw_line!(s.renderer.batch_renderer, p1, p2, thickness, color)
end

# You can add similar wrappers for Triangle, Circle, etc.

# Helper to get the current framebuffer size
function get_screen_size(s::Screen)
    get_framebuffer_size(s.context)
end