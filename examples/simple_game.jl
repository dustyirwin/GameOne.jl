#import Colors
module SimpleGame

using GameOne
using CImGui

# --- Game State ---
current_frame = Ref(1)
last_time = Ref(time())
frame_delay = 1/12
anim_image_id = Ref{Any}(nothing)
last_uploaded_frame = Ref(-1)
ui_frame_dt = Ref(1/60)
frame_dt = Ref(1/12)
music_playing = Ref(false)

# --- ImGui/OpenGL Setup ---
CImGui.set_backend(:GlfwOpenGL3)
ctx = CImGui.CreateContext()

io = CImGui.GetIO()
io.ConfigFlags = unsafe_load(io.ConfigFlags) | CImGui.ImGuiConfigFlags_DockingEnable
io.ConfigFlags = unsafe_load(io.ConfigFlags) | CImGui.ImGuiConfigFlags_ViewportsEnable

# --- Webp Animation Setup ---
webp_path = joinpath(@__DIR__,"images", "Camouflage_001.webp")
tmp_anim_folder = joinpath(tempdir(), basename(webp_path))
process_webp(webp_path, "Camouflage_001", tmp_anim_folder)
frame_paths = [ fn for fn in sort(readdir(tmp_anim_folder; join=true)) if endswith(lowercase(fn), ".png") ]
frame_count = length(frame_paths)
frame_delays = fill(1/12, frame_count)  # Assuming 12 FPS

first_frame, w, h = load_gl_img(frame_paths[1])
frame_data = [ load_gl_img(fp)[1] for fp in frame_paths ]

last_render_time = Ref(time())

# --- Sprite Animation (defer creation until context is ready) ---
sprite_anim = Ref{Any}(nothing)

function update!(anim::SpriteAnimation, dt::Float64)
    anim.timer += dt
    while anim.timer > anim.frame_times[anim.current_frame]
        anim.timer -= anim.frame_times[anim.current_frame]
        anim.current_frame += 1
        if anim.current_frame > length(anim.textures)
            anim.current_frame = anim.looping ? 1 : length(anim.textures)
        end
    end
end

function current_texture(anim::SpriteAnimation)
    anim.textures[anim.current_frame]
end

function update(g::GameOne.Game, delta_time::Float32)
    # Update game state
end

function imgui(g::GameOne.Game)
    now = time()
    ui_frame_dt[] = now - last_render_time[]
    last_render_time[] = now

    # Animation frame update
    if now - last_time[] > frame_delay
        frame_dt[] = now - last_time[]
        current_frame[] = current_frame[] % frame_count + 1
        last_time[] = now
    end

    # Create texture if needed
    if anim_image_id[] === nothing
        anim_image_id[] = CImGui.create_image_texture(w, h)
    end

    # Update texture if frame changed
    if current_frame[] != last_uploaded_frame[]
        CImGui.update_image_texture(anim_image_id[], frame_data[current_frame[]], w, h)
        last_uploaded_frame[] = current_frame[]
    end

    # FPS Display
    anim_fps = 1 / frame_dt[]
    if CImGui.Begin("FPS Display")
        CImGui.Text("Animation FPS: $(round(anim_fps, digits=2))")
        CImGui.Text("UI FPS: $(round(1/ui_frame_dt[], digits=2))")
    end
    CImGui.End()

    # Animation Window
    if CImGui.Begin("Animation")
        CImGui.Image(anim_image_id[], CImGui.ImVec2(w, h))
    end
    CImGui.End()

    # Sound Control
    if CImGui.Begin("Sound Control")
        if CImGui.Button("Play Sound")
            GameOne.play_sound(joinpath(@__DIR__, "sounds", "eep.wav"))
        end
        if CImGui.Button("Play Music") && !music_playing[]
            GameOne.play_music(joinpath(@__DIR__, "music", "radetzky.ogg"), loops=0, volume=1.0)
            music_playing[] = true
        end
        if CImGui.Button("Stop Music") && music_playing[]
            GameOne.stop_music()
            music_playing[] = false
        end
    end
    CImGui.End()

    # Sprite Animation (deferred creation)
    if sprite_anim[] === nothing
        sprite_anim[] = create_sprite_animation(frame_data, w, h, frame_delays)
    end
    update!(sprite_anim[], frame_dt[])
    if CImGui.Begin("Sprite Animation")
        CImGui.Image(current_texture(sprite_anim[]), CImGui.ImVec2(w, h))
    end
    CImGui.End()
end

# --- Create Game Object ---
g = GameOne.Game(
    "Simple Game",
    @__DIR__,
    Main,
    nothing,
    GameOne.KeyState(),
    GameOne.MouseState(),
    0.0f0,                # delta_time
    0,                    # frame_count
    0.0f0,                # fps
    CImGui.render,
    update,
    nothing,              # onkey_function
    nothing,              # onmousedown_function
    nothing,              # onmouseup_function
    nothing,              # onmousemove_function
    imgui,
    nothing,              # imgui_settings
    GameOne.imgui_preinit,
    [Dict{String,Any}()],
    []                    # socket
)

g.render(ctx, window_title="Simple Game Copy") do
    g.imgui(g)
end

end

# --- start game from terminal call the Game ---
if PROGRAM_FILE == @__FILE__()
    using .SimpleGame
    println("Starting Simple Game!")
    GameOne.rungame(SimpleGame.game)
end

