
module Example1

using GameOne

TTF_Init() # Initialize SDL_ttf
Mix_Init(MIX_INIT_MP3) # Initialize SDL_mixer

# Primary window dimensions
const PRIMARY_WIDTH = 800
const PRIMARY_HEIGHT = 600
const PRIMARY_BACKGROUND = colorant"black"

# Secondary window dimensions
const SECONDARY_WIDTH = 400  # Half the width of primary
const SECONDARY_HEIGHT = 600
const SECONDARY_BACKGROUND = colorant"black"

# Title of the game window
const PRIMARY_NAME = "Main"
const SECONDARY_NAME = "Secondary"

# Globals to store the velocity of the actor
global a_dx = 3  # Positive value to move right initially
global a_dy = 3  # Positive value to move down initially
global t_dx = 2
global t_dy = 2

# Create rectangles with proper dimensions and initial window assignments
const red_rect = MoveableRect(PRIMARY_WIDTH ÷ 2, PRIMARY_HEIGHT ÷ 2, 100, 100, 1)
const blue_rect = MoveableRect(50, 50, 50, 50, 2)

# Initialize velocities for rectangles
global dx_red = 3
global dy_red = 3
global dx_blue = 4
global dy_blue = 4

"""
    HelpMarker(msg::AbstractString)

A port of the `HelpMarker()` function from the Dear ImGui demo. This will draw a
grayed out '(?)' text on the screen with `msg` as the tooltip.
"""
function HelpMarker(msg::AbstractString)
    TextDisabled("(?)")

    if IsItemHovered() && BeginTooltip()
        PushTextWrapPos(GetFontSize() * 35.0)
        TextUnformatted(msg)
        PopTextWrapPos()
        EndTooltip()
    end
end

function imgui(g::Game)
    try
        current_screen = get(g.imgui_settings, "current_screen", "primary")
        
        if current_screen == "primary"
            # PRIMARY SCREEN ImGui windows
            CImGui.SetNextWindowPos(ImVec2(10, 10), CImGui.ImGuiCond_FirstUseEver)
            CImGui.SetNextWindowSize(ImVec2(300, 250), CImGui.ImGuiCond_FirstUseEver)
            if CImGui.Begin("Primary Debug Window")
                CImGui.Text("🖥️ Primary Screen Controls")
                
                # Demo window toggle
                @cstatic show_demo=false begin
                    if CImGui.Button("Toggle Demo")
                        show_demo = !show_demo
                    end
                    
                    if show_demo
                        CImGui.ShowDemoWindow(Ref(show_demo))
                    end
                end

                # Text input
                @cstatic begin
                    buffer = zeros(UInt8, 100)
                    CImGui.InputText("Primary Input", buffer, length(buffer))
                end
                
                CImGui.Separator()
                CImGui.Text("Screen Status:")
                CImGui.Text("Active Screen: $(g.screens.active_screen)")
                CImGui.Text("Primary has focus: $(g.screens.primary.has_focus)")
                CImGui.Text("Secondary has focus: $(g.screens.secondary.has_focus)")
                
                CImGui.Separator()
                CImGui.Text("Controls:")
                if CImGui.Button("Play Sound")
                    play_sound(eep_wav)
                end
                
                # Interactive controls
                @cstatic slider_val=0.5 begin
                    if CImGui.SliderFloat("Primary Slider", Ref(slider_val), 0.0, 1.0)
                        g.imgui_settings["primary_slider"] = slider_val
                    end
                end
                
                # Display secondary screen data
                secondary_slider = get(g.imgui_settings, "secondary_slider", 0.0)
                CImGui.Text("Secondary Slider Value: $(round(secondary_slider, digits=3))")
            end
            CImGui.End()
            
        elseif current_screen == "secondary"
            # SECONDARY SCREEN ImGui windows
            CImGui.SetNextWindowPos(ImVec2(10, 10), CImGui.ImGuiCond_FirstUseEver)
            CImGui.SetNextWindowSize(ImVec2(300, 250), CImGui.ImGuiCond_FirstUseEver)
            if CImGui.Begin("Secondary Debug Window")
                CImGui.Text("📺 Secondary Screen Controls")
                
                # Secondary-specific controls
                @cstatic begin
                    buffer2 = zeros(UInt8, 100)
                    CImGui.InputText("Secondary Input", buffer2, length(buffer2))
                end
                
                if CImGui.Button("Secondary Action")
                    @info "Secondary button clicked!"
                    play_sound(harp)
                end
                
                CImGui.Separator()
                CImGui.Text("Actor Positions:")
                CImGui.Text("Alien: ($(Int(alien.x)), $(Int(alien.y))) Screen: $(alien.current_screen)")
                CImGui.Text("Label: ($(Int(label.x)), $(Int(label.y))) Screen: $(label.current_screen)")
                CImGui.Text("Anim: ($(Int(anim.x)), $(Int(anim.y))) Screen: $(anim.current_screen)")
                
                CImGui.Separator()
                CImGui.Text("Velocities:")
                CImGui.Text("Alien: dx=$(dx_alien), dy=$(dy_alien)")
                CImGui.Text("Label: dx=$(dx_label), dy=$(dy_label)")
                CImGui.Text("Anim: dx=$(dx_anim), dy=$(dy_anim)")
                
                # Interactive slider
                @cstatic sec_slider=0.7 begin
                    if CImGui.SliderFloat("Secondary Slider", Ref(sec_slider), 0.0, 2.0)
                        g.imgui_settings["secondary_slider"] = sec_slider
                    end
                end
                
                # Display primary screen data
                primary_slider = get(g.imgui_settings, "primary_slider", 0.0)
                CImGui.Text("Primary Slider Value: $(round(primary_slider, digits=3))")
                
                if CImGui.Button("Reset Positions")
                    alien.x = PRIMARY_WIDTH ÷ 2
                    alien.y = PRIMARY_HEIGHT ÷ 2
                    alien.current_screen = UInt32(1)
                    
                    label.x = PRIMARY_WIDTH ÷ 4
                    label.y = PRIMARY_HEIGHT ÷ 4
                    label.current_screen = UInt32(1)
                    
                    anim.x = PRIMARY_WIDTH ÷ 3
                    anim.y = PRIMARY_HEIGHT ÷ 3
                    anim.current_screen = UInt32(1)
                end
            end
            CImGui.End()

            # Additional secondary window for system info
            CImGui.SetNextWindowPos(ImVec2(10, 280), CImGui.ImGuiCond_FirstUseEver)
            CImGui.SetNextWindowSize(ImVec2(300, 200), CImGui.ImGuiCond_FirstUseEver)
            if CImGui.Begin("System Info")
                CImGui.Text("🔧 System Information")
                CImGui.Text("Current Time: $(now())")
                CImGui.Text("Window Paused: $(Bool(window_paused[]))")
                CImGui.Text("Primary Size: $(g.screens.primary.width)x$(g.screens.primary.height)")
                CImGui.Text("Secondary Size: $(g.screens.secondary.width)x$(g.screens.secondary.height)")
            end
            CImGui.End()
        end
        
    catch e
        @warn "ImGui error: $e"
    end
end

# Create an `ImageActor` object from a PNG file
alien_image_path = joinpath(@__DIR__,"images", "alien.png")
@assert isfile(alien_image_path) "Alien image not found at: $alien_image_path"
alien = ImageFileActor("alien", [alien_image_path], current_screen=UInt32(1))  # 1 for primary
@debug "Created alien actor with image: $alien_image_path"
alien.position.x = PRIMARY_WIDTH ÷ 2  # Start in the middle of the screen
alien.position.y = PRIMARY_HEIGHT ÷ 2  # Start in the middle of the screen

# sound effects
eep_wav = joinpath(@__DIR__, "sounds", "283201-RubberBallBouncing7.wav")
cat_growl = joinpath(@__DIR__, "sounds", "39 Tom Cat Growling, Individual Grow.wav")
harp = joinpath(@__DIR__, "sounds", "harp-glissando-descending-short-103886.mp3")

# Create text actor with dual screen support
label = TextActor(
    "this is some example text",
    joinpath(@__DIR__,"fonts","OpenSans-Regular.ttf"),
    outline_size=1,
    pt_size=24,
    current_screen=UInt32(1)  # 1 for primary
)
label.position.x = PRIMARY_WIDTH ÷ 4  # Start at 1/4 of screen width
label.position.y = PRIMARY_HEIGHT ÷ 4  # Start at 1/4 of screen height
#= 
=#

# Load a custom animation with dual screen support
anim_fns = [joinpath(@__DIR__,"images","FireElem1","Visible$i.png") for i in 0:7]
anim = ImageFileActor("fireelem", anim_fns, current_screen=UInt32(1), anim=true)  # Set anim=true
anim.position.x = PRIMARY_WIDTH ÷ 3  # Start at 1/3 of screen width
anim.position.y = PRIMARY_HEIGHT ÷ 3  # Start at 1/3 of screen height

# Initialize velocities for all actors globally
global dx_alien = 2  # Alien velocity
global dy_alien = 2
global dx_label = 2  # Text velocity
global dy_label = 2
global dx_anim = 2   # FireElem velocity
global dy_anim = 2

# Start playing background music

play_music(joinpath(@__DIR__,"music","radetzky.ogg"))

# The draw function is called by the framework
function draw(g::Game)    
    # Draw existing actors on their respective screens
    GameOne.draw(g.screens, alien)
    GameOne.draw(g.screens, label)
    GameOne.draw(g.screens, anim)
    
    # Draw rectangles on their respective screens
    if red_rect.current_screen == UInt32(1)
        GameOne.draw(g.screens.primary, red_rect; c=colorant"red", fill=false)
    else
        GameOne.draw(g.screens.secondary, red_rect; c=colorant"red", fill=true)
    end
    
    if blue_rect.current_screen == UInt32(1)
        GameOne.draw(g.screens.primary, blue_rect; c=colorant"blue", fill=true)
    else
        GameOne.draw(g.screens.secondary, blue_rect; c=colorant"blue", fill=false)
    end
end

# Update function to handle movement and screen transitions for all actors
function update(g::Game)
    global dx_alien, dy_alien, dx_label, dy_label, dx_anim, dy_anim
    global dx_red, dy_red, dx_blue, dy_blue
    
    if Bool(window_paused[])
        return
    end

    # Update positions for existing actors
    alien.x += dx_alien
    alien.y += dy_alien
    label.x += dx_label
    label.y += dy_label
    anim.x += dx_anim
    anim.y += dy_anim

    # Update rectangle positions
    red_rect.position.x += dx_red
    red_rect.position.y += dy_red
    blue_rect.position.x += dx_blue
    blue_rect.position.y += dy_blue

    # Handle FireElem animation
    if now() - anim.data[:then] > Millisecond(120)
        next_frame!(anim)
    end

    # Handle screen transitions and bouncing for red rectangle
    if red_rect.current_screen == UInt32(1)
        # Primary window bounds for red rectangle
        if red_rect.position.x > PRIMARY_WIDTH - red_rect.position.w
            red_rect.current_screen = UInt32(2)  # Switch to secondary
            red_rect.position.x = 0
        elseif red_rect.position.x < 0
            dx_red = -dx_red  # Bounce off left edge
        end
    else  # In secondary window
        if red_rect.position.x > SECONDARY_WIDTH - red_rect.position.w
            dx_red = -dx_red  # Bounce off right edge
        elseif red_rect.position.x < 0
            red_rect.current_screen = UInt32(1)  # Switch to primary
            red_rect.position.x = PRIMARY_WIDTH - red_rect.position.w
        end
    end
    # Vertical bouncing (same for both windows)
    if red_rect.position.y > PRIMARY_HEIGHT - red_rect.position.h || red_rect.position.y < 0
        dy_red = -dy_red
    end

    # Handle screen transitions and bouncing for blue rectangle
    if blue_rect.current_screen == UInt32(1)
        # Primary window bounds for blue rectangle
        if blue_rect.position.x > PRIMARY_WIDTH - blue_rect.position.w
            blue_rect.current_screen = UInt32(2)  # Switch to secondary
            blue_rect.position.x = 0
        elseif blue_rect.position.x < 0
            dx_blue = -dx_blue  # Bounce off left edge
        end
    else  # In secondary window
        if blue_rect.position.x > SECONDARY_WIDTH - blue_rect.position.w
            dx_blue = -dx_blue  # Bounce off right edge
        elseif blue_rect.position.x < 0
            blue_rect.current_screen = UInt32(1)  # Switch to primary
            blue_rect.position.x = PRIMARY_WIDTH - blue_rect.position.w
        end
    end
    # Vertical bouncing (same for both windows)
    if blue_rect.position.y > PRIMARY_HEIGHT - blue_rect.position.h || blue_rect.position.y < 0
        dy_blue = -dy_blue
    end

    # Check boundaries and handle screen transitions for alien
    if alien.current_screen == UInt32(1) && alien.x > PRIMARY_WIDTH - alien.w  # Right edge of primary
        alien.current_screen = UInt32(2)  # Switch to secondary
        alien.x = 2  # Place at left edge of secondary window
        play_sound(eep_wav)
    elseif alien.current_screen == UInt32(2) && alien.position.x < 2  # Left edge of secondary
        alien.current_screen = UInt32(1)  # Switch to primary
        alien.x = PRIMARY_WIDTH - alien.w - 2  # Place at right edge of primary
        play_sound(eep_wav)
    elseif (alien.current_screen == UInt32(1) && alien.x < 2) ||  # Left edge of primary
           (alien.current_screen == UInt32(2) && alien.x > SECONDARY_WIDTH - alien.w)  # Right edge of secondary
        dx_alien = -dx_alien  # Bounce back
        play_sound(eep_wav)
    end
    
    if alien.y > PRIMARY_HEIGHT - alien.h || alien.y < 2
        dy_alien = -dy_alien
        play_sound(eep_wav)
    end

    # Check boundaries and handle screen transitions for text
    if label.current_screen == UInt32(1) && label.x > PRIMARY_WIDTH - label.w  # Right edge of primary
        label.current_screen = UInt32(2)  # Switch to secondary
        label.x = 2  # Place at left edge of secondary window
        play_sound(eep_wav)
    elseif label.current_screen == UInt32(2) && label.x < 2  # Left edge of secondary
        label.current_screen = UInt32(1)  # Switch to primary
        label.x = PRIMARY_WIDTH - label.w - 2  # Place at right edge of primary
        play_sound(eep_wav)
    elseif (label.current_screen == UInt32(1) && label.x < 2) ||  # Left edge of primary
           (label.current_screen == UInt32(2) && label.x > SECONDARY_WIDTH - label.w)  # Right edge of secondary
        dx_label = -dx_label  # Bounce back
        play_sound(eep_wav)
    end
    
    if label.y > PRIMARY_HEIGHT - label.h || label.y < 2
        dy_label = -dy_label
        play_sound(eep_wav)
    end

    # Check boundaries and handle screen transitions for FireElem
    if anim.current_screen == UInt32(1) && anim.x > PRIMARY_WIDTH - anim.w  # Right edge of primary
        anim.current_screen = UInt32(2)  # Switch to secondary
        anim.x = 2  # Place at left edge of secondary window
        play_sound(eep_wav)
    elseif anim.current_screen == UInt32(2) && anim.x < 2  # Left edge of secondary
        anim.current_screen = UInt32(1)  # Switch to primary
        anim.x = PRIMARY_WIDTH - anim.w - 2  # Place at right edge of primary
        play_sound(eep_wav)
    elseif (anim.current_screen == UInt32(1) && anim.x < 2) ||  # Left edge of primary
           (anim.current_screen == UInt32(2) && anim.x > SECONDARY_WIDTH - anim.w)  # Right edge of secondary
        dx_anim = -dx_anim  # Bounce back
        play_sound(eep_wav)
    end
    
    if anim.y > PRIMARY_HEIGHT - anim.h || anim.y < 2
        dy_anim = -dy_anim
        play_sound(eep_wav)
    end

    # Handle keyboard input for alien movement
    if g.keyboard.DOWN
        dy_alien = 1
    elseif g.keyboard.UP
        dy_alien = -1
    elseif g.keyboard.LEFT
        dx_alien = -1
    elseif g.keyboard.RIGHT
        dx_alien = 1
    end
end

# Optionally, add cleanup at the end
atexit(TTF_Quit)

end # module Example1

using GameOne

# Auto-run when executed directly
if abspath(PROGRAM_FILE) == @__FILE__
  rungame("ex1", false, game_mods=Dict("ex1" => Example1))
end