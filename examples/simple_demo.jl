using GameOne

PA = PortAudio.LibPortAudio
CImGui.set_backend(:GlfwOpenGL3)

ctx = CImGui.CreateContext()
# enable docking and multi-viewport
io = CImGui.GetIO()
io.ConfigFlags = unsafe_load(io.ConfigFlags) | CImGui.ImGuiConfigFlags_DockingEnable
io.ConfigFlags = unsafe_load(io.ConfigFlags) | CImGui.ImGuiConfigFlags_ViewportsEnable
io.ConfigFlags = unsafe_load(io.ConfigFlags) | CImGui.ImGuiConfigFlags_NavEnableKeyboard


# sound file setup
sound_id = Ref{Any}(nothing)
function play_sound(file_path::String)
    buf = load(file_path)
    stream = PortAudioStream(0, nchannels(buf); samplerate=samplerate(buf))
    write(stream, buf)
    close(stream)
end

img_data_gl_flat, img_w, img_h = load_gl_img(joinpath(@__DIR__, "images", "alien.png"))
bkg_data_gl_flat, bkg_width, bkg_height = load_gl_img(joinpath(@__DIR__, "images", "edh_bkg.png"))

image_id = Ref{Any}(nothing)
bkgimg_id = Ref{Any}(nothing)

CImGui.render(ctx) do
    window = CImGui.current_window()
    if window === nothing
        return
    end
    GLFW.MakeContextCurrent(window)
    
    if image_id[] === nothing
        image_id[] = CImGui.create_image_texture(img_w, img_h)
    end
    if bkgimg_id[] === nothing
        bkgimg_id[] = CImGui.create_image_texture(bkg_width, bkg_height)
    end

    draw_background(window, bkgimg_id)
    
    CImGui.update_image_texture(image_id[], img_data_gl_flat, img_w, img_h)
    if CImGui.Begin("Image Window")
        CImGui.Image(image_id[], CImGui.ImVec2(img_w, img_h))
    end
    CImGui.End()
    
    CImGui.update_image_texture(bkgimg_id[], bkg_data_gl_flat, bkg_width, bkg_height)

    if CImGui.Begin("Sound Control")
        if CImGui.Button("Play Sound")
            play_sound(joinpath(@__DIR__, "sounds", "eep.wav"))
        end
    end
    CImGui.End()
end