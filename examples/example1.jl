using Random
using Dates

# Height of the game window
HEIGHT = 600
# Width of the game window
WIDTH = 800
# Background color of the game window
BACKGROUND = colorant"purple"

# Globals to store the velocity of the actor
dx = 2
dy = 2


function next_frame!(a::Actor)
    a.textures = circshift(a.textures, -1)
    a.data[:then] = now()
    return a
end

# Create an `ImageActor` object from a PNG file
alien = ImageActor("examples/images/alien.png", load("examples/images/alien.png") )

# Create an `TextActor` object from an empty string for terminal use
terminal = TextActor(">", "examples/fonts/OpenSans-Regular.ttf")
terminal.alpha = 0

label = TextActor(
    "this is some example text",
    "examples/fonts/OpenSans-Regular.ttf",
    outline_size=1,
    pt_size=24)
label.position.x = 25
label.position.y = 25


#load a custom animation
anim_fns = [ "C:/Users/dusty/My Drive/PlaymatProjects/PlaymatAssets/MtG/unprocessed_gifs/FEBMP/Visible$i.bmp" for i in 0:7 ]
anim = AnimActorBMP("alien_anim", anim_fns)
anim.data[:next_frame] = true
anim.y = 50
anim.x = 10

# Start playing background music

#play_music("examples/music/radetzky_ogg")

# The draw function is called by the framework. All we do here is draw the Actor
function draw(g::Game)
    draw.([
        alien, 
        terminal, 
        label, 
        anim,
        ])
end


# The update function is called every frame. Within the function, we
# * change the position of the actor by the velocity
# * if the actor hits the edges, we invert the velocity, and play a sound
# * if the up/down/left/right keys are pressed, we change the velocity to move the actor in the direction of the keypress

function update(g::Game)
    global dx, dy, anim
    alien.position.x += dx
    alien.position.y += dy

    if anim.data[:next_frame]
        if now() - anim.data[:then] > Millisecond(120) 
            anim = next_frame!(anim)
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


alien_hurt() = alien.image = "images/alien_hurt.png"
alien_normal() = alien.image = "images/alien.png"

command_history = ["@show alien.label"]

function on_key_down(g, key, keymod)
    # start terminal and accept input text to be parsed and executed by
    if key == Keys.BACKQUOTE
        @info "Terminal Started!"
        terminal.alpha = 255
        draw(g); SDL2.RenderPresent(g.screen.renderer)
        update_text_actor!(terminal, ">")
        text = start_text_input(g, terminal, command_history)
        terminal.alpha = 150
        update_text_actor!(terminal, "evaluating: $text...")

        # evaluate entered text
        try
            io = IOBuffer()
            ex = Meta.parse(text)
            show(IOContext(io, :limit => true, :displaysize => (100, 150)), "text/plain", eval(g.game_module, ex))
            s = String(take!(io))
            update_text_actor!(terminal, s)
            push!(command_history, text)
        catch e
            @warn e
        end
        
        schedule_once(() -> terminal.alpha = 0, 4)
        #=
        =#
    end
end


