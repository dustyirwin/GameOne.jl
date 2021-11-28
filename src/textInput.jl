
function start_text_input(g::Game, ta::Actor)
    done = false
    comp = ta.label
    
    SDL2.StartTextInput()

    while !done
        event, success = GameOne.pollEvent!()

        if success
            event_array = [ Char(i) for i in event ]
            event_type = getEventType(event)
            key_sym = event_array[21] |> string
        
            if getEventType(event) == SDL2.TEXTINPUT
                char = getTextInputEventChar(event)
                comp *= char
                comp = comp == ">`" ? ">" : comp
        
                update_text_actor!(ta, comp)
        
                @show "TextInputEvent: $(getEventType(event)) comp: $comp"
        
            elseif length(comp) > 1 && event_type == SDL2.KEYDOWN && key_sym == "\b"  # backspace key
                comp = comp[1:end-1]
        
                update_text_actor!(ta, comp)
        
                @show "BackspaceEvent: $(getEventType(event)) comp: $comp"
        
            elseif getEventType(event) == SDL2.KEYDOWN && key_sym == "\r" # return key
                @show "QuitEvent: $(getEventType(event))"
                done = true
            end
        
            # Update screen
            SDL2.RenderClear(g.screen.renderer)
            draw(ta)
            SDL2.RenderPresent(g.screen.renderer)
        end
    end

    SDL2.StopTextInput()
    comp[2:end]
end


function execute_terminal_command(g::Game, text, M::Module)
    try
        ex = Meta.parse(text)
        @show eval(M, ex)
    catch e
        @warn e
    end
end


function process_keyboard_input()
    key_sym, event = get_keyboard_symbol()
    event_type = getEventType(event)

    if event_type == SDL2.TextInputEvent || event_type == SDL2.KEYDOWN
        @show event_type

        if key_sym == '\r'
            global textInput = false
            terminal.label = ">"
        elseif keysym == '\b' && length(terminal.label) > 1
            terminal.label = terminal.label[1:end-1]
        end
    end
end

# get the next keyboard input symbol from the user keyboard e.g. 'a', '&', 'U', '{', etc.
function get_keyboard_symbol()
    SDL2.StartTextInput()

    while true
        event, success = GameOne.pollEvent!()

        if success #&& event in show_events
            @show event
            @show key_sym = event_array[13] |> string
            @show key_sym = event_array[13] |> Char
            @show key_sym = event_array[21] |> string

            SDL2.StopTextInput()
        end
    end

    key_sym, event
end

# creating new surface from composition
function create_new_text_surface!(comp::String, ta::Actor)
    ta.surfaces[begin] = SDL2.TTF_RenderText_Blended_Wrapped(
        SDL2.TTF_OpenFont(ta.data[:font_path], ta.data[:pt_size]),
        comp,
        SDL2.Color(ta.data[:font_color]...),
        UInt32(ta.data[:wrap_length])
    )

    ta
end