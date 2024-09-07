
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
global a_dx = 3
global a_dy = 3
global t_dx = 2
global t_dy = 2


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
alien = ImageFileActor("alien", [joinpath("examples", "images", "alien.png")])


# sound effects
eep_wav = joinpath(@__DIR__, "sounds", "283201-RubberBallBouncing7.wav")
cat_growl = joinpath(@__DIR__, "sounds", "39 Tom Cat Growling, Individual Grow.wav")
harp = joinpath(@__DIR__, "sounds", "harp-glissando-descending-short-103886.mp3")


label = TextActor(
    "this is some example text",
    "$(@__DIR__)/fonts/OpenSans-Regular.ttf",
    outline_size=1,
    pt_size=24
    )

    
#load a custom animation
anim_fns = ["$(@__DIR__)/images/FireElem1/Visible$i.png" for i in 0:7]
anim = ImageFileActor("fireelem", anim_fns)
anim.data[:next_frame] = true


# Start playing background music

play_music("$(@__DIR__)/examples/music/radetzky_ogg")

# The draw function is called by the framework. All we do here is draw the Actor
function draw(g::Game)
    draw(anim)
    draw(alien)
    draw(label)
end

function update(g::Game)
    global a_dx, a_dy, t_dx, t_dy, anim, wanim

    if Bool(window_paused[])
        nothing
    else
        alien.x += a_dx
        alien.y += a_dy
        
        label.x += t_dx
        label.y += t_dy

        if anim.data[:next_frame]
            if now() - anim.data[:then] > Millisecond(120)
                next_frame!(anim)
            end
        end
        
        if alien.x > SCREEN_WIDTH - alien.w || alien.x < 2
            a_dx = -a_dx
            rand(1:10) == 10 ? play_sound(eep_wav) : nothing
        end
        
        if alien.y > SCREEN_HEIGHT - alien.h || alien.y < 2
            a_dy = -a_dy
            rand(1:10) == 10 ? play_sound(eep_wav) : nothing
        end

        if label.x > SCREEN_WIDTH - label.w || label.x < 2
            t_dx = -t_dx
            rand(1:10) == 10 ? play_sound(eep_wav) : nothing
        end

        if label.y > SCREEN_HEIGHT - label.h || label.y < 2
            t_dy = -t_dy
            rand(1:10) == 10 ? play_sound(eep_wav) : nothing
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

