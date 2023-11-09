module GameOne

import Reexport: @reexport

@reexport import Base.Threads: @threads, Atomic, SpinLock
@reexport import Colors: FixedPointNumbers, @colorant_str, ARGB, Colorant, red, green, blue, alpha
@reexport import Dates: now, Millisecond
@reexport import Random: rand, randstring, shuffle, shuffle!
@reexport using ShiftedArrays: circshift
@reexport import libwebp_jll: webpmux, dwebp
@reexport import DataStructures: OrderedDict

@reexport using SimpleDirectMediaLayer.LibSDL2

import SimpleDirectMediaLayer
const SDL2 = SimpleDirectMediaLayer.LibSDL2

export game, draw, scheduler, schedule_once, schedule_interval, schedule_unique, unschedule,
    collide, angle, distance, play_music, play_sound, line, clear, rungame, game_include,
    getEventType, getTextInputEventChar, start_text_input, update_text_actor!, sdl_colors, quitSDL
export Game, Keys, KeyMods, MouseButton
export Actor, ImagesActor, TextActor, WebpAnimActor
export Line, Rect, Triangle, Circle


include("keyboard.jl")
include("timer.jl")
include("event.jl")
include("window.jl")
include("resources.jl")
include("screen.jl")
include("actor.jl")


# Magic variables to check for in the game module
const HEIGHTSYMBOL = :SCREEN_HEIGHT
const WIDTHSYMBOL = :SCREEN_WIDTH
const SCREENSYMBOL = :SCREEN_NAME
const BACKSYMBOL = :BACKGROUND

mutable struct Game
    screen::Vector{Screen}
    screen_names::Vector{String}
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

const timer = WallTimer()
const game = Ref{Game}()
const playing = Ref{Bool}(false)
const paused = Ref{Bool}(false)

#function __init__() end

function initscreen(gm::Module, name::String, screen_num::Int=1)
    h = getifdefined(gm, HEIGHTSYMBOL, repeat([600], screen_num))[screen_num]
    w = getifdefined(gm, WIDTHSYMBOL, repeat([800], screen_num))[screen_num]
    background = getifdefined(gm, BACKSYMBOL, repeat([ARGB(colorant"black")],screen_num))[screen_num]
    if !(background isa Colorant)
        background = image_surface(background[screen_num])
    end
    s = Screen(name, w, h, background)
    clear(s)
    return s
end

getifdefined(m, s, v) = isdefined(m, s) ? getfield(m, s) : v

game_include(jlf::String) = Base.include(game[].game_module, jlf)

mainloop(g::Ref{Game}) = mainloop(g[])

pollEvent = let event = Ref{SDL_Event}()
    () -> SDL_PollEvent(event)
end

function mainloop(g::Game)
    start!(timer)

    while (true)
        #Don't run if game is paused by system (resizing, lost focus, etc)
        while window_paused[] != 0
            _ = pollEvent()
            sleep(0.5)
        end

        # Handle Events
        errorMsg = ""

        try
            event_ref = Ref{SDL_Event}()
            
            while Bool(SDL_PollEvent(event_ref))
                e = event_ref[]
                t = e.type
                handleEvents!(g, e, t)
            end
        catch e
            rethrow()
        end

        clear.(g.screen)
        Base.invokelatest(g.render_function, g)

        for s in g.screen
            SDL_RenderPresent(s.renderer)
        end

        dt = elapsed(timer)
        # Don't let the game proceed at fewer than this frames per second. If an
        # update takes too long, allow the game to actually slow, rather than
        # having too big of frames.
        min_fps = 20.0
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

    if (t == SDL_KEYDOWN || t == SDL_KEYUP)
        handleKeyPress(g::Game, e.key, t)
    
    elseif (t == SDL_MOUSEBUTTONUP || t == SDL_MOUSEBUTTONDOWN)
        handleMouseClick(g::Game, e.button, t)
        #TODO elseif (t == MOUSEWHEEL); handleMouseScroll(e)
    
    elseif (t == SDL_MOUSEMOTION)
        handleMousePan(g::Game, e.motion, t)

    elseif (t == SDL_WINDOWEVENT)
        handleWindowEvent(g::Game, e, t)
    
    elseif (t == SDL_QUIT)
        paused[] = playing[] = false
    end
end

function handleKeyPress(g::Game, e, t)
    keySym = e.keysym.sym
    keyMod = e.keysym.mod
    @info "Keyboard" keySym, keyMod
    if (t == SDL_KEYDOWN)
        push!(g.keyboard, keySym)
        Base.invokelatest(g.onkey_function, g, keySym, keyMod)
        
    elseif (t == SDL_KEYUP)
        delete!(g.keyboard, keySym)
    end

    #keyRepeat = (getKeyRepeat(e) != 0)
end

function handleMouseClick(g::Game, e, t)
    @debug "Mouse Button" button, x, y
    if (t == SDL_MOUSEBUTTONUP)
        Base.invokelatest(g.onmouseup_function, g, (e.x, e.y), MouseButtons.MouseButton(e.button))
    elseif (t == SDL_MOUSEBUTTONDOWN)
        Base.invokelatest(g.onmousedown_function, g, (e.x, e.y), MouseButtons.MouseButton(e.button))
    end
end

function handleMousePan(g::Game, e, t)
    @debug "Mouse Move" e.x, e.y
    Base.invokelatest(g.onmousemove_function, g, (e.x, e.y))
end

function handleWindowEvent(g::Game, e, t)
    # manage window focus
    for s in g.screen
        if (s.window_id == e.window.windowID) && !s.has_focus
            s.has_focus = true
            @info "Window $(e.window.windowID) gained focus"

        elseif s.has_focus
            s.has_focus = false
            @info "Window $(e.window.windowID) lost focus"

        end
    end
end

getKeySym(e) = bitcat(UInt32, e[24:-1:21])
getKeyRepeat(e) = bitcat(UInt8, e[14:-1:14])
getKeyMod(e) = bitcat(UInt16, e[26:-1:25])

getMouseButtonClick(e) = bitcat(UInt8, e[17:-1:17])
getMouseClickX(e) = bitcat(Int32, e[23:-1:20])
getMouseClickY(e) = bitcat(Int32, e[27:-1:24])

getMouseMoveX(e) = bitcat(Int32, e[24:-1:21])
getMouseMoveY(e) = bitcat(Int32, e[28:-1:25])


"""
    `rungame(game_file::String)`
    `rungame()`

    The entry point to GameOne. This is the user-facing function that is used to start a game. 
    The single argument method should be used from the REPL or main script. It takes the game source
    file as it's only argument. 

    The zero argument method should be used from the game source file itself when is being executed directly
"""
function rungame(jlf::String, external::Bool=true)
    # The optional argument `external` is used to determine whether the zero or single argument version 
    # has been called. End users should never have to use this argument directly. 
    # external=true means rungame has been called from the REPl or run script, with the game file as input
    # external=false means rungame has been called at the bottom of the game file itself
    global playing, paused
    g = initgame(jlf::String, external)
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

function rungame()
    rungame(abspath(PROGRAM_FILE), false)
end

function initgame(jlf::String, external::Bool)
    if !isfile(jlf)
        ArgumentError("File not found: $jlf")
    end
    name = titlecase(replace(basename(jlf), ".jl" => ""))
    initSDL()
    game[] = Game()
    scheduler[] = Scheduler()
    g = game[]
    g.keyboard = Keyboard()
    if external
        module_name = Symbol(name * "_" * randstring(5))
        game_module = Module(module_name)
        @debug "Initialised Anonymous Game Module" module_name
        g.game_module = game_module
        g.location = dirname(jlf)
    else
        g.game_module = Main
        g.location = pwd()
    end

    if external
        Base.include_string(g.game_module, "using GameOne")
        Base.include_string(g.game_module, "import GameOne.draw")
        Base.include_string(g.game_module, "using Colors")
        Base.include(g.game_module, jlf)
    end

    g.screen_names = getifdefined(g.game_module, :SCREEN_NAME, ["Main", "Secondary"])
    g.update_function = getfn(g.game_module, :update, 2)
    g.render_function = getfn(g.game_module, :draw, 3)
    g.onkey_function = getfn(g.game_module, :on_key_down, 3)
    g.onmouseup_function = getfn(g.game_module, :on_mouse_up, 3)
    g.onmousedown_function = getfn(g.game_module, :on_mouse_down, 3)
    g.onmousemove_function = getfn(g.game_module, :on_mouse_move, 2)
    g.screen = [ initscreen(g.game_module, name, i) for (i,name) in enumerate(g.screen_names) ]
    clear.(g.screen)
    return g
end


function getfn(m::Module, s::Symbol, maxargs = 3)
    @debug "grabbing function $s in module $m"
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

function start_text_input(g::Game, terminal::Actor)
    done = false
    comp = terminal.label
    SDL_StartTextInput()

    while !done
        event, success = pollEvent!()

        if success
            event_array = UInt8.([Char(i) for i in event])

            event_type = getEventType(event_array)
            @info "event type: $event_type"

            key_sym = event_array[21]
            @info "key sym: $key_sym"

            #SDL_GetModState() |> string

            if getEventType(event) == SDL_TEXTINPUT
                char = getTextInputEventChar(event)
                comp *= char
                comp = comp == ">`" ? ">" : comp

                update_text_actor!(terminal, comp)
                @info "TextInputEvent: $(getEventType(event)) comp: $comp"

                #= Paste from clipboard
                # KEYMODs: LCTRL = 4160 | RCTRL = 4096

                #elseif event_type == SDL_KEYDOWN && (SDL_GetModState() |> string == "4160" || SDL_GetModState() |> string == "4096") && (key_sym == "v" || key_sym == "V")
                    comp = comp * "$(unsafe_string(SDL_GetClipboardText()))"
                    update_text_actor!(terminal, comp)
                    =#
            elseif length(comp) > 1 && getEventType(event_array) == 768 && key_sym == 8  # "\b" backspace key
                comp = comp[1:end-1]
                update_text_actor!(terminal, comp)
                #draw(g); SDL_RenderPresent(g.screen.renderer)

                @info "BackspaceEvent: $(getEventType(event)) comp: $comp"

            elseif getEventType(event_array) == 768 && key_sym == 81
                if haskey(terminal.data, :command_history) && length(terminal.data[:command_history]) > 0
                    terminal.data[:command_history] = copy(GameOne.circshift(terminal.data[:command_history], 1))
                    comp = terminal.data[:command_history][begin]
                    update_text_actor!(terminal, comp)
                end

            elseif getEventType(event_array) == 768 && key_sym == 82
                if haskey(terminal.data, :command_history) && length(terminal.data[:command_history]) > 0
                    terminal.data[:command_history] = copy(GameOne.circshift(terminal.data[:command_history], -1))
                    comp = terminal.data[:command_history][begin]
                    update_text_actor!(terminal, comp)
                end

            elseif getEventType(event) == SDL_KEYDOWN && key_sym == 13 #"\r" # return key
                @info "QuitEvent: $(getEventType(event))"
                @info "Composition: $comp"

                if !haskey(terminal.data, :command_history)
                    terminal.data[:command_history] = copy(GameOne.circshift([""], 0))
                end
                
                terminal.data[:command_history] = copy(GameOne.circshift([ Set([ terminal.data[:command_history]..., comp ])... ], 0))
    
                done = true
            end

            # Update screen(s)
            for s in g.screen
                SDL_RenderClear(s.renderer)
                draw(g)
                SDL_RenderPresent(s.renderer)
            end
        end
    end

    SDL_StopTextInput()
    terminal.label = comp[2:end]
end


# Having a QuitException is useful for testing, since an exception will simply
# pause the interpreter. For release builds, the catch() block will call quitSDL().
struct QuitException <: Exception end

function getSDLError()
    x = SDL_GetError()
    return unsafe_string(x)
end

function initSDL()
    SDL_GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS, 4)
    SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, 4)
    r = SDL_Init(UInt32(SDL_INIT_VIDEO | SDL_INIT_AUDIO))
    if r != 0
        error("Unable to initialise SDL: $(getSDLError())")
    end
    TTF_Init()

    mix_init_flags = MIX_INIT_FLAC | MIX_INIT_MP3 | MIX_INIT_OGG
    inited = Mix_Init(Int32(mix_init_flags))
    if inited & mix_init_flags != mix_init_flags
        @warn "Failed to initialise audio mixer properly. Sounds may not play correctly\n$(getSDLError())"
    end

    device = Mix_OpenAudio(Int32(22050), UInt16(AUDIO_S16SYS), Int32(2), Int32(1024))
    if device != 0
        @warn "No audio device available, sounds and music will not play.\n$(getSDLError())"
        Mix_CloseAudio()
    end
end

function quitSDL(g)
    # Need to close the callback before quitting SDL to prevent it from hanging
    # https://github.com/n0name/2D_Engine/issues/3
    @debug "Quitting the game"
    clear!(scheduler[])
    for s in g.screen
        SDL_DelEventWatch(window_event_watcher_cfunc[], s.window);
        SDL_DestroyRenderer(s.renderer)
        SDL_DestroyWindow(s.window)
    end
    #Run all finalisers
    GC.gc();GC.gc();
    quitSDL()
end

function quitSDL()
    Mix_HaltMusic()
    Mix_HaltChannel(Int32(-1))
    Mix_CloseAudio()
    TTF_Quit()
    Mix_Quit()
    SDL_Quit()
end

function main()
    if length(ARGS) < 1
        throw(ArgumentError("No file to run"))
    end
    jlf = ARGS[1]
    rungame(jlf)
end

end # module
