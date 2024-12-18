# Use a pre-allocated event buffer instead of creating new ones
const EVENT_BUFFER = Ref{SDL2.SDL_Event}()

function pollEvents!()
    while Bool(SDL2.SDL_PollEvent(EVENT_BUFFER))
        evt = EVENT_BUFFER[]
    end

    return evt
end

function getEventType(e::Array{UInt8})
    bitcat(UInt32, e[4:-1:1])
end

function getEventType(e::SDL2.SDL_Event)
    bitcat(UInt32, e[4:-1:1])
end

# TextInputEvent only?
function getTextInputEventChar(e::Array{UInt8})
    Char(e[13])
end

function getTextEditEventChar(e::Array{UInt8})
    Char(e[14])
end

function getTextEditEventString(e::Array{UInt8})
    join([string.(e[13:32])]...)
end

function bitcat(::Type{T}, arr)::T where T<:Number
    out = zero(T)

    for x in arr
        out = out << T(sizeof(x) * 8)
        out |= convert(T, x)  # the `convert` prevents signed T from promoting to Int64.
    end

    out
end


################################################################################

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
    @debug "Mouse Button" e.x e.y e.windowID
    
    if (t == SDL_MOUSEBUTTONUP)
        Base.invokelatest(g.onmouseup_function, g, (e.x, e.y), MouseButtons.MouseButton(e.button), e.windowID)
    elseif (t == SDL_MOUSEBUTTONDOWN)
        Base.invokelatest(g.onmousedown_function, g, (e.x, e.y), MouseButtons.MouseButton(e.button), e.windowID)
    end
end

function handleMousePan(g::Game, e, t)
    @debug "Mouse Move" e.x e.y e.windowID
    Base.invokelatest(g.onmousemove_function, g, (e.x, e.y), e.windowID)
end

function handleWindowEvent(g::Game, e, t)
    window_id = e.window.windowID
    
    # Update active screen based on window focus
    if window_id == SDL2.SDL_GetWindowID(g.screens.primary.window)
        g.screens.active_screen = UInt32(1)
        g.screens.primary.has_focus = true
        g.screens.secondary.has_focus = false
    elseif window_id == SDL2.SDL_GetWindowID(g.screens.secondary.window)
        g.screens.active_screen = UInt32(2)
        g.screens.primary.has_focus = false
        g.screens.secondary.has_focus = true
    end
    
    @debug "Window $window_id focus changed. Active screen: $(g.screens.active_screen)"
end