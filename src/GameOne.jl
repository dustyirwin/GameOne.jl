module GameOne

using Reexport: @reexport

# Base imports
@reexport using Logging: @debug, @info, @warn, @error, @logmsg
@reexport using Colors: FixedPointNumbers, @colorant_str, ARGB, Colorant, red, green, blue, alpha
@reexport using Base.Threads: @threads, @spawn, Atomic, SpinLock
@reexport using Dates: now, Millisecond
@reexport using Random: rand, randstring, shuffle, shuffle!
@reexport using DataStructures: OrderedDict, counter, @enum
@reexport using Sockets
@reexport using CImGui
@reexport using CImGui.CSyntax
@reexport using CImGui.CSyntax.CStatic
@reexport using CImGui: ImVec2, ImVec4, IM_COL32, ImS32, ImU32, ImS64, ImU64, lib
@reexport using CImGui.lib

@reexport using Printf: @sprintf

# SDL2 imports
@reexport using SimpleDirectMediaLayer.LibSDL2: SDL_Event, SDL_Texture, SDL_DestroyTexture, SDL_ShowCursor, 
    SDL_SetWindowFullscreen, SDL_SetHint, SDL_HINT_RENDER_SCALE_QUALITY, SDL_RenderPresent, 
    SDL_HasIntersection, SDL_Rect, SDL_RenderFillRect, SDL_CreateTextureFromSurface, SDL_TEXTUREACCESS_TARGET,
    SDL_BlendMode, SDL_Surface, SDL_WINDOW_FULLSCREEN, IMG_Load, SDL_SetRenderTarget,
    SDL_PIXELFORMAT_ARGB32, SDL_UpperBlitScaled, SDL_FreeSurface, SDL_FLIP_NONE, SDL_FLIP_BOTH, SDL_FLIP_VERTICAL, 
    SDL_FLIP_HORIZONTAL, SDL_RenderCopyEx, SDL_PollEvent, SDL_TEXTINPUT, SDL_KEYDOWN, SDL_KEYUP, SDL_MOUSEBUTTONDOWN, 
    SDL_MOUSEBUTTONUP, SDL_GetError, SDL_INIT_VIDEO, SDL_INIT_AUDIO, SDL_WINDOWEVENT, SDL_QUIT, SDL_MOUSEMOTION, 
    SDL_MOUSEWHEEL, SDL_GetClipboardText, SDL_SetClipboardText, SDL_GetError, SDL_StopTextInput, SDL_StartTextInput, SDL_GL_MULTISAMPLEBUFFERS, 
    SDL_GL_MULTISAMPLESAMPLES,SDL_DestroyRenderer, SDL_DestroyWindow, SDL_GetWindowID, SDL_RenderDrawLine, 
    SDL_RenderDrawPoint, SDL_WINDOWPOS_CENTERED, SDL_WINDOW_ALLOW_HIGHDPI, SDL_RENDERER_ACCELERATED, SDL_WINDOW_ALLOW_HIGHDPI,
    SDL_RENDERER_PRESENTVSYNC, SDL_RENDERER_TARGETTEXTURE, SDL_RENDERER_SOFTWARE, 
    SDL_BLENDMODE_BLEND, SDL_SetTextureAlphaMod, SDL_GL_SetAttribute, SDL_Init, SDL_Color,
    SDL_WINDOW_OPENGL, SDL_WINDOW_SHOWN, SDL_CreateWindow, SDL_SetWindowMinimumSize, SDL_SetWindowResizable, SDL_WINDOW_RESIZABLE,
    SDL_WINDOW_MOUSE_FOCUS, SDL_WINDOW_FOREIGN, SDL_WINDOW_ALWAYS_ON_TOP, SDL_WINDOW_SKIP_TASKBAR, SDL_WINDOW_UTILITY, SDL_WINDOW_TOOLTIP,
    SDL_WINDOW_INPUT_FOCUS,SDL_WINDOW_MOUSE_FOCUS,SDL_WINDOW_FOREIGN,SDL_WINDOW_ALWAYS_ON_TOP,SDL_WINDOW_SKIP_TASKBAR,SDL_WINDOW_UTILITY,
    SDL_WINDOW_TOOLTIP,SDL_WINDOW_POPUP_MENU, SDL_WINDOW_METAL,SDL_WINDOW_VULKAN,SDL_WINDOW_HIDDEN,SDL_WINDOW_BORDERLESS,
    SDL_WINDOW_FULLSCREEN_DESKTOP,SDL_WINDOW_FULLSCREEN,SDL_WINDOW_OPENGL,
    
    SDL_SetTextureBlendMode, SDL_CreateRGBSurface, SDL_CreateRGBSurfaceWithFormat, SDL_CreateRGBSurfaceWithFormatFrom,
    SDL_CreateRenderer, SDL_CreateTexture, SDL_SetRenderDrawBlendMode, SDL_SetRenderDrawColor, SDL_RenderClear, SDL_DelEventWatch,
    SDL_GetWindowSize, SDL_GetWindowFlags, SDL_GetWindowSurface, SDL_Quit, SDL_RWFromFile, SDL_RenderCopy, SDL_RenderDrawRect,
    MIX_INIT_FLAC, MIX_INIT_MP3, MIX_INIT_OGG, Mix_Init, Mix_OpenAudio, Mix_HaltMusic, Mix_HaltChannel, Mix_CloseAudio, 
    Mix_Quit, Mix_LoadWAV_RW, AUDIO_S16SYS, Mix_PlayChannelTimed, Mix_PlayMusic, Mix_PlayingMusic, Mix_FreeChunk, 
    Mix_FreeMusic, Mix_VolumeMusic, Mix_Volume, Mix_PausedMusic, Mix_ResumeMusic, Mix_LoadMUS, Mix_PauseMusic,
    TTF_Quit, TTF_OpenFont, TTF_RenderText_Blended_Wrapped, TTF_SetFontOutline, TTF_CloseFont, TTF_Init,
    SDL_HINT_VIDEO_X11_NET_WM_BYPASS_COMPOSITOR, SDL_HINT_RENDER_VSYNC, SDL_HINT_RENDER_DRIVER, SDL_HINT_RENDER_DIRECT3D_THREADSAFE

import SimpleDirectMediaLayer
const SDL2 = SimpleDirectMediaLayer.LibSDL2
global const BackendPlatformUserData = Ref{Any}(C_NULL)

# GameOne exports
export SDL2, BackendPlatformUserData
export game, draw, scheduler, schedule_once, schedule_interval, schedule_unique, unschedule,
    collide, angle, distance, play_music, play_sound, line, clear, rungame, game_include,
    window_paused, getEventType, getTextInputEventChar, start_text_input, update_text_actor!, sdl_colors, quitSDL,
    image_surface
export Game, Screen, Keys, KeyMods, MouseButton
export Actor, TextActor, ImageFileActor, ImageMemActor 
export Line, Rect, Triangle, Circle
export ImGui_ImplSDL2_InitForSDLRenderer, ImGui_ImplSDLRenderer2_Init, ImGui_ImplSDLRenderer2_NewFrame, ImGui_ImplSDL2_NewFrame,
    ImGui_ImplSDLRenderer2_RenderDrawData, ImGuiDockNodeFlags_PassthruCentralNode, TextDisabled, PushItemFlag, PopItemFlag,
    ImGui_ImplSDLRenderer2_Shutdown#, ImGui_ImplSDL2_Shutdown

# :/
#import DocStringExtensions: TYPEDSIGNATURES

# ImGuiSDLBackend
include("imgui_impl_sdl2.jl")
include("imgui_impl_sdlrenderer2.jl")

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

# Add at module level
const STRING_POOL = Dict{String, String}()

function intern_string(s::String)
    get!(STRING_POOL, s) do
        s
    end
end

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
    imgui_function::Function
    imgui_settings::Dict{String,Any}
    state::Vector{Dict{String,Any}}
    socket::Vector{TCPSocket}
    Game() = new()
end

const timer = WallTimer()
const game = Ref{Game}()
const playing = Ref{Bool}(false)
const paused = Ref{Bool}(false)

function initscreen(gm::Module, name::String)
    h = getifdefined(gm, HEIGHTSYMBOL, 600,)
    w = getifdefined(gm, WIDTHSYMBOL, 800,)
    background = getifdefined(gm, BACKSYMBOL, SDL_CreateRGBSurface(0, w, h, 32, 0, 0, 0, 0))

    #if !(background isa Colorant)
    #    background = image_surface(background)
    #end
    
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


ver = pointer(SDL2.SDL_version[SDL2.SDL_version(0,0,0)])
SDL2.SDL_GetVersion(ver)
global sdlVersion = string(unsafe_load(ver).major, ".", unsafe_load(ver).minor, ".", unsafe_load(ver).patch)
println("SDL version: ", sdlVersion)
sdlVersion = parse(Int32, replace(sdlVersion, "." => ""))


function mainloop(g::Game)
    start!(timer)
    
    sdlRenderer = g.screen.renderer
    window = g.screen.window
    
    # create the ImGui context
    ctx = g.imgui_settings["ctx"] = CImGui.CreateContext()
    io = g.imgui_settings["io"] = CImGui.GetIO()

    io.BackendPlatformUserData = C_NULL
    io.ConfigFlags = unsafe_load(io.ConfigFlags) | CImGui.ImGuiConfigFlags_DockingEnable
    io.ConfigFlags = unsafe_load(io.ConfigFlags) | CImGui.ImGuiConfigFlags_ViewportsEnable 
    io.ConfigFlags = unsafe_load(io.ConfigFlags) | CImGui.ImGuiConfigFlags_NavEnableKeyboard
    io.ConfigFlags = unsafe_load(io.ConfigFlags) | CImGui.ImGuiConfigFlags_NavEnableGamepad

    ImGui_ImplSDL2_InitForSDLRenderer(window, sdlRenderer)
    ImGui_ImplSDLRenderer2_Init(sdlRenderer)
    
    quit = false
    
    try
        while !quit
            #Don't run if game is paused by system (resizing, lost focus, etc)
            #while window_paused[] != 0
            #    _ = pollEvent()
            #    sleep(0.5)
            #end

            # Handle Events
            errorMsg = ""

            event_ref = Ref{SDL_Event}()
            
            while Bool(SDL_PollEvent(event_ref))
                evt = event_ref[]
                ImGui_ImplSDL2_ProcessEvent(evt, sdlVersion)
                evt_ty = evt.type

                @debug "evt_ty: $evt_ty evt.key.keysym.sym: $(evt.key.keysym.sym)"
                
                if evt_ty == SDL2.SDL_QUIT
                    quit = true
                    break
                    
                else
                    handleEvents!(g, evt, evt_ty)
                end
            end

            # clearing out renderer for new frame
            SDL2.SDL_RenderClear(sdlRenderer);
            if window_paused[] == 0
                Base.invokelatest(g.render_function, g)
            end           
            
            # run custom imguiSDL2 function to draw ui elements on screen
            Base.invokelatest(g.imgui_function, g)

            # present rendered image to screen
            SDL_RenderPresent(sdlRenderer)

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

            # Small sleep to prevent CPU hogging
            sleep(0.001)
        end
    catch err
        @warn "Error in renderloop!" exception=err
        Base.show_backtrace(stderr, catch_backtrace())
    finally
        ImGui_ImplSDLRenderer2_Shutdown();
        #ImGui_ImplSDL2_Shutdown();

        CImGui.DestroyContext(ctx)
        SDL2.SDL_DestroyRenderer(sdlRenderer);
        SDL2.SDL_DestroyWindow(window);
        SDL2.SDL_Quit()
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
    
    #elseif (t == SDL_QUIT)
    #    paused[] = playing[] = false
    end
end

function handleKeyPress(g::Game, e, t)
    keySym = e.keysym.sym
    keyMod = e.keysym.mod
    @debug "Keyboard" keySym, keyMod
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
    if (g.screen.window_id == e.window.windowID) && !g.screen.has_focus
        g.screen.has_focus = true
        @debug "Window $(e.window.windowID) gained focus"

    elseif g.screen.has_focus
        g.screen.has_focus = false
        @debug "Window $(e.window.windowID) lost focus"

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
function rungame(jlf::String, external::Bool=true; socket::Union{TCPSocket,Nothing}=nothing)
    # The optional argument `external` is used to determine whether the zero or single argument version 
    # has been called. End users should never have to use this argument directly. 
    # external=true means rungame has been called from the REPl or run script, with the game file as input
    # external=false means rungame has been called at the bottom of the game file itself
    global playing, paused
    g = initgame(jlf::String, external; socket=socket)
    try
        playing[] = paused[] = true
        mainloop(g)
    catch e
        if !isa(e, QuitException) && !isa(e, InterruptException)
            @error e exception = (e, catch_backtrace())
        end
    finally
        GameOne.quitSDL(g)
    end
end

function rungame()
    rungame(abspath(PROGRAM_FILE), false)
end

function initgame(jlf::String, external::Bool; socket::Union{TCPSocket,Nothing}=nothing)
    if !isfile(jlf)
        ArgumentError("File not found: $jlf")
    end

    # setting up hints for SDL to run on Mac
    SDL_SetHint(SDL_HINT_RENDER_DRIVER, "metal")
    SDL_SetHint(SDL_HINT_RENDER_VSYNC, "1")
    SDL_SetHint(SDL_HINT_VIDEO_X11_NET_WM_BYPASS_COMPOSITOR, "0")

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

    g.imgui_function = getfn(g.game_module, :imgui, 2)
    g.update_function = getfn(g.game_module, :update, 2)
    g.render_function = getfn(g.game_module, :draw, 3)
    g.onkey_function = getfn(g.game_module, :on_key_down, 3)
    g.onmouseup_function = getfn(g.game_module, :on_mouse_up, 3)
    g.onmousedown_function = getfn(g.game_module, :on_mouse_down, 3)
    g.onmousemove_function = getfn(g.game_module, :on_mouse_move, 2)
    g.state = Vector{Dict{String,Dict}}([Dict("imgui"=>Dict("username"=>"", "password"=>""))])
    g.screen = initscreen(g.game_module, name)
    g.imgui_settings = Dict(
        "menu_active"=>true,
        "show_login"=>false,
        "show_menu"=>false,
        "console_history"=>Vector{String}(),
        "io"=>CImGui.GetIO()
    )
    clear(g.screen)
    
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
    SDL_DelEventWatch(window_event_watcher_cfunc[], g.screen.window)
    SDL_DestroyRenderer(g.screen.renderer)
    SDL_DestroyWindow(g.screen.window)
    
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

# Add ImGui memory management settings
function configure_imgui_memory()
    io = CImGui.GetIO()
    
    # Set smaller vertex/index buffer sizes if you don't need large UIs
    io.BackendFlags = unsafe_load(io.BackendFlags) | 
                     CImGui.ImGuiBackendFlags_RendererHasVtxOffset
    
    # Configure ImGui to use less memory
    style = CImGui.GetStyle()
    style.WindowPadding = ImVec2(4, 4)
    style.ItemSpacing = ImVec2(4, 2)
    style.ItemInnerSpacing = ImVec2(2, 2)
end

end # module
