using .GameOne

# Modern Game structure
mutable struct Game
    name::String
    location::String
    game_module::Module
    screen::Union{Screen, Nothing}
    keyboard::KeyState
    mouse::MouseState
    delta_time::Float32
    frame_count::Int64
    fps::Float32
    render::Union{Function, Nothing}
    update::Function
    onkey::Union{Function, Nothing}
    onmousedown::Union{Function, Nothing}
    onmouseup::Union{Function, Nothing}
    onmousemove::Union{Function, Nothing}
    imgui::Union{Function, Nothing}
    imgui_settings::Union{Dict{String,Any}, Nothing}
    imgui_preinit::Union{Function, Nothing}
    state::Vector{Dict{String,Any}}
    socket::Vector{TCPSocket}
end

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


function imgui_preinit(ctx::Ptr{CImGui.ImGuiContext})
    # Ensure ImGui context exists
    if ctx == C_NULL
        @error "ImGui context is null in imgui_preinit"
        return
    end
    io = CImGui.GetIO()
    io.ConfigFlags = unsafe_load(io.ConfigFlags) | CImGui.ImGuiConfigFlags_DockingEnable
    io.ConfigFlags = unsafe_load(io.ConfigFlags) | CImGui.ImGuiConfigFlags_ViewportsEnable

    style = Ptr{CImGui.ImGuiStyle}(CImGui.GetStyle())
    if unsafe_load(io.ConfigFlags) & CImGui.ImGuiConfigFlags_ViewportsEnable == CImGui.ImGuiConfigFlags_ViewportsEnable
        style.WindowRounding = 5.0f0
        col = CImGui.c_get(style.Colors, CImGui.ImGuiCol_WindowBg)
        CImGui.c_set!(style.Colors, CImGui.ImGuiCol_WindowBg, CImGui.ImVec4(col.x, col.y, col.z, 1.0f0))
    end
end

function rungame(game::Game)
    #screen = game.screen
    ctx = CImGui.CreateContext()

    io = CImGui.GetIO()
    io.ConfigFlags = unsafe_load(io.ConfigFlags) | CImGui.ImGuiConfigFlags_DockingEnable
    io.ConfigFlags = unsafe_load(io.ConfigFlags) | CImGui.ImGuiConfigFlags_ViewportsEnable


    if ctx == C_NULL
        @error "ImGui context is null in rungame"
        return
    end
    #renderer = screen.renderer
    #batch = renderer.batch_renderer

    # Set ImGui backend (high-level, handles all init)
    CImGui.set_backend(:GlfwOpenGL3)

    # Optional: ImGui pre-init hook (set config flags, style, etc.)
    if !isnothing(game.imgui_preinit)
        game.imgui_preinit(ctx)
    end

    last_time = time()
    #=
    loop_callback = function()
        # --- Timing ---
        now = time()
        dt = now - last_time
        last_time = now
        game.delta_time = Float32(dt)

        # --- Poll events (GLFW) ---
        poll_events()

        # --- Clear screen ---
        clear(screen)

        # --- Begin batch ---
        begin_batch!(batch)

        # --- Game update ---
        game.update(game, dt)

        # --- End batch and flush to GPU ---
        end_batch!(batch)

        # --- ImGui: Draw menus/windows ---
        game.imgui(game)

        # --- Present frame (swap buffers) ---
        present(screen)
    end
    
    # Main render loop using GameOne.renderloop (Windows/GlfwOpenGL3 expects this signature)
    GameOne.renderloop(loop_callback, ctx, Val(:GlfwOpenGL3))
    =#

    game.render(ctx) do
        game.imgui(game)
    end

    # Cleanup
    CImGui.DestroyContext(ctx)
    shutdown_glfw()
end