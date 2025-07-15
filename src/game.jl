using .GameOne

function my_imgui_preinit()
    # Ensure ImGui context exists
    if CImGui.GetCurrentContext() == C_NULL
        CImGui.CreateContext()
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
    screen = game.screen
    ctx = screen.context
    renderer = screen.renderer
    batch = renderer.batch_renderer

    # Set ImGui backend (high-level, handles all init)
    CImGui.set_backend(:GlfwOpenGL3)

    # Optional: ImGui pre-init hook (set config flags, style, etc.)
    if !isnothing(game.imgui_preinit_function)
        game.imgui_preinit_function()
    end

    # Main render loop using CImGui.render
    last_time = time()
    CImGui.render(game,ctx) do
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
        game.update_function(game, dt)

        # --- Game render (draw your cards, etc.) ---
        game.render_function(game)

        # --- End batch and flush to GPU ---
        end_batch!(batch)

        # --- ImGui: Draw menus/windows ---
        game.imgui_function(game)

        # --- Present frame (swap buffers) ---
        present(screen)
    end

    # Cleanup
    destroy_gl_context!(ctx)
    shutdown_glfw()
end