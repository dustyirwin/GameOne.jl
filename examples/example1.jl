__precompile__(false)

module Example1

using GameOne

# Global variables for manual viewport (simple approach without event filtering)
manual_viewport_window_global = Ref{Ptr{SDL2.SDL_Window}}(C_NULL)
manual_viewport_created_global = Ref{Bool}(false)

TTF_Init() # Initialize SDL_ttf
Mix_Init(MIX_INIT_MP3) # Initialize SDL_mixer

# window dimensions
const SCREEN_WIDTH = 800
const SCREEN_HEIGHT = 600
const SCREEN_BACKGROUND = colorant"black"
const SCREEN_NAME = "Main"

function imgui(g::Game)
    try
        # Check if manual viewport has focus to prevent event bleeding
        @cstatic manual_viewport_created=false manual_viewport_window=C_NULL manual_viewport_renderer=C_NULL begin
            manual_viewport_has_focus = false
            if manual_viewport_created && manual_viewport_window != C_NULL
                # Check if the manual viewport window has mouse or keyboard focus
                mouse_focus = SDL2.SDL_GetMouseFocus()
                keyboard_focus = SDL2.SDL_GetKeyboardFocus()
                manual_viewport_has_focus = (mouse_focus == manual_viewport_window || keyboard_focus == manual_viewport_window)
            end
            
            # Only show ImGui UI if manual viewport doesn't have focus
            if !manual_viewport_has_focus
                # Now that GameOne only calls this function once, we can simplify
                CImGui.SetNextWindowPos(ImVec2(10, 10), CImGui.ImGuiCond_FirstUseEver)
                CImGui.SetNextWindowSize(ImVec2(350, 400), CImGui.ImGuiCond_FirstUseEver)
                
                if CImGui.Begin("Debug Window")
                    CImGui.Text("🖥️ Screen Controls")
                    
                    # Add quit button
                    if CImGui.Button("Quit Game")
                        window_paused[] = 1
                        playing[] = false
                    end
                    
                    CImGui.SameLine()
                    if CImGui.Button("Play Sound")
                        play_sound(eep_wav)
                    end
                    
                    @cstatic slider_val=0.5f0 begin
                        if CImGui.SliderFloat("Slider", Ref(slider_val), 0.0f0, 1.0f0)
                            g.imgui_settings["slider"] = slider_val
                        end
                    end
                    
                    # Manual viewport creation section
                    CImGui.Separator()
                    CImGui.Text("Manual Viewport Creation:")
                    
                    if !manual_viewport_created
                        if CImGui.Button("Create Manual Viewport Window")
                            println("🚀 Creating manual viewport window...")
                            try
                                # Create a new SDL window manually
                                manual_viewport_window = SDL2.SDL_CreateWindow(
                                    "Manual Viewport Window",
                                    SDL2.SDL_WINDOWPOS_UNDEFINED,
                                    SDL2.SDL_WINDOWPOS_UNDEFINED,
                                    400, 300,
                                    SDL2.SDL_WINDOW_SHOWN | SDL2.SDL_WINDOW_RESIZABLE
                                )
                                
                                if manual_viewport_window != C_NULL
                                    println("✅ Manual viewport window created successfully!")
                                    
                                    # Create renderer for the window
                                    manual_viewport_renderer = SDL2.SDL_CreateRenderer(
                                        manual_viewport_window, -1,
                                        SDL2.SDL_RENDERER_ACCELERATED | SDL2.SDL_RENDERER_PRESENTVSYNC
                                    )
                                    
                                    if manual_viewport_renderer != C_NULL
                                        println("✅ Manual viewport renderer created successfully!")
                                        manual_viewport_created = true
                                        # Update global variables (no event filter needed)
                                        manual_viewport_window_global[] = manual_viewport_window
                                        manual_viewport_created_global[] = true
                                    else
                                        println("❌ Failed to create renderer: $(unsafe_string(SDL2.SDL_GetError()))")
                                        SDL2.SDL_DestroyWindow(manual_viewport_window)
                                        manual_viewport_window = C_NULL
                                    end
                                else
                                    println("❌ Failed to create window: $(unsafe_string(SDL2.SDL_GetError()))")
                                end
                            catch e
                                println("❌ Error creating manual viewport: $e")
                                # Clean up any partially created resources
                                if manual_viewport_renderer != C_NULL
                                    SDL2.SDL_DestroyRenderer(manual_viewport_renderer)
                                    manual_viewport_renderer = C_NULL
                                end
                                if manual_viewport_window != C_NULL
                                    SDL2.SDL_DestroyWindow(manual_viewport_window)
                                    manual_viewport_window = C_NULL
                                end
                                manual_viewport_created = false
                                manual_viewport_window_global[] = C_NULL
                                manual_viewport_created_global[] = false
                            end
                        end
                    else
                        CImGui.TextColored(CImGui.ImVec4(0,1,0,1), "✅ Manual viewport created!")
                        CImGui.Text("Window ID: $(manual_viewport_window)")
                        if CImGui.Button("Destroy Manual Viewport")
                            println("🧹 Destroying manual viewport window...")
                            try
                                # Clean up renderer first
                                if manual_viewport_renderer != C_NULL
                                    SDL2.SDL_DestroyRenderer(manual_viewport_renderer)
                                    manual_viewport_renderer = C_NULL
                                end
                                # Clean up window
                                if manual_viewport_window != C_NULL
                                    SDL2.SDL_DestroyWindow(manual_viewport_window)
                                    manual_viewport_window = C_NULL
                                end
                                # Update state
                                manual_viewport_created = false
                                # Update global variables
                                manual_viewport_window_global[] = C_NULL
                                manual_viewport_created_global[] = false
                                
                                println("✅ Manual viewport destroyed!")
                            catch e
                                println("❌ Error destroying manual viewport: $e")
                            end
                        end
                    end
                    
                    # Show actor positions in ImGui
                    CImGui.Separator()
                    CImGui.Text("Actor Positions:")
                    CImGui.Text("Alien: ($(Int(alien.x)), $(Int(alien.y)))")
                    CImGui.Text("Label: ($(Int(label.x)), $(Int(label.y)))")
                    CImGui.Text("FireElem: ($(Int(anim.x)), $(Int(anim.y)))")
                    CImGui.Text("Red Rect: ($(red_rect.x), $(red_rect.y))")
                    CImGui.Text("Blue Rect: ($(blue_rect.x), $(blue_rect.y))")
                end
                CImGui.End()
            else
                # Manual viewport has focus, show the Debug Window but make it non-interactive
                CImGui.SetNextWindowPos(ImVec2(10, 10), CImGui.ImGuiCond_FirstUseEver)
                CImGui.SetNextWindowSize(ImVec2(350, 400), CImGui.ImGuiCond_FirstUseEver)
                
                # Push style to make it look disabled
                CImGui.PushStyleColor(CImGui.ImGuiCol_WindowBg, ImVec4(0.1, 0.1, 0.1, 0.7))
                CImGui.PushStyleColor(CImGui.ImGuiCol_Text, ImVec4(0.6, 0.6, 0.6, 1.0))
                
                if CImGui.Begin("Debug Window (Viewport Active)", C_NULL, CImGui.ImGuiWindowFlags_NoInputs)
                    CImGui.Text("🖥️ Screen Controls (Manual Viewport Active)")
                    CImGui.Text("Click main window to regain control")
                    
                    CImGui.Separator()
                    
                    # Show buttons but they won't be clickable due to NoInputs flag
                    CImGui.Button("Quit Game")
                    CImGui.SameLine()
                    CImGui.Button("Play Sound")
                    
                    @cstatic slider_val=0.5f0 begin
                        CImGui.SliderFloat("Slider", Ref(slider_val), 0.0f0, 1.0f0)
                    end
                    
                    # Manual viewport section
                    CImGui.Separator()
                    CImGui.Text("Manual Viewport Creation:")
                    
                    if !manual_viewport_created
                        CImGui.Button("Create Manual Viewport Window")
                    else
                        CImGui.TextColored(CImGui.ImVec4(0.4, 0.8, 0.4, 1.0), "✅ Manual viewport created!")
                        CImGui.Text("Window ID: $(manual_viewport_window)")
                        CImGui.Button("Destroy Manual Viewport")
                    end
                    
                    # Show actor positions in ImGui
                    CImGui.Separator()
                    CImGui.Text("Actor Positions:")
                    CImGui.Text("Alien: ($(Int(alien.x)), $(Int(alien.y)))")
                    CImGui.Text("Label: ($(Int(label.x)), $(Int(label.y)))")
                    CImGui.Text("FireElem: ($(Int(anim.x)), $(Int(anim.y)))")
                    CImGui.Text("Red Rect: ($(red_rect.x), $(red_rect.y))")
                    CImGui.Text("Blue Rect: ($(blue_rect.x), $(blue_rect.y))")
                end
                CImGui.End()
                
                CImGui.PopStyleColor(2)  # Pop both style colors
            end
            
            # Always handle manual viewport rendering regardless of focus
            if manual_viewport_created && manual_viewport_window != C_NULL
                # Check if window was closed
                if SDL2.SDL_GetWindowFlags(manual_viewport_window) == 0
                    # Window was destroyed, clean up
                    println("🪟 Manual viewport window was closed externally")
                    if manual_viewport_renderer != C_NULL
                        SDL2.SDL_DestroyRenderer(manual_viewport_renderer)
                        manual_viewport_renderer = C_NULL
                    end
                    manual_viewport_window = C_NULL
                    manual_viewport_created = false
                    manual_viewport_window_global[] = C_NULL
                    manual_viewport_created_global[] = false
                    println("✅ Manual viewport cleaned up")
                end
                
                # Render the manual viewport window (no event handling here)
                if manual_viewport_renderer != C_NULL && manual_viewport_window != C_NULL
                    # Clear with a pleasant blue background
                    SDL2.SDL_SetRenderDrawColor(manual_viewport_renderer, 30, 144, 255, 255)  # Dodger blue
                    SDL2.SDL_RenderClear(manual_viewport_renderer)
                    
                    # Draw a simple pattern to show it's working
                    SDL2.SDL_SetRenderDrawColor(manual_viewport_renderer, 255, 255, 255, 255)  # White
                    
                    # Draw some rectangles
                    for i in 1:5
                        rect = SDL2.SDL_Rect(50 + i*30, 50 + i*20, 80, 60)
                        SDL2.SDL_RenderDrawRect(manual_viewport_renderer, Ref(rect))
                    end
                    
                    # Draw title text area (just a filled rectangle for now)
                    SDL2.SDL_SetRenderDrawColor(manual_viewport_renderer, 255, 255, 0, 255)  # Yellow
                    title_rect = SDL2.SDL_Rect(10, 10, 380, 30)
                    SDL2.SDL_RenderFillRect(manual_viewport_renderer, Ref(title_rect))
                    
                    # Show mouse position if this window has mouse focus
                    focused_window = SDL2.SDL_GetMouseFocus()
                    if focused_window == manual_viewport_window
                        mouse_x_ref = Ref{Cint}(0)
                        mouse_y_ref = Ref{Cint}(0)
                        SDL2.SDL_GetMouseState(mouse_x_ref, mouse_y_ref)
                        
                        # Draw mouse indicator (small filled circle)
                        SDL2.SDL_SetRenderDrawColor(manual_viewport_renderer, 255, 0, 0, 255)  # Red
                        mouse_size = 5
                        mouse_rect = SDL2.SDL_Rect(
                            mouse_x_ref[] - mouse_size, 
                            mouse_y_ref[] - mouse_size, 
                            mouse_size * 2, 
                            mouse_size * 2
                        )
                        SDL2.SDL_RenderFillRect(manual_viewport_renderer, Ref(mouse_rect))
                    end
                    
                    # Present the manual viewport (only once per frame)
                    SDL2.SDL_RenderPresent(manual_viewport_renderer)
                end
            end
        end
        
    catch e
        @warn "ImGui error: $e"
    end
end

# Create actors
alien_image_path = joinpath(@__DIR__,"images", "alien.png")
alien = ImageFileActor("alien", [alien_image_path])
alien.x = SCREEN_WIDTH ÷ 2
alien.y = SCREEN_HEIGHT ÷ 2

eep_wav = joinpath(@__DIR__, "sounds", "283201-RubberBallBouncing7.wav")

label = TextActor(
    "this is some example text",
    joinpath(@__DIR__,"fonts","OpenSans-Regular.ttf"),
    outline_size=1,
    pt_size=24
)
label.x = SCREEN_WIDTH ÷ 4
label.y = SCREEN_HEIGHT ÷ 4

anim_fns = [joinpath(@__DIR__,"images","FireElem1","Visible$i.png") for i in 0:7]
anim = ImageFileActor("fireelem", anim_fns, anim=true)
anim.x = SCREEN_WIDTH ÷ 3
anim.y = SCREEN_HEIGHT ÷ 3

# Create rectangles
const red_rect = Rect(SCREEN_WIDTH ÷ 2, SCREEN_HEIGHT ÷ 2, 100, 100)
const blue_rect = Rect(50, 50, 50, 50)

# Initialize velocities for all actors
global dx_alien = 2
global dy_alien = 2
global dx_label = 2
global dy_label = 2
global dx_anim = 2
global dy_anim = 2
global dx_red = 3
global dy_red = 3
global dx_blue = 4
global dy_blue = 4

function draw(g::Game)    
    GameOne.draw(g.screen, alien)
    GameOne.draw(g.screen, label)
    GameOne.draw(g.screen, anim)
    
    # Add rectangles back
    GameOne.draw(g.screen, red_rect, c=colorant"red")
    GameOne.draw(g.screen, blue_rect, c=colorant"blue")
end

function update(g::Game)
    global dx_alien, dy_alien, dx_label, dy_label, dx_anim, dy_anim
    global dx_red, dy_red, dx_blue, dy_blue
    
    if Bool(window_paused[])
        return
    end

    # Update positions for all actors
    alien.x += dx_alien
    alien.y += dy_alien
    label.x += dx_label
    label.y += dy_label
    anim.x += dx_anim
    anim.y += dy_anim
    
    # Update rectangle positions
    red_rect.x += dx_red
    red_rect.y += dy_red
    blue_rect.x += dx_blue
    blue_rect.y += dy_blue

    # Handle FireElem animation
    if now() - anim.data[:then] > Millisecond(120)
        next_frame!(anim)
    end

    # ALIEN BOUNCING - Both horizontal AND vertical with 2px margin
    if alien.x > SCREEN_WIDTH - alien.w - 2 || alien.x < 2
        dx_alien = -dx_alien
        play_sound(eep_wav)
    end
    if alien.y > SCREEN_HEIGHT - alien.h - 2 || alien.y < 2
        dy_alien = -dy_alien
        play_sound(eep_wav)
    end

    # LABEL BOUNCING - Both horizontal AND vertical with 2px margin
    if label.x > SCREEN_WIDTH - label.w - 2 || label.x < 2
        dx_label = -dx_label
        play_sound(eep_wav)
    end
    if label.y > SCREEN_HEIGHT - label.h - 2 || label.y < 2
        dy_label = -dy_label
        play_sound(eep_wav)
    end

    # ANIM BOUNCING - Both horizontal AND vertical with 2px margin
    if anim.x > SCREEN_WIDTH - anim.w - 2 || anim.x < 2
        dx_anim = -dx_anim
        play_sound(eep_wav)
    end
    if anim.y > SCREEN_HEIGHT - anim.h - 2 || anim.y < 2
        dy_anim = -dy_anim
        play_sound(eep_wav)
    end

    # RED RECTANGLE BOUNCING - Both horizontal AND vertical with 2px margin
    if red_rect.x > SCREEN_WIDTH - red_rect.w - 2 || red_rect.x < 2
        dx_red = -dx_red
        play_sound(eep_wav)
    end
    if red_rect.y > SCREEN_HEIGHT - red_rect.h - 2 || red_rect.y < 2
        dy_red = -dy_red
        play_sound(eep_wav)
    end

    # BLUE RECTANGLE BOUNCING - Both horizontal AND vertical with 2px margin
    if blue_rect.x > SCREEN_WIDTH - blue_rect.w - 2 || blue_rect.x < 2
        dx_blue = -dx_blue
        play_sound(eep_wav)
    end
    if blue_rect.y > SCREEN_HEIGHT - blue_rect.h - 2 || blue_rect.y < 2
        dy_blue = -dy_blue
        play_sound(eep_wav)
    end

    # Handle keyboard input for alien movement
    if g.keyboard.DOWN
        dy_alien = abs(dy_alien)   # Move down
    elseif g.keyboard.UP
        dy_alien = -abs(dy_alien)  # Move up
    elseif g.keyboard.LEFT
        dx_alien = -abs(dx_alien)  # Move left
    elseif g.keyboard.RIGHT
        dx_alien = abs(dx_alien)   # Move right
    end
end

atexit(TTF_Quit)

# Cleanup function for manual viewport
function cleanup_viewport()
    try
        # Reset global variables
        manual_viewport_window_global[] = C_NULL
        manual_viewport_created_global[] = false
    catch e
        println("⚠️ Error resetting global variables: $e")
    end
end

atexit(cleanup_viewport)

end # module Example1

using GameOne

if abspath(PROGRAM_FILE) == @__FILE__
  rungame("ex1", false, game_mods=Dict("ex1" => Example1))
end