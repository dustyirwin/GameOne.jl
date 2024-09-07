using Printf

using CImGui
import CImGui.CSyntax: @c, @cstatic

# Load deps for the GLFW/OpenGL backend
import GLFW
import ModernGL

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
    
    @c CImGui.ShowDemoWindow(Ref{Bool}(true))

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
alien = ImageFileActor("alien1", [joinpath("examples", "images", "alien.png")])

# sound effects
eep_wav = joinpath(@__DIR__, "sounds", "283201-RubberBallBouncing7.wav")
cat_growl = joinpath(@__DIR__, "sounds", "39 Tom Cat Growling, Individual Grow.wav")
harp = joinpath(@__DIR__, "sounds", "harp-glissando-descending-short-103886.mp3")

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
    draw(anim, g.screen)
    draw(alien, g.screen)
    #draw(label, g.screen)
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

# Setup Dear ImGui context
CImGui.set_backend(:imgui_impl_sdl2)

function official_demo(; engine=nothing)
    ctx = CImGui.CreateContext()

    # Enable docking and multi-viewport
    io = CImGui.GetIO()
    io.ConfigFlags = unsafe_load(io.ConfigFlags) | CImGui.ImGuiConfigFlags_DockingEnable
    io.ConfigFlags = unsafe_load(io.ConfigFlags) | CImGui.ImGuiConfigFlags_ViewportsEnable

    # Setup Dear ImGui style
    CImGui.StyleColorsDark()
    # CImGui.StyleColorsClassic()
    # CImGui.StyleColorsLight()

    # Load fonts
    # - If no fonts are loaded, dear imgui will use the default font. You can also load multiple fonts and use `CImGui.PushFont/PopFont` to select them.
    # - `CImGui.AddFontFromFileTTF` will return the `Ptr{ImFont}` so you can store it if you need to select the font among multiple.
    # - If the file cannot be loaded, the function will return C_NULL. Please handle those errors in your application (e.g. use an assertion, or display an error and quit).
    # - The fonts will be rasterized at a given size (w/ oversampling) and stored into a texture when calling `CImGui.Build()`/`GetTexDataAsXXXX()``, which `ImGui_ImplXXXX_NewFrame` below will call.
    # - Read 'fonts/README.txt' for more instructions and details.
    fonts_dir = joinpath(@__DIR__, "..", "fonts")
    fonts = unsafe_load(CImGui.GetIO().Fonts)
    # default_font = CImGui.AddFontDefault(fonts)
    # CImGui.AddFontFromFileTTF(fonts, joinpath(fonts_dir, "Cousine-Regular.ttf"), 15)
    # CImGui.AddFontFromFileTTF(fonts, joinpath(fonts_dir, "DroidSans.ttf"), 16)
    # CImGui.AddFontFromFileTTF(fonts, joinpath(fonts_dir, "Karla-Regular.ttf"), 10)
    # CImGui.AddFontFromFileTTF(fonts, joinpath(fonts_dir, "ProggyTiny.ttf"), 10)
    CImGui.AddFontFromFileTTF(fonts, joinpath(fonts_dir, "Roboto-Medium.ttf"), 16)
    # @assert default_font != C_NULL

    show_demo_window = true
    show_another_window = false
    clear_color = Cfloat[0.45, 0.55, 0.60, 1.00]

    # for tests
    timeout = parse(Int, get(ENV, "AUTO_CLOSE_DEMO", "0"))
    timer = Timer(timeout)

    CImGui.render(ctx; window_title="Demo", clear_color=Ref(clear_color), engine) do
        # show the big demo window
        show_demo_window && @c CImGui.ShowDemoWindow(&show_demo_window)

        # show a simple window that we create ourselves.
        # we use a Begin/End pair to created a named window.
        @cstatic f=Cfloat(0.0) counter=Cint(0) begin
            CImGui.Begin("Hello, world!")  # create a window called "Hello, world!" and append into it.
            CImGui.Text("This is some useful text.")  # display some text
            @c CImGui.Checkbox("Demo Window", &show_demo_window)  # edit bools storing our window open/close state
            @c CImGui.Checkbox("Another Window", &show_another_window)

            @c CImGui.SliderFloat("float", &f, 0, 1)  # edit 1 float using a slider from 0 to 1
            CImGui.ColorEdit3("clear color", clear_color)  # edit 3 floats representing a color
            CImGui.Button("Button") && (counter += 1)

            CImGui.SameLine()
            CImGui.Text("counter = $counter")
            CImGui.Text(@sprintf("Application average %.3f ms/frame (%.1f FPS)", 1000 / unsafe_load(CImGui.GetIO().Framerate), unsafe_load(CImGui.GetIO().Framerate)))

            CImGui.End()
        end

        # show another simple window.
        if show_another_window
            @c CImGui.Begin("Another Window", &show_another_window)  # pass a pointer to our bool variable (the window will have a closing button that will clear the bool when clicked)
            CImGui.Text("Hello from another window!")
            CImGui.Button("Close Me") && (show_another_window = false;)
            CImGui.End()
        end

        if haskey(ENV, "AUTO_CLOSE_DEMO") && !isopen(timer)
            return :imgui_exit_loop
        end

        # Yield for the timer
        yield()
    end
end

# Run automatically if the script is launched from the command-line
if !isempty(Base.PROGRAM_FILE)
    official_demo()
end
