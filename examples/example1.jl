module Example1

using GameOne
using GameOne.CImGui
using GameOne:ModernGL as GL
using GameOne:WallTimer, KeyState, MouseState

export rungame

# Draw callback
function draw(g::Game)
    GameOne.draw(g.screen, alien)
#   GameOne.draw(g.screen, label)
    #GameOne.draw(g.screen, anim)
    GameOne.draw(g.screen, red_rect, c=colorant"red")
    GameOne.draw(g.screen, blue_rect, c=colorant"blue")
end

function imgui(g::Game)
    # Only run ImGui config once, after context is created
    @static if !isdefined(Main, :_imgui_config_done)
        global _imgui_config_done = false
    end
    if !_imgui_config_done
        io = CImGui.GetIO()
        if io != C_NULL
            io.ConfigFlags = unsafe_load(io.ConfigFlags) | CImGui.ImGuiConfigFlags_DockingEnable
            io.ConfigFlags = unsafe_load(io.ConfigFlags) | CImGui.ImGuiConfigFlags_ViewportsEnable

            style = Ptr{CImGui.ImGuiStyle}(CImGui.GetStyle())
            if unsafe_load(io.ConfigFlags) & CImGui.ImGuiConfigFlags_ViewportsEnable == CImGui.ImGuiConfigFlags_ViewportsEnable
                style.WindowRounding = 5.0f0
                col = CImGui.c_get(style.Colors, CImGui.ImGuiCol_WindowBg)
                CImGui.c_set!(style.Colors, CImGui.ImGuiCol_WindowBg, CImGui.ImVec4(col.x, col.y, col.z, 1.0f0))
            end
            global _imgui_config_done = true
        end
    end

    # Example ImGui usage
    CImGui.Begin("Example Window")
    CImGui.ImText("Hello, GameOne!")
    CImGui.ImText("FPS: $(g.fps)")
    CImGui.End()
end

function update(g::Game, dt::Float64)
    # Update actors
    update!(alien, dt)
    #update!(label, dt)
    #update!(anim, dt)
    # After creating alien
    move!(alien, 400, 300)

    # Example: move the red rectangle
    #move!(red_rect, 1.0f0 * dt, 0.0f0)  # Move right by 1 unit per second
end

# Game setup and run
function rungame()
    SCREEN_WIDTH = Int32(800)
    SCREEN_HEIGHT = Int32(600)
    SAMPLES = Int32(4)
    VSYNC = true

    CImGui.set_backend(:GlfwOpenGL3)
    ctx = CImGui.CreateContext()

    io = CImGui.GetIO()
    io.ConfigFlags = unsafe_load(io.ConfigFlags) | CImGui.ImGuiConfigFlags_DockingEnable
    io.ConfigFlags = unsafe_load(io.ConfigFlags) | CImGui.ImGuiConfigFlags_ViewportsEnable
    io.ConfigFlags = unsafe_load(io.ConfigFlags) | CImGui.ImGuiConfigFlags_NavEnableKeyboard

    screen = create_screen("Example 1", SCREEN_WIDTH, SCREEN_HEIGHT, vsync=VSYNC, samples=SAMPLES, background=colorant"black")

    # Load assets
    alien_path = string(joinpath(@__DIR__, "images", "alien.png"))
    #fire_frames = load_animated_textures(joinpath(@__DIR__, "images", "Camouflage_001.webp"))
    eep_wav = joinpath(@__DIR__, "sounds", "283201-RubberBallBouncing7.wav")

    # Actors (update to your new Actor/ImageActor system as needed)
    global alien = GameOne.ImageActor(alien_path)
    #move!(alien, SCREEN_WIDTH ÷ 2, SCREEN_HEIGHT ÷ 2)

    #anim = SpriteAnimation(fire_frames, fill(0.12, length(fire_frames)))
    #anim.x = SCREEN_WIDTH ÷ 3
    #anim.y = SCREEN_HEIGHT ÷ 3

    #label = TextActor("this is some example text", joinpath(@__DIR__, "fonts", "OpenSans-Regular.ttf"), pt_size=24)
    #move!(label, SCREEN_WIDTH ÷ 4, SCREEN_HEIGHT ÷ 4)

    global red_rect = Rect(SCREEN_WIDTH ÷ 2, SCREEN_HEIGHT ÷ 2, 100, 100)
    global blue_rect = Rect(50, 50, 50, 50)

    screen = create_screen("Main", SCREEN_WIDTH, SCREEN_HEIGHT, background=colorant"black")

    game = Game(
        "ExampleOne",
        @__DIR__,
        @__MODULE__,
        screen,
        KeyState(),
        MouseState(),
        0.0f0,
        0,
        0.0f0,
        CImGui.render,
        update,
        nothing, 
        nothing, 
        nothing, 
        nothing,
        imgui,
        Dict{String,Any}(),
        GameOne.imgui_preinit,
        Vector{Dict{String,Any}}(),
        Vector{TCPSocket}()
    )
    
    game.render(ctx, window_title="ExampleOne", window_size=(800, 600)) do
        window = CImGui.current_window()
        
        if window !== nothing
            #draw_background(window, tex_ref, img_data_gl_flat, img_width, img_height)
            game.imgui(game)
            game.update(game, 0.01)  # Update with dummy dt
        end
    end
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    using .Example1
    Example1.rungame()
end