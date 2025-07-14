module Example1

using GameOne
using Colors

const SCREEN_WIDTH = Int32(800)
const SCREEN_HEIGHT = Int32(600)
const SAMPLES = Int32(4)
const VSYNC = true

screen = create_screen("Example 1", SCREEN_WIDTH, SCREEN_HEIGHT, vsync=VSYNC, samples=SAMPLES, background=colorant"black")

# Load assets
alien_tex = load_texture(joinpath(@__DIR__, "images", "alien.png"))
#fire_frames = load_animated_textures(joinpath(@__DIR__, "images", "Camouflage_001.webp"))
eep_wav = joinpath(@__DIR__, "sounds", "283201-RubberBallBouncing7.wav")

# Actors (update to your new Actor/ImageActor system as needed)
alien = GameOne.ImageActor("alien", [alien_tex])
alien.x = SCREEN_WIDTH ÷ 2
alien.y = SCREEN_HEIGHT ÷ 2

#anim = SpriteAnimation(fire_frames, fill(0.12, length(fire_frames)))
#anim.x = SCREEN_WIDTH ÷ 3
#anim.y = SCREEN_HEIGHT ÷ 3

label = TextActor("this is some example text", joinpath(@__DIR__, "fonts", "OpenSans-Regular.ttf"), pt_size=24)
label.x = SCREEN_WIDTH ÷ 4
label.y = SCREEN_HEIGHT ÷ 4

const red_rect = Rect(SCREEN_WIDTH ÷ 2, SCREEN_HEIGHT ÷ 2, 100, 100)
const blue_rect = Rect(50, 50, 50, 50)

# ImGui callback (see above)

# Draw callback
function draw(g::Game)
    GameOne.draw(g.screen, alien)
    GameOne.draw(g.screen, label)
    #GameOne.draw(g.screen, anim)
    GameOne.draw(g.screen, red_rect, c=colorant"red")
    GameOne.draw(g.screen, blue_rect, c=colorant"blue")
end

# Update callback (use your existing logic, but remove SDL2 specifics)

# Game setup and run
function main()
    screen = create_screen("Main", SCREEN_WIDTH, SCREEN_HEIGHT, background=colorant"black")
    g = Game(
        screen,
        @__DIR__,
        @__MODULE__,
        KeyState(),
        MouseState(),
        0.0f0,
        0,
        0.0f0,
        draw,
        update,
        nothing, nothing, nothing, nothing,
        imgui,
        Dict{String,Any}(),
        Vector{Dict{String,Any}}(),
        Vector{TCPSocket}()
    )
    rungame(g)
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    Example1.main()
end