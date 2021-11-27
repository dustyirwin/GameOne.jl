using Images

# Height of the game window
HEIGHT = 400
# Width of the game window
WIDTH = 400
# Background color of the game window
BACKGROUND = colorant"purple"

# Globals to store the velocity of the actor
dx = 2
dy = 2


# Create an `ImageActor` object from a PNG file
a = ImageActor("examples/images/alien.png", load("examples/images/alien.png"))

# Create an `TextActor` object from an empty string for terminal use
tt = TextActor(">", "examples/fonts/OpenSans-Regular.ttf")

# Start playing background music
play_music("examples/music/radetzky_ogg")

# The draw function is called by the framework. All we do here is draw the Actor
function draw(g::Game)
    draw(a)
    draw(tt)
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

function on_key_down(g, key, keymod)
    if key == Keys.BACKQUOTE
        comp = start_terminal(g)
        #@show ex = Meta.parse(command)
        #@show res = @eval ex
        update_text_actor!(tt, comp)
    end
end

# We define functions to change the image for the actor. These functions are called from the keydown and scheduled events.
alien_hurt() = a.image = "images/alien_hurt.png"
alien_normal() = a.image = "images/alien.png"
