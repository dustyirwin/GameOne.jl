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

function get_mouse_button_name(button::UInt8)
    if button == SDL2.BUTTON_LEFT
        return "LEFT"
    elseif button == SDL2.BUTTON_RIGHT
        return "RIGHT"
    elseif button == SDL2.BUTTON_MIDDLE
        return "MIDDLE"
    else
        return "BUTTON_$button"
    end
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
        primary_window_id = SDL2.SDL_GetWindowID(screens.primary.window)
        secondary_window_id = SDL2.SDL_GetWindowID(screens.secondary.window)
        
        # Get window information
        current_screen = if window_id == primary_window_id
            screens.active_screen = :primary
            "PRIMARY"
        elseif window_id == secondary_window_id
            screens.active_screen = :secondary
            "SECONDARY"
        else
            "UNKNOWN"
        end
        
        # Handle mouse events with enhanced logging
        if evt.type == SDL2.MOUSEBUTTONDOWN
            x, y = Int(evt.button.x), Int(evt.button.y)
            button = evt.button.button
            button_name = get_mouse_button_name(button)
            @info "MOUSE EVENT" event="BUTTON DOWN" button=button_name screen=current_screen x=x y=y window_id=window_id
            handle_mouse_button!(game_state, evt, screens)
        elseif evt.type == SDL2.MOUSEBUTTONUP
            x, y = Int(evt.button.x), Int(evt.button.y)
            button = evt.button.button
            button_name = get_mouse_button_name(button)
            @info "MOUSE EVENT" event="BUTTON UP" button=button_name screen=current_screen x=x y=y window_id=window_id
            handle_mouse_button!(game_state, evt, screens)
        elseif evt.type == SDL2.MOUSEMOTION
            x, y = Int(evt.motion.x), Int(evt.motion.y)
            if game_state.dragging_actor !== nothing
                @info "MOUSE EVENT" event="MOTION" screen=current_screen x=x y=y window_id=window_id actor=game_state.dragging_actor.label
            end
            handle_mouse_motion!(game_state, evt, screens)
        end
    end
    return true
end

function handle_mouse_button!(game_state, evt, screens::GameScreens)
    x, y = Int(evt.button.x), Int(evt.button.y)
    window_id = evt.button.windowID
    current_screen = screens.active_screen == :primary ? "PRIMARY" : "SECONDARY"
    button_name = get_mouse_button_name(evt.button.button)
    
    if evt.type == SDL2.MOUSEBUTTONDOWN
        # Check for clicks on actors in the active screen
        for actor in game_state.actors
            if actor.current_window == screens.active_screen && collide(actor, x, y)
                @info "ACTOR CLICKED" actor=actor.label button=button_name screen=current_screen x=x y=y window_id=window_id
                game_state.dragging_actor = actor
                # Store the offset between mouse and actor position for smooth dragging
                actor.data[:mouse_offset] = Int32[x - actor.x, y - actor.y]
                break
            end
        end
    elseif evt.type == SDL2.MOUSEBUTTONUP && game_state.dragging_actor !== nothing
        @info "ACTOR RELEASED" actor=game_state.dragging_actor.label button=button_name screen=current_screen x=x y=y window_id=window_id
        game_state.dragging_actor = nothing
    end
end

function handle_mouse_motion!(game_state, evt, screens::GameScreens)
    if game_state.dragging_actor !== nothing
        x, y = Int(evt.motion.x), Int(evt.motion.y)
        window_id = evt.motion.windowID
        current_screen = screens.active_screen == :primary ? "PRIMARY" : "SECONDARY"
        actor = game_state.dragging_actor
        
        # Update actor position based on mouse movement
        offset = actor.data[:mouse_offset]
        actor.x = x - offset[1]
        actor.y = y - offset[2]
        
        @info "ACTOR DRAGGING" actor=actor.label screen=current_screen x=x y=y window_id=window_id
        
        # Check if we should switch windows based on position
        if screens.active_screen == :primary && x > SCREEN_WIDTH - actor.w
            @info "ACTOR TRANSITION" actor=actor.label from="PRIMARY" to="SECONDARY" x=x y=y window_id=window_id
            actor.current_window = :secondary
            actor.x = 2
        elseif screens.active_screen == :secondary && x < 2
            @info "ACTOR TRANSITION" actor=actor.label from="SECONDARY" to="PRIMARY" x=x y=y window_id=window_id
            actor.current_window = :primary
            actor.x = SCREEN_WIDTH - actor.w - 2
        end
    end
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
