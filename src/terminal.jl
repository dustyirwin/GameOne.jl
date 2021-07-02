
function start_terminal(g::Game, gs::Dict, AN::Module)
    done = false
    comp = ">"

    SDL2.StartTextInput()

    while !done
        event, success = GameOne.pollEvent!()
        
        if success
            
            if getEventType(event) == SDL2.TEXTINPUT
                
                @show SDL2.GetClipboardText()
                #comp *= String(Char(i) for i in clip)
                
                char = getTextInputEventChar(event)
                
                comp *= char
                comp = comp == ">`" ? ">" : comp
                @show "TextInputEvent! comp: $comp"

            elseif getEventType(event) == SDL2.TEXTEDITING
                
                #=
                Update the composition text.
                Update the cursor position.
                Update the selection length (if any).
                =#
                
                #cursor = getTextEditEventCursorPosition(event) #.edit.start)
                #selection_len = getTextEditEventCursorPosition(event) #.edit.length)
                
                @show "TextEditingEvent! Exiting..."
                done = true
            end
        end
        
        SDL2.Redraw()
    end

    SDL2.StopTextInput()
    
    @show ex = Meta.parse(comp[2:end])
    @show res = eval(M, ex)

    comp = 
    """
    >$(comp[2:end])
    $res
    """
    
    AN.update_text_actor!(gs[:terminal_text], comp)

end # func

"""
SDL2 Structs:
mutable struct TextEditingEvent <: AbstractEvent
    _type::Uint32
    timestamp::Uint32
    windowID::Uint32
    text::NTuple{32, UInt8}
    start::Sint32
    length::Sint32
end

mutable struct TextInputEvent <: AbstractEvent
    _type::Uint32
    timestamp::Uint32
    windowID::Uint32
    text::NTuple{32, UInt8}
end


//Main loop flag
    bool quit = false;

//Event handler
    SDL_Event e;

//Set text color as black
    SDL_Color textColor = { 0, 0, 0, 0xFF };

//The current input text.
    std::string inputText = "Some Text";
    gInputTextTexture.loadFromRenderedText( inputText.c_str(), textColor );

//Enable text input
    SDL_StartTextInput();

//While application is running
    while( !quit )
    {
        //The rerender text flag
            bool renderText = false;

        //Handle events on queue
            while( SDL_PollEvent( &e ) != 0 )
            {
        //Special key input
            else if( e.type == SDL_KEYDOWN )
            {
            //Handle backspace
                if( e.key.keysym.sym == SDLK_BACKSPACE && inputText.length() > 0 )
                {
                    //lop off character
                    inputText.pop_back();
                    renderText = true;
                }
            //Handle copy
                else if( e.key.keysym.sym == SDLK_c && SDL_GetModState() & KMOD_CTRL )
                {
                    SDL_SetClipboardText( inputText.c_str() );
                }
            //Handle paste
                else if( e.key.keysym.sym == SDLK_v && SDL_GetModState() & KMOD_CTRL )
                {
                    inputText = SDL_GetClipboardText();
                    renderText = true;
                }
            }
            //Special text input event
            else if( e.type == SDL_TEXTINPUT )
            {
                //Not copy or pasting
                if( !( SDL_GetModState() & KMOD_CTRL && ( e.text.text[ 0 ] == 'c' || e.text.text[ 0 ] == 'C' || e.text.text[ 0 ] == 'v' || e.text.text[ 0 ] == 'V' ) ) )
                {
                    //Append character
                    inputText += e.text.text;
                    renderText = true;
                }
            }
        }
            //Rerender text if needed
        if( renderText )
        {
            //Text is not empty
                if( inputText != "" )
                {
                //Render new text
                gInputTextTexture.loadFromRenderedText( inputText.c_str(), textColor );
            }
            //Text is empty
            else
            {
                //Render space texture
                gInputTextTexture.loadFromRenderedText( " ", textColor );
            }
        }
        //Clear screen
        SDL_SetRenderDrawColor( gRenderer, 0xFF, 0xFF, 0xFF, 0xFF );
        SDL_RenderClear( gRenderer );

    //Render text textures
    gPromptTextTexture.render( ( SCREEN_WIDTH - gPromptTextTexture.getWidth() ) / 2, 0 );
    gInputTextTexture.render( ( SCREEN_WIDTH - gInputTextTexture.getWidth() ) / 2, gPromptTextTexture.getHeight() );

    //Update screen
    SDL_RenderPresent( gRenderer );
    }
    //Disable text input
    SDL_StopTextInput();


    SDL_StartTextInput();
    while (!done) {
        SDL_Event event;
        if (SDL_PollEvent(&event)) {
            switch (event.type) {
                case SDL_QUIT:
                    /* Quit */
                    done = SDL_TRUE;
                    break;
                case SDL_TEXTINPUT:
                    /* Add new text onto the end of our text */
                    strcat(text, event.text.text);
                    break;
                case SDL_TEXTEDITING:
                    /*
                    Update the composition text.
                    Update the cursor position.
                    Update the selection length (if any).
                    */
                    composition = event.edit.text;
                    cursor = event.edit.start;
                    selection_len = event.edit.length;
                    break;
            }
        }
        Redraw();
    }

    """
