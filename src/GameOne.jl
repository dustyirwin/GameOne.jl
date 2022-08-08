module GameOne

using Dates
using Colors
using Random
using Reexport
using SimpleDirectMediaLayer

@reexport using Images
@reexport using ShiftedArrays

const SDL2 = SimpleDirectMediaLayer

export game, draw, scheduler, schedule_once, schedule_interval, schedule_unique, unschedule,
    collide, angle, distance, play_music, play_sound, line, clear, rungame, game_include,
    getEventType, getTextInputEventChar, start_text_input, update_text_actor!
export Game, Keys, Keymods, MouseButtons
export ImageActor, TextActor, GIFActor, Actor, Line, Rect, Circle
export SDL2


include("keyboard.jl")
include("timer.jl")
include("window.jl")
include("event.jl")
include("resources.jl")
include("screen.jl")
include("actor.jl")


#Magic variables
const HEIGHTSYMBOL = :SCREEN_HEIGHT
const WIDTHSYMBOL = :SCREEN_WIDTH
const BACKSYMBOL = :BACKGROUND

mutable struct Game
    screen::Screen
    location::String
    game_module::Module
    keyboard::Keyboard
    render_function::Function
    update_function::Function
    onkey_function::Function
    onmousedown_function::Function
    onmouseup_function::Function
    onmousemove_function::Function
    Game() = new()
end


# const EVENT_HANDLER_FN = Dict(
#     MOUSEBUTTONDOWN => "on_mouse_down",
#     MOUSEBUTTONUP => "on_mouse_up",
#     MOUSEMOTION => "on_mouse_move",
#     KEYDOWN => "on_key_down",
#     KEYUP => "on_key_up",
#     MUSIC_END => "on_music_end"
# )


const timer = WallTimer()
const game = Ref{Game}()
const playing = Ref{Bool}(false)
const paused = Ref{Bool}(false)

function __init__() end

function initscreen(gm::Module, name::String)
    h = getifdefined(gm, HEIGHTSYMBOL, 400)
    w = getifdefined(gm, WIDTHSYMBOL, 600)
    color = getifdefined(gm, BACKSYMBOL, ARGB(colorant"white"))
    s = Screen(name, w, h, color)
    clear(s)
    return s
end


getifdefined(m, s, v) = isdefined(m, s) ? getfield(m, s) : v

mainloop(g::Ref{Game}) = mainloop(g[])

function mainloop(g::Game)
    start!(timer)

    while (true)
        #Don't run if game is paused by system (resizing, lost focus, etc)
        while window_paused[] != 0
            _ = pollEvent!()
            sleep(0.25)
        end

        # Handle Events
        errorMsg = ""

        try
            hadEvents = true
            e_time = 0
            while hadEvents
                e, hadEvents = pollEvent!()
                t = getEventType(e)
                handleEvents!(g, e, t)
            end
        catch e
            rethrow()
        end

        #if (debug && debugText) renderFPS(renderer,last_10_frame_times) end
        SDL2.RenderClear(g.screen.renderer)
        Base.invokelatest(g.render_function, g)
        SDL2.RenderPresent(g.screen.renderer)

        dt = elapsed(timer)
        # Don't let the game proceed at fewer than this frames per second. If an
        # update takes too long, allow the game to actually slow, rather than
        # having too big of frames.
        min_fps = 30.0
        max_fps = 60.0
        dt = min(dt / 1e9, 1.0 / min_fps)
        start!(timer)
        Base.invokelatest(g.update_function, g, dt)
        tick!(scheduler[])
        if (playing[] == false)
            throw(QuitException())
        end
    end
end

function handleEvents!(g::Game, e, t)
    global playing, paused

    if (t == SDL2.KEYDOWN || t == SDL2.KEYUP)
        handleKeyPress(g::Game, e, t)
    elseif (t == SDL2.MOUSEBUTTONUP || t == SDL2.MOUSEBUTTONDOWN)
        handleMouseClick(g::Game, e, t)
        #TODO elseif (t == SDL2.MOUSEWHEEL); handleMouseScroll(e)
    elseif (t == SDL2.MOUSEMOTION)
        handleMousePan(g::Game, e, t)
    elseif (t == SDL2.QUIT)
        paused[] = playing[] = false
    end
end

function handleKeyPress(g::Game, e, t)
    keySym = getKeySym(e)
    keyMod = getKeyMod(e)
    @debug "Keyboard" keySym, keyMod
    if (t == SDL2.KEYDOWN)
        push!(g.keyboard, keySym)
        
        # TODO: clean up keyboard errors... experiencing Argument Error: Invalid value for enum key: 1073741593 (audio volume up key)... and other un-mapped keys
        try 
            Base.invokelatest(g.onkey_function, g, Keys.Key(keySym), Keymods.Keymod(keyMod))
        catch err
            @error "ERROR: $err"
        end
    
    elseif (t == SDL2.KEYUP)
        delete!(g.keyboard, keySym)
    end
    #keyRepeat = (getKeyRepeat(e) != 0)
end

function handleMouseClick(g::Game, e, t)
    button = getMouseButtonClick(e)
    x = getMouseClickX(e)
    y = getMouseClickY(e)
    @debug "Mouse Button" button, x, y
    if (t == SDL2.MOUSEBUTTONUP)
        Base.invokelatest(g.onmouseup_function, g, (x, y), MouseButtons.MouseButton(button))
    elseif (t == SDL2.MOUSEBUTTONDOWN)
        Base.invokelatest(g.onmousedown_function, g, (x, y), MouseButtons.MouseButton(button))
    end
end

function handleMousePan(g::Game, e, t)
    x = getMouseMoveX(e)
    y = getMouseMoveY(e)
    @debug "Mouse Move" x, y
    Base.invokelatest(g.onmousemove_function, g, (x, y))
end

getKeySym(e) = bitcat(UInt32, e[24:-1:21])
getKeyRepeat(e) = bitcat(UInt8, e[14:-1:14])
getKeyMod(e) = bitcat(UInt16, e[26:-1:25])

getMouseButtonClick(e) = bitcat(UInt8, e[17:-1:17])
getMouseClickX(e) = bitcat(Int32, e[23:-1:20])
getMouseClickY(e) = bitcat(Int32, e[27:-1:24])

getMouseMoveX(e) = bitcat(Int32, e[24:-1:21])
getMouseMoveY(e) = bitcat(Int32, e[28:-1:25])

function rungame(jlf::String)
    global playing, paused
    g = initgame(jlf::String)
    try
        playing[] = paused[] = true
        mainloop(g)
    catch e
        if !isa(e, QuitException) && !isa(e, InterruptException)
            @error e exception = (e, catch_backtrace())
        end
    finally
        GameOne.quitSDL(game[])
    end
end

function initgame(jlf::String)
    if !isfile(jlf)
        ArgumentError("File not found: $jlf")
    end
    name = titlecase(replace(basename(jlf), ".jl" => ""))
    module_name = Symbol(name * "_" * randstring(5))
    game_module = Module(module_name)
    @debug "Initialised Anonymous Game Module" module_name
    initSDL()
    game[] = Game()
    scheduler[] = Scheduler()
    g = game[]
    g.game_module = game_module
    g.location = dirname(jlf)
    g.keyboard = Keyboard()

    Base.include_string(game_module, "using GameOne")
    Base.include_string(game_module, "import GameOne.draw")
    Base.include_string(game_module, "using Colors")
    Base.include(game_module, jlf)

    g.update_function = getfn(game_module, :update, 2)
    g.render_function = getfn(game_module, :draw, 1)
    g.onkey_function = getfn(game_module, :on_key_down, 4)
    g.onmouseup_function = getfn(game_module, :on_mouse_up, 3)
    g.onmousedown_function = getfn(game_module, :on_mouse_down, 3)
    g.onmousemove_function = getfn(game_module, :on_mouse_move, 2)
    g.screen = initscreen(game_module, "GameOne::" * name)
    clear(g.screen)
    return g
end

game_include(jlf::String) = Base.include(game[].game_module, jlf)

function getfn(m::Module, s::Symbol, maxargs = 3)
    if isdefined(m, s)
        fn = getfield(m, s)

        ms = copy(methods(fn).ms)
        filter!(x -> x.module == m, ms)
        if length(ms) > 1
            sort!(ms, by = x -> x.nargs, rev = true)
        end
        m = ms[1]
        if (m.nargs - 1) > maxargs
            error("Found a $s function with $(m.nargs-1) arguments. A maximum of $maxargs arguments are allowed.")
        end
        @debug "Event method" fn m.nargs
        #TODO Validate types for arguments
        if m.nargs - 1 == maxargs #required to handle the zero-arg case
            return fn
        end
        return (x...) -> fn(x[1:(m.nargs-1)]...)
    else
        return (x...) -> nothing
    end
end

function start_text_input(g::Game, terminal::Actor, history=String[])
    done = false
    comp = terminal.label

    SDL2.StartTextInput()

    while !done
        event, success = GameOne.pollEvent!()

        if success
            event_array = [Char(i) for i in event]
            
            event_type = getEventType(event)
            #@info event_type
            
            key_sym = event_array[21] |> string
            #@info key_sym
            
            #SDL2.GetModState() |> string
        
            if getEventType(event) == SDL2.TEXTINPUT
                char = getTextInputEventChar(event)
                comp *= char
                comp = comp == ">`" ? ">" : comp
            
                update_text_actor!(terminal, comp)
            
                #@info "TextInputEvent: $(getEventType(event)) comp: $comp"
            
            # Paste from clipboard
            # KEYMODs: LCTRL = 4160 | RCTRL = 4096
            elseif event_type == SDL2.KEYDOWN && (SDL2.GetModState() |> string == "4160" || SDL2.GetModState() |> string == "4096") && (key_sym == "v" || key_sym == "V")
                comp = comp * "$(unsafe_string(SDL2.GetClipboardText()))"
                update_text_actor!(terminal, comp)
            
            
            elseif length(comp) > 1 && event_type == SDL2.KEYDOWN && key_sym == "\b"  # backspace key
                comp = comp[1:end-1]
                update_text_actor!(terminal, comp)
            
                #@info "BackspaceEvent: $(getEventType(event)) comp: $comp"
            
            elseif string(event_type) == "0x00000300" && key_sym == "R"
                update_text_actor!(terminal, history[end])

            elseif getEventType(event) == SDL2.KEYDOWN && key_sym == "\r" # return key
                @info "QuitEvent: $(getEventType(event))"
                @info "Composition: $comp"
                done = true
            end
        
            # Update screen
            SDL2.RenderClear(g.screen.renderer)
            draw(g)
            SDL2.RenderPresent(g.screen.renderer)
        end
    end

    SDL2.StopTextInput()
    terminal.label = comp[2:end]
end


# H ving a QuitException is useful for testing, since an exception will simply
# pause the interpreter. For release builds, the catch() block will call quitSDL().
struct QuitException <: Exception end

function getSDLError()
    x = SDL2.GetError()
    return unsafe_string(x)
end

function initSDL()
    SDL2.GL_SetAttribute(SDL2.GL_MULTISAMPLEBUFFERS, 4)
    SDL2.GL_SetAttribute(SDL2.GL_MULTISAMPLESAMPLES, 4)
    r = SDL2.Init(UInt32(SDL2.INIT_VIDEO | SDL2.INIT_AUDIO))
    if r != 0
        error("Unable to initialise SDL: $(getSDLError())")
    end
    SDL2.TTF_Init()

    mix_init_flags = SDL2.MIX_INIT_FLAC | SDL2.MIX_INIT_MP3 | SDL2.MIX_INIT_OGG
    inited = SDL2.Mix_Init(Int32(mix_init_flags))
    if inited & mix_init_flags != mix_init_flags
        @warn "Failed to initialise audio mixer properly. Sounds may not play correctly\n$(getSDLError())"
    end

    device = SDL2.Mix_OpenAudio(Int32(22050), UInt16(SDL2.AUDIO_S16SYS), Int32(2), Int32(1024))
    if device != 0
        @warn "No audio device available, sounds and music will not play.\n$(getSDLError())"
        SDL2.Mix_CloseAudio()
    end
end

function quitSDL(g::Game)
    # Need to close the callback before quitting SDL to prevent it from hanging
    # https://github.com/n0name/2D_Engine/issues/3
    @debug "Quitting the game"
    clear!(scheduler[])
    SDL2.DelEventWatch(window_event_watcher_cfunc[], g.screen.window)
    SDL2.DestroyRenderer(g.screen.renderer)
    SDL2.DestroyWindow(g.screen.window)
    #Run all finalisers
    GC.gc()
    GC.gc()
    quitSDL()
end

function quitSDL()
    SDL2.Mix_HaltMusic()
    SDL2.Mix_HaltChannel(Int32(-1))
    SDL2.Mix_CloseAudio()
    SDL2.TTF_Quit()
    SDL2.Mix_Quit()
    SDL2.Quit()
end

function main()
    if length(ARGS) < 1
        throw(ArgumentError("No file to run"))
    end
    jlf = ARGS[1]
    rungame(jlf)
end

end # module
