#import Colors
module SimpleGame

using GameOne
using CImGui


# --- Animation Setup ---
anim_folder = joinpath(@__DIR__, "images", "FireElem1")
frames = let
    files = sort(readdir(anim_folder; join=true))
    [Array(GameOne.RGBA.(load(f))) for f in files]
end
frame_count = length(frames)
h, w = size(frames[1])
frame_data = [vec(reinterpret(UInt8, permutedims(f, (2,1)))) for f in frames]

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

last_render_time = Ref(time())

function update(g::GameOne.Game, delta_time::Float32)
    # Update game state
end

function imgui(g::GameOne.Game)
    # custom imgui windows
end

# --- Create Game Object ---
g = GameOne.Game(
    "Simple Game",
    @__DIR__,
    Main,
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

g.render(ctx) do
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
        CImGui.End()
    end

    # Animation Window
    if CImGui.Begin("Animation")
        CImGui.Image(anim_image_id[], CImGui.ImVec2(w, h))
        CImGui.End()
    end

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
        CImGui.End()
    end
end

end

# --- start game from terminal call the Game ---
if PROGRAM_FILE == @__FILE__()
    using .SimpleGame
    println("Starting Simple Game!")
    GameOne.rungame(SimpleGame.game)
end