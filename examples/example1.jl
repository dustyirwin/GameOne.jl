__precompile__(false)

module Example1

using GameOne

TTF_Init() # Initialize SDL_ttf
Mix_Init(MIX_INIT_MP3) # Initialize SDL_mixer

# window dimensions
const SCREEN_WIDTH = 800
const SCREEN_HEIGHT = 600
const SCREEN_BACKGROUND = colorant"black"
const SCREEN_NAME = "Main"

function imgui(g::Game)
    try
        CImGui.SetNextWindowPos(ImVec2(10, 10), CImGui.ImGuiCond_FirstUseEver)
        CImGui.SetNextWindowSize(ImVec2(300, 250), CImGui.ImGuiCond_FirstUseEver)
        
        if CImGui.Begin("Debug Window")
            CImGui.Text("🖥️ Screen Controls")
            
            # Add quit button
            if CImGui.Button("Quit Game")
                window_paused[] = 1
                playing[] = false
            end
            
            CImGui.SameLine()
            if CImGui.Button("Play Sound")
                play_sound(eep_wav)
            end
            
            @cstatic slider_val=0.5f0 begin
                if CImGui.SliderFloat("Slider", Ref(slider_val), 0.0f0, 1.0f0)
                    g.imgui_settings["slider"] = slider_val
                end
            end
            
            # Show actor positions in ImGui
            CImGui.Separator()
            CImGui.Text("Actor Positions:")
            CImGui.Text("Alien: ($(Int(alien.x)), $(Int(alien.y)))")
            CImGui.Text("Label: ($(Int(label.x)), $(Int(label.y)))")
            CImGui.Text("FireElem: ($(Int(anim.x)), $(Int(anim.y)))")
            CImGui.Text("Red Rect: ($(red_rect.x), $(red_rect.y))")
            CImGui.Text("Blue Rect: ($(blue_rect.x), $(blue_rect.y))")
        end
        CImGui.End()
        
    catch e
        @warn "ImGui error: $e"
    end
end

# Create actors
alien_image_path = joinpath(@__DIR__,"images", "alien.png")
alien = ImageFileActor("alien", [alien_image_path])
alien.x = SCREEN_WIDTH ÷ 2
alien.y = SCREEN_HEIGHT ÷ 2

eep_wav = joinpath(@__DIR__, "sounds", "283201-RubberBallBouncing7.wav")

label = TextActor(
    "this is some example text",
    joinpath(@__DIR__,"fonts","OpenSans-Regular.ttf"),
    outline_size=1,
    pt_size=24
)
label.x = SCREEN_WIDTH ÷ 4
label.y = SCREEN_HEIGHT ÷ 4

anim_fns = [joinpath(@__DIR__,"images","FireElem1","Visible$i.png") for i in 0:7]
anim = ImageFileActor("fireelem", anim_fns, anim=true)
anim.x = SCREEN_WIDTH ÷ 3
anim.y = SCREEN_HEIGHT ÷ 3

# Create rectangles
const red_rect = Rect(SCREEN_WIDTH ÷ 2, SCREEN_HEIGHT ÷ 2, 100, 100)
const blue_rect = Rect(50, 50, 50, 50)

# Initialize velocities for all actors
global dx_alien = 2
global dy_alien = 2
global dx_label = 2
global dy_label = 2
global dx_anim = 2
global dy_anim = 2
global dx_red = 3
global dy_red = 3
global dx_blue = 4
global dy_blue = 4

function draw(g::Game)    
    GameOne.draw(g.screen, alien)
    GameOne.draw(g.screen, label)
    GameOne.draw(g.screen, anim)
    
    # Add rectangles back
    GameOne.draw(g.screen, red_rect, c=colorant"red")
    GameOne.draw(g.screen, blue_rect, c=colorant"blue")
end

function update(g::Game)
    global dx_alien, dy_alien, dx_label, dy_label, dx_anim, dy_anim
    global dx_red, dy_red, dx_blue, dy_blue
    
    if Bool(window_paused[])
        return
    end

    # Update positions for all actors
    alien.x += dx_alien
    alien.y += dy_alien
    label.x += dx_label
    label.y += dy_label
    anim.x += dx_anim
    anim.y += dy_anim
    
    # Update rectangle positions
    red_rect.x += dx_red
    red_rect.y += dy_red
    blue_rect.x += dx_blue
    blue_rect.y += dy_blue

    # Handle FireElem animation
    if now() - anim.data[:then] > Millisecond(120)
        next_frame!(anim)
    end

    # ALIEN BOUNCING - Both horizontal AND vertical with 2px margin
    if alien.x > SCREEN_WIDTH - alien.w - 2 || alien.x < 2
        dx_alien = -dx_alien
        play_sound(eep_wav)
    end
    if alien.y > SCREEN_HEIGHT - alien.h - 2 || alien.y < 2
        dy_alien = -dy_alien
        play_sound(eep_wav)
    end

    # LABEL BOUNCING - Both horizontal AND vertical with 2px margin
    if label.x > SCREEN_WIDTH - label.w - 2 || label.x < 2
        dx_label = -dx_label
        play_sound(eep_wav)
    end
    if label.y > SCREEN_HEIGHT - label.h - 2 || label.y < 2
        dy_label = -dy_label
        play_sound(eep_wav)
    end

    # ANIM BOUNCING - Both horizontal AND vertical with 2px margin
    if anim.x > SCREEN_WIDTH - anim.w - 2 || anim.x < 2
        dx_anim = -dx_anim
        play_sound(eep_wav)
    end
    if anim.y > SCREEN_HEIGHT - anim.h - 2 || anim.y < 2
        dy_anim = -dy_anim
        play_sound(eep_wav)
    end

    # RED RECTANGLE BOUNCING - Both horizontal AND vertical with 2px margin
    if red_rect.x > SCREEN_WIDTH - red_rect.w - 2 || red_rect.x < 2
        dx_red = -dx_red
        play_sound(eep_wav)
    end
    if red_rect.y > SCREEN_HEIGHT - red_rect.h - 2 || red_rect.y < 2
        dy_red = -dy_red
        play_sound(eep_wav)
    end

    # BLUE RECTANGLE BOUNCING - Both horizontal AND vertical with 2px margin
    if blue_rect.x > SCREEN_WIDTH - blue_rect.w - 2 || blue_rect.x < 2
        dx_blue = -dx_blue
        play_sound(eep_wav)
    end
    if blue_rect.y > SCREEN_HEIGHT - blue_rect.h - 2 || blue_rect.y < 2
        dy_blue = -dy_blue
        play_sound(eep_wav)
    end

    # Handle keyboard input for alien movement
    if g.keyboard.DOWN
        dy_alien = abs(dy_alien)   # Move down
    elseif g.keyboard.UP
        dy_alien = -abs(dy_alien)  # Move up
    elseif g.keyboard.LEFT
        dx_alien = -abs(dx_alien)  # Move left
    elseif g.keyboard.RIGHT
        dx_alien = abs(dx_alien)   # Move right
    end
end

atexit(TTF_Quit)

end # module Example1

using GameOne

if abspath(PROGRAM_FILE) == @__FILE__
  rungame("ex1", false, game_mods=Dict("ex1" => Example1))
end