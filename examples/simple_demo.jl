using GameOne
using CImGui
using FileIO, Colors
using ImageCore: permutedims, Array
using ModernGL, GLFW
using PortAudio, LibSndFile
using SampledSignals

PA = PortAudio.LibPortAudio
CImGui.set_backend(:GlfwOpenGL3)

ctx = CImGui.CreateContext()
# enable docking and multi-viewport
io = CImGui.GetIO()
io.ConfigFlags = unsafe_load(io.ConfigFlags) | CImGui.ImGuiConfigFlags_DockingEnable
io.ConfigFlags = unsafe_load(io.ConfigFlags) | CImGui.ImGuiConfigFlags_ViewportsEnable

# sound file setup
sound_id = Ref{Any}(nothing)
function play_sound(file_path::String)
    buf = load(file_path)
    stream = PortAudioStream(0, nchannels(buf); samplerate=samplerate(buf))
    write(stream, buf)
    close(stream)
end

# load an image into GL format
function load_gl_img(image_path::String)
    img = load(image_path)
    img_rgba = Array(RGBA.(img))  # Ensure it's an Array
    h, w = size(img_rgba)  # Julia: (height, width)
    img_gl = permutedims(img_rgba, (2, 1))  # OpenGL expects (width, height)
    img_data_gl_flat = vec(reinterpret(UInt8, img_gl))
    return img_data_gl_flat, w, h
end

function draw_background(window, image_id, img_w, img_h)
    # Make sure the OpenGL context is current
    GLFW.MakeContextCurrent(window)
    # Get framebuffer and window size
    fbw, fbh = GLFW.GetFramebufferSize(window)
    wx, wy = GLFW.GetWindowPos(window)
    ww, wh = GLFW.GetWindowSize(window)
    # Draw the image to fill the window
    draw_list = CImGui.GetBackgroundDrawList()
    if image_id[] !== nothing
        CImGui.ImDrawList_AddImage(
            draw_list,
            image_id[],
            CImGui.ImVec2(wx, wy),
            CImGui.ImVec2(wx + ww, wy + wh),
            CImGui.ImVec2(0, 0),
            CImGui.ImVec2(1, 1),
            CImGui.ImVec4(1.0, 1.0, 1.0, 1.0)
        )
    end
end

img_data_gl_flat, img_w, img_h = load_gl_img(joinpath(@__DIR__, "images", "alien.png"))

image_id = Ref{Any}(nothing)

CImGui.render(ctx) do
    window = CImGui.current_window()
    if window === nothing
        return
    end
    GLFW.MakeContextCurrent(window)
    draw_background(window, image_id, img_w, img_h)
    
    if image_id[] === nothing
        image_id[] = CImGui.create_image_texture(img_w, img_h)
    end
    CImGui.update_image_texture(image_id[], img_data_gl_flat, img_w, img_h)
    if CImGui.Begin("Image Window")
        CImGui.Image(image_id[], CImGui.ImVec2(img_w, img_h))
        CImGui.End()
    end
    if CImGui.Begin("Sound Control")
        if CImGui.Button("Play Sound")
            play_sound(joinpath(@__DIR__, "sounds", "eep.wav"))
        end
        CImGui.End()
    end
end