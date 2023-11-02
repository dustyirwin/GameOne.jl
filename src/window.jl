
# -------- Opening a window ---------------
# Forward reference for @cfunction
function windowEventWatcher end
const window_event_watcher_cfunc = Ref(Ptr{Nothing}(0))

const window_paused = Threads.Atomic{UInt8}(0) # Whether or not the game should be running (if lost focus)


function makeWinRenderer(title = "GameOne", w=1920, h=1080)
    global winWidth, winHeight, winWidth_highDPI, winHeight_highDPI

    win = SDL2.SDL_CreateWindow(title,
        Int32(SDL2.SDL_WINDOWPOS_CENTERED), Int32(SDL2.SDL_WINDOWPOS_CENTERED), Int32(w), Int32(h),
        UInt32(SDL2.SDL_WINDOW_ALLOW_HIGHDPI|SDL2.SDL_WINDOW_OPENGL|SDL2.SDL_WINDOW_SHOWN));
        SDL2.SDL_SetWindowMinimumSize(win, Int32(w), Int32(h))
    
    window_event_watcher_cfunc[] = @cfunction(windowEventWatcher, Cint, (Ptr{Nothing}, Ptr{SDL2.SDL_Event}))

    renderer = SDL2.SDL_CreateRenderer(win, Int32(-1), UInt32(SDL2.SDL_RENDERER_ACCELERATED | SDL2.SDL_RENDERER_PRESENTVSYNC))

    SDL2.SDL_SetRenderDrawBlendMode(renderer, SDL2.SDL_BLENDMODE_BLEND)

    return win,renderer
end

# This function handles all window events.
# We currently do no allow window resizes
function windowEventWatcher(data_ptr::Ptr{Cvoid}, event_ptr::Ptr{SDL2.SDL_Event})::Cint
    ev = unsafe_load(event_ptr)
    
    if (ev.type == SDL2.SDL_WINDOWEVENT)
        #event = unsafe_load(Ptr{SDL_WindowEvent}(pointer_from_objref(ev)))
        winevent = ev.window.event
        if (winevent == SDL2.SDL_WINDOWEVENT_FOCUS_LOST || winevent == SDL2.SDL_WINDOWEVENT_HIDDEN || winevent == SDL2.SDL_WINDOWEVENT_MINIMIZED)
            # Stop game playing when out of focus
            window_paused[] = 1
            #end
        elseif (winevent == SDL2.SDL_WINDOWEVENT_FOCUS_GAINED || winevent == SDL2.SDL_WINDOWEVENT_SHOWN)
            window_paused[] = 0
        end
    end
    
    return 0
end 


function getWindowSize(win)
    w, h, w_highDPI, h_highDPI = Int32[0], Int32[0], Int32[0], Int32[0]
    SDL2.SDL_GetWindowSize(win, w, h)
    SDL2.SDL_GL_GetDrawableSize(win, w_highDPI, h_highDPI)
    return w[],h[],w_highDPI[],h_highDPI[]
end
