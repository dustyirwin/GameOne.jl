
# ref: https://www.geeksforgeeks.org/sdl-library-in-c-c-with-examples/
using SimpleDirectMediaLayer.LibSDL2
using GameOne

SDL_GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS, 16)
SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, 16)

@assert SDL_Init(SDL_INIT_EVERYTHING) == 0 "error initializing SDL: $(unsafe_string(SDL_GetError()))"

@kwdef mutable struct Screen
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

screen = []

for i in 1:2
    win = Screen()
    win.name = "Game$i"
    win.window = SDL_CreateWindow(win.name, SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, win.width, win.height, SDL_WINDOW_SHOWN)
    win.renderer = SDL_CreateRenderer(win.window, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC)
    win.window_id = SDL_GetWindowID(win.window)
    SDL_SetWindowResizable(win.window, SDL_TRUE)
    push!(screen, win)
end

surface1 = IMG_Load(joinpath(@__DIR__, "images", "alien.png"))
surface2 = IMG_Load(joinpath(@__DIR__, "images", "alien_hurt.png"))

texs = [ SDL_CreateTextureFromSurface(screen[i].renderer, surf) for (i,surf) in enumerate([surface1, surface2]) ]

SDL_FreeSurface.([surface1, surface2])

# getting texture bounding box width and height
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
            elseif evt_ty == SDL_MOUSEMOTION
                for s in screen
                    if s.has_focus && MouseButton.LEFT
                        xs[ s.window_id ] = evt.motion.x
                        ys[ s.window_id ] = evt.motion.y
                    end
                end

            elseif evt_ty == SDL_WINDOWEVENT
                for s in screen
                    if (s.window_id == evt.window.windowID)
                        s.has_focus = true
                        @info "Window $(evt.window.windowID) gained focus"
                    else
                        s.has_focus = false
                        @info "Window $(evt.window.windowID) lost focus"
                    end
                end
            end
        end
        
        for (i,s,t) in zip(1:length(screen), screen, texs)
            
            if s.has_focus
                SDL_RenderClear(s.renderer)
                dest_refs[i][] = SDL_Rect(xs[i], ys[i], w, h)
                SDL_RenderCopy(s.renderer, t, C_NULL, dest_refs[i])
                SDL_RenderPresent(s.renderer)
            else
                SDL_RenderPresent(s.renderer)
            end
        end

        SDL_Delay(1000 ÷ 60)
    end
finally
    SDL_DestroyTexture.(texs)
    SDL_DestroyRenderer.([s.renderer for s in screen])
    SDL_DestroyWindow.([s.window for s in screen])
    SDL_Quit()
end