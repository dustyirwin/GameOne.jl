ENV["JULIA_DEBUG"] = "GameOne"

pwd()

#cd("examples")
#using Pkg
#Pkg.activate(".")

#using Images
using GameOne

# Width of the game window
SCREEN_WIDTH = 800
# Height of the game window
SCREEN_HEIGHT = 600
# Background color of the game window
BACKGROUND = colorant"black"
# Title of the game window
SCREEN_NAME = "Main"

# Globals to store the velocity of the actor
global a_dx = 3  # Positive value to move right initially
global a_dy = 3  # Positive value to move down initially
global t_dx = 2
global t_dy = 2


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
    
    #@c CImGui.ShowDemoWindow(Ref{Bool}(true))

    show_login = true
    username = ""
    password = ""

    if g.imgui_settings["show_login"] 
        if CImGui.Begin("Login")
            CImGui.SetWindowSize((280,140))
            
            @cstatic u=""*"\0"^128 p=""*"\0"^128 begin
                # Widget labels CANNOT match any other label in widget?
                if CImGui.InputTextWithHint(" ", "   <username>    ", u, length(u))  
                    @info u
                end
                
                CImGui.NewLine()

                # Widget text labels CANNOT match any other label in widget?
                if CImGui.InputTextWithHint("  ", "   <password>    ", p, length(p), CImGui.ImGuiInputTextFlags_Password)
                    @info p
                end

                username = rstrip(string(u),'\0')
                password = rstrip(string(p),'\0')
            end

            CImGui.NewLine()

            if CImGui.Button("Login")
                println("Username: ", username, " username_length: ", length(username))
                println("Password: ", password, " password_length: ", length(password))
                
                # Add your authentication logic here

                if "beep" == username && "boop" == password
                    println("Login successful")
                    play_sound(harp)
                    g.imgui_settings["show_login"]  = false
                    g.imgui_settings["show_console"] = true
                    window_paused[] = false
                else
                    println("Login failed")
                    play_sound(cat_growl)
                end
            end
        
            CImGui.SameLine()

            if CImGui.Button("Sign Up")
                println("Sign Up button clicked")
                # Add your sign up logic here
            end

            CImGui.End()
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
alien = ImageFileActor("alien", [alien_image_path], current_window=:primary)
@debug "Created alien actor with image: $alien_image_path"
alien.x = SCREEN_WIDTH ÷ 2  # Start in the middle of the screen
alien.y = SCREEN_HEIGHT ÷ 2  # Start in the middle of the screen

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
    current_window=:primary  # Start on primary screen
)
label.x = SCREEN_WIDTH ÷ 4  # Start at 1/4 of screen width
label.y = SCREEN_HEIGHT ÷ 4  # Start at 1/4 of screen height

# Load a custom animation with dual screen support
anim_fns = ["$(@__DIR__)/images/FireElem1/Visible$i.png" for i in 0:7]
anim = ImageFileActor("fireelem", anim_fns, current_window=:primary)  # Start on primary screen
anim.data[:next_frame] = true
anim.x = SCREEN_WIDTH ÷ 3  # Start at 1/3 of screen width
anim.y = SCREEN_HEIGHT ÷ 3  # Start at 1/3 of screen height

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
    @debug "Drawing actors..."
    @debug "Alien position: ($(alien.x), $(alien.y)), window: $(alien.current_window)"
    @debug "Label position: ($(label.x), $(label.y)), window: $(label.current_window)"
    @debug "FireElem position: ($(anim.x), $(anim.y)), window: $(anim.current_window)"
    
    # Draw actors on their respective screens
    draw(alien, g.screens)
    draw(label, g.screens)
    draw(anim, g.screens)
end

# Update function to handle movement and screen transitions for all actors
function update(g::Game)
    global dx_alien, dy_alien, dx_label, dy_label, dx_anim, dy_anim
    
    if Bool(window_paused[])
        return
    end

    # Update alien position
    alien.x += dx_alien
    alien.y += dy_alien

    # Update text position
    label.x += dx_label
    label.y += dy_label

    # Update FireElem position
    anim.x += dx_anim
    anim.y += dy_anim

    # Handle FireElem animation
    if anim.data[:next_frame] && now() - anim.data[:then] > Millisecond(120)
        next_frame!(anim)
    end

    # Check boundaries and handle screen transitions for alien
    if alien.current_window == :primary && alien.x > SCREEN_WIDTH - alien.w  # Right edge of primary
        alien.current_window = :secondary
        alien.x = 2  # Place at left edge of secondary window
        play_sound(eep_wav)
    elseif alien.current_window == :secondary && alien.x < 2  # Left edge of secondary
        alien.current_window = :primary
        alien.x = SCREEN_WIDTH - alien.w - 2  # Place at right edge of primary window
        play_sound(eep_wav)
    elseif (alien.current_window == :primary && alien.x < 2) ||  # Left edge of primary
           (alien.current_window == :secondary && alien.x > SCREEN_WIDTH - alien.w)  # Right edge of secondary
        dx_alien = -dx_alien  # Bounce back
        play_sound(eep_wav)
    end
    
    if alien.y > SCREEN_HEIGHT - alien.h || alien.y < 2
        dy_alien = -dy_alien
        play_sound(eep_wav)
    end

    # Check boundaries and handle screen transitions for text
    if label.current_window == :primary && label.x > SCREEN_WIDTH - label.w  # Right edge of primary
        label.current_window = :secondary
        label.x = 2  # Place at left edge of secondary window
        play_sound(eep_wav)
    elseif label.current_window == :secondary && label.x < 2  # Left edge of secondary
        label.current_window = :primary
        label.x = SCREEN_WIDTH - label.w - 2  # Place at right edge of primary window
        play_sound(eep_wav)
    elseif (label.current_window == :primary && label.x < 2) ||  # Left edge of primary
           (label.current_window == :secondary && label.x > SCREEN_WIDTH - label.w)  # Right edge of secondary
        dx_label = -dx_label  # Bounce back
        play_sound(eep_wav)
    end
    
    if label.y > SCREEN_HEIGHT - label.h || label.y < 2
        dy_label = -dy_label
        play_sound(eep_wav)
    end

    # Check boundaries and handle screen transitions for FireElem
    if anim.current_window == :primary && anim.x > SCREEN_WIDTH - anim.w  # Right edge of primary
        anim.current_window = :secondary
        anim.x = 2  # Place at left edge of secondary window
        play_sound(eep_wav)
    elseif anim.current_window == :secondary && anim.x < 2  # Left edge of secondary
        anim.current_window = :primary
        anim.x = SCREEN_WIDTH - anim.w - 2  # Place at right edge of primary window
        play_sound(eep_wav)
    elseif (anim.current_window == :primary && anim.x < 2) ||  # Left edge of primary
           (anim.current_window == :secondary && anim.x > SCREEN_WIDTH - anim.w)  # Right edge of secondary
        dx_anim = -dx_anim  # Bounce back
        play_sound(eep_wav)
    end
    
    if anim.y > SCREEN_HEIGHT - anim.h || anim.y < 2
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

