
# ref: https://www.geeksforgeeks.org/sdl-library-in-c-c-with-examples/
using SimpleDirectMediaLayer.LibSDL2

SDL_GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS, 16)
SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, 16)

@assert SDL_Init(SDL_INIT_EVERYTHING) == 0 "error initializing SDL: $(unsafe_string(SDL_GetError()))"

@kwdef mutable struct SCreen
    name::String = ""
    window::Union{Ptr{SDL_Window}, Nothing}=nothing
    renderer::Union{Ptr{SDL_Renderer}, Nothing}=nothing
    width::Cint=Cint(800)
    height::Cint=Cint(600)
    has_focus::Bool=false
    full_screen::Bool=false
    minimized::Bool=false
    shown::Bool=false
    window_id::Cint=Cint(0)
end

windows = []

for i in 1:2
    win = LWindow()
    win.name = "Game$i"
    win.window = SDL_CreateWindow(win.name, SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, win.width, win.height, SDL_WINDOW_SHOWN)
    win.renderer = SDL_CreateRenderer(win.window, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC)
    win.window_id = SDL_GetWindowID(win.window)
    SDL_SetWindowResizable(win.window, SDL_TRUE)
    push!(windows, win)
end

surface1 = IMG_Load(joinpath(@__DIR__, "images", "alien.png"))
texs = SDL_CreateTextureFromSurface.([w.renderer for w in windows], surface1)
SDL_FreeSurface(surface1)

w_ref, h_ref = Ref{Cint}(0), Ref{Cint}(0)
SDL_QueryTexture(texs[1], C_NULL, C_NULL, w_ref, h_ref)

try
    w, h = w_ref[], h_ref[]
    xs = [ (800 - w) ÷ 2 for i in 1:2 ]
    ys = [ (600 - h) ÷ 2 for i in 1:2 ]
    dest_refs = [ Ref(SDL_Rect(xs[i], ys[i], w, h)) for i in 1:2 ]
    close = false
    speed = 300

    while !close
        event_ref = Ref{SDL_Event}()
        
        while Bool(SDL_PollEvent(event_ref))
            evt = event_ref[]
            evt_ty = evt.type

            if evt_ty == SDL_QUIT
                close = true
                break
            elseif evt_ty == SDL_KEYDOWN
                scan_code = evt.key.keysym.scancode
                win_id = evt.window.windowID
                if scan_code == SDL_SCANCODE_W || scan_code == SDL_SCANCODE_UP
                    ys[win_id] -= speed / 30
                    break
                elseif scan_code == SDL_SCANCODE_A || scan_code == SDL_SCANCODE_LEFT
                    xs[win_id] -= speed / 30
                    break
                elseif scan_code == SDL_SCANCODE_S || scan_code == SDL_SCANCODE_DOWN
                    ys[win_id] += speed / 30
                    break
                elseif scan_code == SDL_SCANCODE_D || scan_code == SDL_SCANCODE_RIGHT
                    xs[win_id] += speed / 30
                    break
                else
                    break
                end
            elseif evt_ty == SDL_WINDOWEVENT
                for w in windows
                    if w.window_id == evt.window.windowID
                        w.has_focus = true
                    else
                        w.has_focus = false
                    end
                end

                @info "Window focus gained on window $(evt.window.windowID)"
            end
        end

        #x + w > 1000 && (x = 1000 - w)
        #x < 0 && (x = 0)
        #y + h > 1000 && (y = 1000 - h)
        #y < 0 && (y = 0)

        #dest_refs[] = SDL_Rect(x, y, w, h)
        
        for (i,win,t) in zip(1:2, windows, texs)
            if win.has_focus
                SDL_RenderClear(win.renderer)
                dest_refs[i][] = SDL_Rect(xs[i], ys[i], w, h)
                SDL_RenderCopy(win.renderer, t, C_NULL, dest_refs[i])
                SDL_RenderPresent(win.renderer)
            else
                SDL_RenderPresent(win.renderer)
            end
        end

        #dest = dest_ref[]
        #x, y, w, h = dest.x, dest.y, dest.w, dest.h
        #SDL_RenderPresent.([w.renderer for w in windows])

        SDL_Delay(1000 ÷ 60)
    end
finally
    SDL_DestroyTexture.(texs)
    SDL_DestroyRenderer.([w.renderer for w in windows])
    SDL_DestroyWindow.([w.window for w in windows])
    SDL_Quit()
end