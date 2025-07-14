using .GameOne

function rungame(game::Game)
    screen = game.screen
    ctx = screen.context
    renderer = screen.renderer
    batch = renderer.batch_renderer

    # Main loop
    last_time = time()
    while !should_close(ctx)
        # --- Timing ---
        now = time()
        dt = now - last_time
        last_time = now
        game.delta_time = Float32(dt)

        # --- Poll events (GLFW) ---
        poll_events()

        # --- ImGui: Start frame ---
        CImGui.NewFrame()

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

        # --- ImGui: Render ---
        CImGui.Render()
        # You must call your ImGui OpenGL/GLFW backend's render function here
        # e.g. ImGui_ImplOpenGL3_RenderDrawData(CImGui.GetDrawData())

        # --- Present frame (swap buffers) ---
        present(screen)
    end

    # Cleanup
    destroy_gl_context!(ctx)
    shutdown_glfw()
end