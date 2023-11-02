using Random
using Dates
using GameOne

# Width of the game window
SCREEN_WIDTH = [ 800, 400 ]
# Height of the game window
SCREEN_HEIGHT = [ 600, 300 ]
# Background color of the game window
BACKGROUND = [colorant"purple", colorant"blue"]
# Title of the game window
SCREEN_NAME = [ "Main", "Secondary" ]

# Globals to store the velocity of the actor
global dx = 2
global dy = 2


function next_frame!(a::Actor)
    a.textures = circshift(a.textures, -1)
    a.data[:then] = now()
    return a
end

# Create an `ImageActor` object from a PNG file
alien = ImageActor("images/alien.png", load("$(@__DIR__)/images/alien.png"))

# Create an `TextActor` object from an empty string for terminal use
terminal = TextActor(">", "$(@__DIR__)/fonts/OpenSans-Regular.ttf", outline_size=1, pt_size=35)
terminal.alpha = 0

#=
=#
label = TextActor(
    "this is some example text",
    "$(@__DIR__)/fonts/OpenSans-Regular.ttf",
    outline_size=1,
    pt_size=24)
label.x = 25
label.y = 25

#load a custom animation
anim_fns = ["$(@__DIR__)/images/FireElem1/Visible$i.png" for i in 0:7]
anim = ImageFileAnimActor("fe", anim_fns)
anim.data[:next_frame] = true
anim.y = 50
anim.x = 10


webp_fn = "Aura of Silence_001.webp"
wanim = WebpAnimActor(webp_fn, "$(@__DIR__)/images/$webp_fn")
wanim.data[:next_frame] = true
wanim.y = 100
wanim.x = 250


# Start playing background music

#play_music("examples/music/radetzky_ogg")

# The draw function is called by the framework. All we do here is draw the Actor
function draw(g::Game)
    draw(anim, g.screen[begin])
    draw(wanim, g.screen[begin])
    draw(alien, g.screen[begin])
    draw(label, g.screen[begin])
    draw(terminal, g.screen[begin])
end


# The update function is called every frame. Within the function, we
# * change the position of the actor by the velocity
# * if the actor hits the edges, we invert the velocity, and play a sound
# * if the up/down/left/right keys are pressed, we change the velocity to move the actor in the direction of the keypress

function update(g::Game)
    global dx, dy, anim, wanim
    alien.position.x += dx
    alien.position.y += dy

    if anim.data[:next_frame]
        if now() - anim.data[:then] > Millisecond(120)
            anim = next_frame!(anim)
        end
    end

    if wanim.data[:next_frame]
        if now() - wanim.data[:then] > Millisecond(120)
            wanim = next_frame!(wanim)
        end
    end

    #=
    =#

    if alien.x > 400 - alien.w || alien.x < 2
        dx = -dx
        play_sound("examples/sounds/eep.wav")
    end

    if alien.y > 400 - alien.h || alien.y < 2
        dy = -dy
        play_sound("examples/sounds/eep.wav")
    end

    #=
    if g.keyboard.DOWN
        dy = 2
    elseif g.keyboard.UP
        dy = -2
    elseif g.keyboard.LEFT
        dx = -2
    elseif g.keyboard.RIGHT
        dx = 2
    end
    =#
end

# If the "space" key is pressed, change the displayed image to the "hurt" variant.
# Also schedule an event to change it back to normal after one second.
# We define functions to change the image for the actor. These functions are called 
# from the keydown and scheduled events.


alien_hurt() = alien.image = "images/alien_hurt.png"
alien_normal() = alien.image = "images/alien.png"

#command_history = ["@show alien.label"]

function on_key_down(g, key, keymod)
    # start terminal and accept input text to be parsed and executed by
    if key == Keys.BACKQUOTE
        @info "Terminal Started!"
        terminal.alpha = 255
        draw(g)
        SDL_RenderPresent.([ s.renderer for s in g.screen ])
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


