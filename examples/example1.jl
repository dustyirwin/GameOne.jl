
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
global dx = 3
global dy = 3
global dx2 = 3
global dy2 = 3


function text_input_with_hint_single_line(name::String, hint::String, filters = CImGui.ImGuiInputTextFlags_None)
    currentText = ""
    @cstatic buf=""*"\0"^128 begin
        CImGui.InputTextWithHint(name, hint, buf, length(buf), filters)
        for characterIndex = eachindex(buf)
            if Int32(buf[characterIndex]) == 0 # The end of the buffer will be recognized as a 0
                currentText =  characterIndex == 1 ? "" : String(SubString(buf, 1, characterIndex - 1))
                break
            end
        end

        return currentText
    end
end

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

    command_text = "Welcome to the console!\n"
    response_text = ""
    command_history = []

    if g.imgui_settings["show_console"]
        
        if CImGui.Begin("Console")
            CImGui.SetWindowSize((280,140))
            
            @cstatic txt=""*"\0"^512  begin
                # Widget labels CANNOT match any other label in widget?
                if CImGui.InputTextWithHint(" ", "  <command>  ", txt, length(txt))  
                    println(txt)
                end

                command_text = rstrip(string(txt),'\0')
                CImGui.Text(command_text)
            end
            
            CImGui.NewLine()
            
            if CImGui.Button("Run")
                println("Run button clicked")
                # Add your run logic here
                
                try
                    io = IOBuffer()
                    ex = Meta.parse(command_text)
                    @info "command_text: $command_text"
                    show(IOContext(io, :limit => true, :displaysize => (500, 250)), "text/plain", eval(g.game_module, ex))
                    response_text = String(take!(io))
                    @info "response_text: $response_text"
                    push!(command_history, command_text)
                catch e
                    @warn e
                end
            end

            CImGui.SameLine()
            
            if CImGui.Button("Clear")
                println("Clear button clicked")
                # Add your clear logic here
                command_text = ""
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
#alien = ImageFileActor("alien1", [joinpath(@__DIR__,"images","alien.png")])
alien = ImageFileActor("alien1", [joinpath("examples", "images", "alien.png")])

#alien_hurt_img = load("$(@__DIR__)/images/alien_hurt.png")
#alien_ok_img = ["$(@__DIR__)/images/alien.png"]
#alien2 = ImageMemActor("alien2", alien_hurt_img)

# sound effects
eep_wav = joinpath(@__DIR__, "sounds", "283201-RubberBallBouncing7.wav")
cat_growl = joinpath(@__DIR__, "sounds", "39 Tom Cat Growling, Individual Grow.wav")
harp = joinpath(@__DIR__, "sounds", "harp-glissando-descending-short-103886.mp3")

# Create an `TextActor` object from an empty string for terminal use
#terminal = TextActor(">", "$(@__DIR__)/fonts/OpenSans-Regular.ttf", outline_size=1, pt_size=35)
#terminal.alpha = 0


#=
label = TextActor(
    "this is some example text",
    "$(@__DIR__)/fonts/OpenSans-Regular.ttf",
    outline_size=1,
    pt_size=24
    )
#label.x = 25
label.y = 25
=#

    
#load a custom animation
anim_fns = ["$(@__DIR__)/images/FireElem1/Visible$i.png" for i in 0:7]
anim = ImageFileActor("fireelem", anim_fns)
anim.data[:next_frame] = true
anim.y = 50
anim.x = 10


# Start playing background music

play_music("$(@__DIR__)/examples/music/radetzky_ogg")

# The draw function is called by the framework. All we do here is draw the Actor
function draw(g::Game)
    draw(anim)
    draw(alien)
end


# The update function is called every frame. Within the function, we
# * change the position of the actor by the velocity
# * if the actor hits the edges, we invert the velocity, and play a sound
# * if the up/down/left/right keys are pressed, we change the velocity to move the actor in the direction of the keypress

function update(g::Game)
    global dx, dy, dx2, dy2, anim, wanim

    if Bool(window_paused[])
        nothing
    else
        alien.position.x += dx
        alien.position.y += dy

        if anim.data[:next_frame]
            if now() - anim.data[:then] > Millisecond(120)
                next_frame!(anim)
            end
        end
        
        if alien.x > SCREEN_WIDTH - alien.w || alien.x < 2
            dx = -dx
            play_sound(eep_wav)
        end
        
        if alien.y > SCREEN_HEIGHT - alien.h || alien.y < 2
            dy = -dy
            play_sound(eep_wav)
        end
    end

    if g.keyboard.DOWN
        dy = 1
    elseif g.keyboard.UP
        dy = -1
    elseif g.keyboard.LEFT
        dx = -1
    elseif g.keyboard.RIGHT
        dx = 1
    end
end

# If the "space" key is pressed, change the displayed image to the "hurt" variant.
# Also schedule an event to change it back to normal after one second.
# We define functions to change the image for the actor. These functions are called 
# from the keydown and scheduled events.


alien_hurt() = alien.image = "images/alien_hurt.png"
alien_normal() = alien.image = "images/alien.png"

#=command_history = ["@show alien.label"]

function on_key_down(g, key, keymod)
    # start terminal and accept input text to be parsed and executed by
    if key == Keys.BACKQUOTE
        @info "Terminal Started!"
        terminal.alpha = 255
        draw(g)
        SDL_RenderPresent(g.screen.renderer)
        update_text_actor!(terminal, ">")
        text = start_text_input(g, terminal)
        terminal.alpha = 150
        update_text_actor!(terminal, "evaluating: $text...")

        # evaluate entered text
        try
            io = IOBuffer()
            ex = Meta.parse(text)
            show(IOContext(io, :limit => true, :displaysize => (500, 250)), "text/plain", eval(g.game_module, ex))
            s = String(take!(io))
            update_text_actor!(terminal, s)
            #push!(command_history, text)
        catch e
            @warn e
        end

        schedule_once(() -> terminal.alpha = 0, 4)
        #=
        =#
    end
end

if !isempty(Base.PROGRAM_FILE)
    rungame()
end
=#