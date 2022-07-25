
# Height of the game window
HEIGHT = 400
# Width of the game window
WIDTH = 400
# Background color of the game window
BACKGROUND = colorant"purple"

# Globals to store the velocity of the actor
dx = 1
dy = 1


# Create an `ImageActor` object from a PNG file
a = ImageActor("examples/images/alien.png", load("examples/images/alien.png"))

# Create an `TextActor` object from an empty string for terminal use
terminal = TextActor(">", "examples/fonts/OpenSans-Regular.ttf")
terminal.alpha = 0

label = TextActor("this is some example text", "examples/fonts/OpenSans-Regular.ttf")
label.position.x = 50
label.position.y = 50

# Start playing background music
play_music("examples/music/radetzky_ogg")

# The draw function is called by the framework. All we do here is draw the Actor
function draw(g::Game)
    draw.([a, terminal])
    draw(label)
end

 
# The update function is called every frame. Within the function, we
# * change the position of the actor by the velocity
# * if the actor hits the edges, we invert the velocity, and play a sound
# * if the up/down/left/right keys are pressed, we change the velocity to move the actor in the direction of the keypress

function update(g::Game)
    global dx, dy
    a.position.x += dx
    a.position.y += dy

    if a.x > 400 - a.w || a.x < 2
        dx = -dx
        play_sound("examples/sounds/eep.wav")
    end

    if a.y > 400 - a.h || a.y < 2
        dy = -dy
        play_sound("examples/sounds/eep.wav")
    end

    if g.keyboard.DOWN
        dy = 2
    elseif g.keyboard.UP
        dy = -2
    elseif g.keyboard.LEFT
        dx = -2
    elseif g.keyboard.RIGHT
        dx = 2
    end
end

# If the "space" key is pressed, change the displayed image to the "hurt" variant.
# Also schedule an event to change it back to normal after one second.
# We define functions to change the image for the actor. These functions are called 
# from the keydown and scheduled events.


alien_hurt() = a.image = "images/alien_hurt.png"
alien_normal() = a.image = "images/alien.png"


function on_key_down(g, key, keymod)
    # start terminal and accept input text to be parsed and executed by
    if key == Keys.BACKQUOTE
        terminal.alpha = 255
        update_text_actor!(terminal, ">")
        draw(g)
        SDL2.RenderPresent(g.screen.renderer)
        text = start_text_input(g, terminal)
        terminal.alpha = 150
        update_text_actor!(terminal, "evaluating: $text...")

        # evaluate entered text
        try
            io = IOBuffer()
            ex = Meta.parse(text)
            show(IOContext(io, :limit=>true, :displaysize=>(100,20)), "text/plain", eval(g.game_module, ex))
            s = String(take!(io))
            update_text_actor!(terminal, s)
        catch e
            @warn e
        end

        schedule_once(() -> terminal.alpha = 0, 4)
    end
end


