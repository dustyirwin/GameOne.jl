using GLFW

function getEventType(e::Array{UInt8})
    bitcat(UInt32, e[4:-1:1])
end
function getEventWindowID(e::Array{UInt8})
    bitcat(UInt32, e[8:-1:5])
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



function handleMousePan(g::Game, e, t)
    @debug "Mouse Move" e.x e.y e.windowID
    Base.invokelatest(g.onmousemove_function, g, (e.x, e.y), e.windowID)
end

function setup_glfw_callbacks(ctx::GLContext, game::Game)
    # Keyboard
    GLFW.SetKeyCallback(ctx.window) do window, key, scancode, action, mods
        if action == GLFW.PRESS
            game.keyboard.keys[key] = true
            Base.invokelatest(game.onkey_function, game, key, mods)
        elseif action == GLFW.RELEASE
            game.keyboard.keys[key] = false
        end
    end

    # Mouse button
    GLFW.SetMouseButtonCallback(ctx.window) do window, button, action, mods
        x, y = GLFW.GetCursorPos(window)
        if action == GLFW.PRESS
            game.mouse.buttons[button] = true
            Base.invokelatest(game.onmousedown_function, game, (x, y), button, mods)
        elseif action == GLFW.RELEASE
            game.mouse.buttons[button] = false
            Base.invokelatest(game.onmouseup_function, game, (x, y), button, mods)
        end
    end

    # Mouse move
    GLFW.SetCursorPosCallback(ctx.window) do window, xpos, ypos
        game.mouse.position = Vec2f(xpos, ypos)
        Base.invokelatest(game.onmousemove_function, game, (xpos, ypos), window)
    end

    # Window close, resize, etc. can be added similarly
end
