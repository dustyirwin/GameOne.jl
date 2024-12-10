ENV["JULIA_DEBUG"] = "GameOne"

pwd()

#cd("examples")
#using Pkg
#Pkg.activate(".")

#using Images
using GameOne

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
    if g.screens.active_screen == UInt32(1)  # Only render ImGui on primary screen
        # Wrap ImGui calls in try-catch to prevent crashes
        try
            # Create a proper window with Begin/End
            if CImGui.Begin("Debug Window")
                # Demo window toggle
                show_demo = Ref{Bool}(false)
                if CImGui.Button("Demo")
                    show_demo[] = !show_demo[]
                end
                
                if show_demo[]
                    CImGui.ShowDemoWindow(show_demo)
                end

                # Text input using fixed buffer
                @cstatic begin
                    buffer = zeros(UInt8, 100)
                    CImGui.InputText("Input", buffer, length(buffer))
                    text = String(buffer[1:findfirst(iszero, buffer)-1])
                end
            end
            CImGui.End()
        catch e
            @warn "ImGui error: $e"
        end
    end
end

function next_frame!(a::Actor)
    circshift!(a.textures, -1)
    a.data[:then] = now()
    return a
end

# Create an `ImageActor` object from a PNG file
alien_image_path = joinpath("examples", "images", "alien.png")
@assert isfile(alien_image_path) "Alien image not found at: $alien_image_path"
alien = ImageFileActor("alien", [alien_image_path], current_window=UInt32(1))  # 1 for primary
@debug "Created alien actor with image: $alien_image_path"
alien.x = PRIMARY_WIDTH ÷ 2  # Start in the middle of the screen
alien.y = PRIMARY_HEIGHT ÷ 2  # Start in the middle of the screen

# sound effects
eep_wav = joinpath(@__DIR__, "sounds", "283201-RubberBallBouncing7.wav")
cat_growl = joinpath(@__DIR__, "sounds", "39 Tom Cat Growling, Individual Grow.wav")
harp = joinpath(@__DIR__, "sounds", "harp-glissando-descending-short-103886.mp3")

# Create text actor with dual screen support
label = TextActor(
    "this is some example text",
    "$(@__DIR__)/fonts/OpenSans-Regular.ttf",
    outline_size=1,
    pt_size=24,
    current_window=UInt32(1)  # 1 for primary
)
label.x = PRIMARY_WIDTH ÷ 4  # Start at 1/4 of screen width
label.y = PRIMARY_HEIGHT ÷ 4  # Start at 1/4 of screen height

# Load a custom animation with dual screen support
anim_fns = ["$(@__DIR__)/images/FireElem1/Visible$i.png" for i in 0:7]
anim = ImageFileActor("fireelem", anim_fns, current_window=UInt32(1))  # 1 for primary
anim.data[:next_frame] = true
anim.x = PRIMARY_WIDTH ÷ 3  # Start at 1/3 of screen width
anim.y = PRIMARY_HEIGHT ÷ 3  # Start at 1/3 of screen height

# Initialize velocities for all actors globally
global dx_alien = 2  # Alien velocity
global dy_alien = 2
global dx_label = 2  # Text velocity
global dy_label = 2
global dx_anim = 2   # FireElem velocity
global dy_anim = 2

# Start playing background music

play_music("$(@__DIR__)/examples/music/radetzky_ogg")

# The draw function is called by the framework
function draw(g::Game)    
    # Draw existing actors on their respective screens
    draw(g.screens, alien)
    draw(g.screens, label)
    draw(g.screens, anim)
    
    # Draw rectangles on their respective screens
    if red_rect.current_window == UInt32(1)
        draw(g.screens.primary, red_rect; c=colorant"red", fill=false)
    else
        draw(g.screens.secondary, red_rect; c=colorant"red", fill=true)
    end
    
    if blue_rect.current_window == UInt32(1)
        draw(g.screens.primary, blue_rect; c=colorant"blue", fill=true)
    else
        draw(g.screens.secondary, blue_rect; c=colorant"blue", fill=false)
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
    if anim.data[:next_frame] && now() - anim.data[:then] > Millisecond(120)
        next_frame!(anim)
    end

    # Handle screen transitions and bouncing for red rectangle
    if red_rect.current_window == UInt32(1)
        # Primary window bounds for red rectangle
        if red_rect.position.x > PRIMARY_WIDTH - red_rect.position.w
            red_rect.current_window = UInt32(2)  # Switch to secondary
            red_rect.position.x = 0
        elseif red_rect.position.x < 0
            dx_red = -dx_red  # Bounce off left edge
        end
    else  # In secondary window
        if red_rect.position.x > SECONDARY_WIDTH - red_rect.position.w
            dx_red = -dx_red  # Bounce off right edge
        elseif red_rect.position.x < 0
            red_rect.current_window = UInt32(1)  # Switch to primary
            red_rect.position.x = PRIMARY_WIDTH - red_rect.position.w
        end
    end
    # Vertical bouncing (same for both windows)
    if red_rect.position.y > PRIMARY_HEIGHT - red_rect.position.h || red_rect.position.y < 0
        dy_red = -dy_red
    end

    # Handle screen transitions and bouncing for blue rectangle
    if blue_rect.current_window == UInt32(1)
        # Primary window bounds for blue rectangle
        if blue_rect.position.x > PRIMARY_WIDTH - blue_rect.position.w
            blue_rect.current_window = UInt32(2)  # Switch to secondary
            blue_rect.position.x = 0
        elseif blue_rect.position.x < 0
            dx_blue = -dx_blue  # Bounce off left edge
        end
    else  # In secondary window
        if blue_rect.position.x > SECONDARY_WIDTH - blue_rect.position.w
            dx_blue = -dx_blue  # Bounce off right edge
        elseif blue_rect.position.x < 0
            blue_rect.current_window = UInt32(1)  # Switch to primary
            blue_rect.position.x = PRIMARY_WIDTH - blue_rect.position.w
        end
    end
    # Vertical bouncing (same for both windows)
    if blue_rect.position.y > PRIMARY_HEIGHT - blue_rect.position.h || blue_rect.position.y < 0
        dy_blue = -dy_blue
    end

    # Check boundaries and handle screen transitions for alien
    if alien.current_window == UInt32(1) && alien.x > PRIMARY_WIDTH - alien.w  # Right edge of primary
        alien.current_window = UInt32(2)  # Switch to secondary
        alien.x = 2  # Place at left edge of secondary window
        play_sound(eep_wav)
    elseif alien.current_window == UInt32(2) && alien.position.x < 2  # Left edge of secondary
        alien.current_window = UInt32(1)  # Switch to primary
        alien.x = PRIMARY_WIDTH - alien.w - 2  # Place at right edge of primary
        play_sound(eep_wav)
    elseif (alien.current_window == UInt32(1) && alien.x < 2) ||  # Left edge of primary
           (alien.current_window == UInt32(2) && alien.x > SECONDARY_WIDTH - alien.w)  # Right edge of secondary
        dx_alien = -dx_alien  # Bounce back
        play_sound(eep_wav)
    end
    
    if alien.y > PRIMARY_HEIGHT - alien.h || alien.y < 2
        dy_alien = -dy_alien
        play_sound(eep_wav)
    end

    # Check boundaries and handle screen transitions for text
    if label.current_window == UInt32(1) && label.x > PRIMARY_WIDTH - label.w  # Right edge of primary
        label.current_window = UInt32(2)  # Switch to secondary
        label.x = 2  # Place at left edge of secondary window
        play_sound(eep_wav)
    elseif label.current_window == UInt32(2) && label.x < 2  # Left edge of secondary
        label.current_window = UInt32(1)  # Switch to primary
        label.x = PRIMARY_WIDTH - label.w - 2  # Place at right edge of primary
        play_sound(eep_wav)
    elseif (label.current_window == UInt32(1) && label.x < 2) ||  # Left edge of primary
           (label.current_window == UInt32(2) && label.x > SECONDARY_WIDTH - label.w)  # Right edge of secondary
        dx_label = -dx_label  # Bounce back
        play_sound(eep_wav)
    end
    
    if label.y > PRIMARY_HEIGHT - label.h || label.y < 2
        dy_label = -dy_label
        play_sound(eep_wav)
    end

    # Check boundaries and handle screen transitions for FireElem
    if anim.current_window == UInt32(1) && anim.x > PRIMARY_WIDTH - anim.w  # Right edge of primary
        anim.current_window = UInt32(2)  # Switch to secondary
        anim.x = 2  # Place at left edge of secondary window
        play_sound(eep_wav)
    elseif anim.current_window == UInt32(2) && anim.x < 2  # Left edge of secondary
        anim.current_window = UInt32(1)  # Switch to primary
        anim.x = PRIMARY_WIDTH - anim.w - 2  # Place at right edge of primary
        play_sound(eep_wav)
    elseif (anim.current_window == UInt32(1) && anim.x < 2) ||  # Left edge of primary
           (anim.current_window == UInt32(2) && anim.x > SECONDARY_WIDTH - anim.w)  # Right edge of secondary
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

