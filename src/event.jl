# Use a pre-allocated event buffer instead of creating new ones
const EVENT_BUFFER = Ref{SDL2.SDL_Event}()

function pollEvents!()
    while Bool(SDL2.SDL_PollEvent(EVENT_BUFFER))
        evt = EVENT_BUFFER[]
        # ... event handling ...
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

function process_events!(game_state, screens::GameScreens)
    event_ref = Ref{SDL2.Event}()
    
    while Bool(SDL2.PollEvent(event_ref))
        evt = event_ref[]
        
        if evt.type == SDL2.QUIT
            return false
        end
        
        # Determine which window the event belongs to
        window_id = get_window_id(evt)
        if window_id == SDL2.SDL_GetWindowID(screens.primary.window)
            screens.active_screen = :primary
        elseif window_id == SDL2.SDL_GetWindowID(screens.secondary.window)
            screens.active_screen = :secondary
        end
        
        # Handle mouse events
        if evt.type == SDL2.MOUSEBUTTONDOWN
            handle_mouse_down!(game_state, evt, screens)
        elseif evt.type == SDL2.MOUSEBUTTONUP
            handle_mouse_up!(game_state, evt, screens)
        elseif evt.type == SDL2.MOUSEMOTION
            handle_mouse_motion!(game_state, evt, screens)
        end
    end
    return true
end

function get_window_id(evt::SDL2.SDL_Event)
    # Different event types store window ID in different places
    if evt.type in (SDL2.MOUSEBUTTONDOWN, SDL2.MOUSEBUTTONUP, SDL2.MOUSEMOTION)
        return evt.button.windowID
    end
    return 0
end

function handle_mouse_down!(game_state, evt, screens::GameScreens)
    x, y = Int(evt.button.x), Int(evt.button.y)
    
    # Get the current screen's actors
    active_screen = screens.active_screen == :primary ? screens.primary : screens.secondary
    
    # Your existing mouse down handling code here, but use active_screen
    # ...
end

function handleWindowEvent(g::Game, e, t)
    window_id = e.window.windowID
    
    # Update active screen based on window focus
    if window_id == SDL2.SDL_GetWindowID(g.screens.primary.window)
        g.screens.active_screen = :primary
        g.screens.primary.has_focus = true
        g.screens.secondary.has_focus = false
    elseif window_id == SDL2.SDL_GetWindowID(g.screens.secondary.window)
        g.screens.active_screen = :secondary
        g.screens.primary.has_focus = false
        g.screens.secondary.has_focus = true
    end
    
    @debug "Window $window_id focus changed. Active screen: $(g.screens.active_screen)"
end
