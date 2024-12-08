# Use a memory pool for frequently created/destroyed actors
mutable struct ActorPool{T}
    active::Vector{T}
    inactive::Vector{T}
    max_size::Int
end

function ActorPool(T::Type, max_size::Int=1000)
    ActorPool(T[], T[], max_size)
end

function get_actor(pool::ActorPool{T}) where T
    if !isempty(pool.inactive)
        actor = pop!(pool.inactive)
        push!(pool.active, actor)
        return actor
    elseif length(pool.active) < pool.max_size
        actor = T()  # Assuming default constructor exists
        push!(pool.active, actor)
        return actor
    end
    return nothing  # Pool is full
end

function release_actor!(pool::ActorPool, actor)
    idx = findfirst(==(actor), pool.active)
    if idx !== nothing
        deleteat!(pool.active, idx)
        push!(pool.inactive, actor)
    end
end

mutable struct Actor
    id::String
    label::String
    surfaces::Union{Vector{Ptr{SDL_Surface}}, Nothing}
    textures::Union{Vector{Ptr{SDL_Texture}}, Nothing}
    position::SDL_Rect
    scale::Vector{Float32}
    rotate_center::Union{Vector{Int32},Ptr{Nothing}}
    angle::Float64
    alpha::UInt8
    data::Dict{Symbol,Any}
    current_window::Symbol  # :primary or :secondary

    # Add constructor with type conversions
    function Actor(id::String, label::String, surfaces, textures, position::SDL_Rect, 
                  scale::Vector, rotate_center, angle::Number, alpha::Number, 
                  data::Dict{Symbol,Any}, current_window::Symbol=:primary)
        new(id, label, surfaces, textures, position, 
            convert(Vector{Float32}, scale), 
            rotate_center,
            convert(Float64, angle),
            convert(UInt8, alpha),
            data, current_window)
    end
end

function TextActor(text::String, font_path::String; id=randstring(10), x = 0, y = 0, pt_size = 24,
    font_color = Int[255, 255, 255, 255], outline_color = Int[0, 0, 0, 225],
    wrap_length = 800, outline_size = 0, current_window=:primary, kv...)

    @assert isfile(font_path) "Font file for $text not found: $font_path"

    text_font = TTF_OpenFont(font_path, pt_size)
    outline_font = TTF_OpenFont(font_path, pt_size)
    
    fg = TTF_RenderText_Blended_Wrapped(text_font, text, SDL_Color(font_color...), UInt32(wrap_length))
    if fg == C_NULL
        error("Failed to render text surface: $(unsafe_string(SDL_GetError()))")
    end
    
    surface = unsafe_load(fg)
    w, h = Int32(surface.w), Int32(surface.h)
    fg = if outline_size > 0
        TTF_SetFontOutline(outline_font, Int32(outline_size))
        bg = TTF_RenderText_Blended_Wrapped(outline_font, text, SDL_Color(outline_color...), UInt32(wrap_length))
        SDL_UpperBlitScaled(fg, C_NULL, bg, Int32[outline_size,outline_size, w, h])
        bg
    else
        fg
    end
    
    TTF_CloseFont(text_font)
    TTF_CloseFont(outline_font)
    
    r = SDL_Rect(x, y, w, h)

    a = Actor(
        id,
        text,
        [fg],
        [],
        r,
        [1., 1.],
        C_NULL,
        0,
        255,
        Dict(
            :sz => [w, h],
            :fade_in => false,
            :fade_out => false,
            :spin => false,
            :spin_cw => true,
            :shake => false,
            :next_frame => false,
            :font_path => font_path,
            :pt_size => pt_size,
            :outline_size => outline_size,
            :outline_color => outline_color,
            :wrap_length => wrap_length,
            :mouse_offset => Int32[0, 0],
            :font_color => font_color,
            :type=>"text",
            :current_window => current_window,
            )
        )
        
    for (k, v) in kv
        setproperty!(a, k, v)
    end

    return a
end

function update_text_actor!(a::Actor, new_text::String; font_path=a.data[:font_path], pt_size = a.data[:pt_size],
    font_color = a.data[:font_color], outline_color = a.data[:outline_color], wrap_length = a.data[:wrap_length],
    outline_size = a.data[:outline_size])

    font = TTF_OpenFont(font_path, pt_size)
    outline_font = TTF_OpenFont(font_path, pt_size)
    
    fg = TTF_RenderText_Blended_Wrapped(font, new_text, SDL_Color(font_color...), UInt32(wrap_length))
    w, h = size(fg)
    
    fg = if a.data[:outline_size] > 0
        TTF_SetFontOutline(outline_font, Int32(outline_size))
        bg = TTF_RenderText_Blended_Wrapped(
            outline_font, new_text, SDL_Color(outline_color...), UInt32(wrap_length))
        SDL_UpperBlitScaled(fg, C_NULL, bg, Int32[outline_size, outline_size, w, h])
        bg
    else
        fg
    end
    
    a.surfaces = [fg]
    a.w, a.h = size(a.surfaces[begin])
    a.textures = []
    a.label = new_text
    
    TTF_CloseFont(outline_font)
    TTF_CloseFont(font)

    return a
end

LoadBMP(src::String) = SDL_LoadBMP_RW(src, 1)

#= Actor does not release memory! Why??
function ImageMemActor(img_name::String, img; x=0, y=0, kv...)
    img = ARGB.(img)
    w, h = Int32.(size(img))
    sf = SDL_CreateRGBSurfaceWithFormatFrom(
        img,
        w,
        h,
        Int32(32),
        Int32(4w),
        SDL_PIXELFORMAT_ARGB32,
    )

    r = SDL_Rect(x, y, w, h)
    a = Actor(
        randstring(10),
        img_name,
        [sf],
        [],
        r,
        [1.,1.],
        C_NULL,
        0,
        255,
        Dict(
            :anim => false,
            :label=>img_name,
            :img=>img,              # required! Causes garbled image if not included?? Why?? Because sf is a pointer/reference?
            :sz=>[w,h],
            :fade_in=>false,        # change to fade_in? remove anim-specific keys (add k,v when anim is run?)
            :fade_out=>false,
            :spin=>false,
            :spin_cw=>true,
            :shake=>false,
            :mouse_offset=>Int32[0,0],
            :type=>"imagemem",
        )
    )

    for (k, v) in kv
        setproperty!(a, k, v)
    end
    return a
end
=#

function ImageFileActor(name::String, img_fns::Vector{String}, id=randstring(16); x=0, y=0, 
    frame_delays=[], anim=false, webp_path="", current_window=:primary, kv...)
    
    n = Int32.(length(img_fns))
    frame_delays = isempty(frame_delays) ? [ Millisecond(100) for _ in 1:n ] : frame_delays
    
    # Load images with error checking
    surfaces = []
    for fn in img_fns
        @debug "Loading image: $fn"
        surface = IMG_Load(fn)
        if surface == C_NULL
            error_msg = unsafe_string(SDL_GetError())
            error("Failed to load image $fn: $error_msg")
        end
        @debug "Successfully loaded surface for $fn"
        push!(surfaces, surface)
    end
    
    if isempty(surfaces)
        error("No surfaces were loaded for actor $name")
    end
    
    # Get dimensions from first surface
    surface = unsafe_load(surfaces[begin])
    w, h = Int32(surface.w), Int32(surface.h)
    @debug "Image loaded with dimensions: $(w)x$(h)"
    
    r = SDL_Rect(x, y, w, h)
    a = Actor(
        id,
        name,
        surfaces,
        [],
        r,
        [1.,1.],
        C_NULL,
        0,
        255,
        Dict(
            :anim => anim,
            :label => name,
            :img_fns => img_fns,
            :webp_path => webp_path,
            :sz => [w, h],
            :fade_in => false,
            :fade_out => false,
            :spin => false,
            :spin_cw => true,
            :shake => false,
            :then => now(),
            :next_frame => false,
            :frame_delays => frame_delays,
            :mouse_offset => Int32[0, 0],
            :type => "imagefile",
            :current_window => current_window,
        )
    )

    for (k, v) in kv
        setproperty!(a, k, v)
    end
    
    @debug "Created ImageFileActor: $name with id: $id"
    return a
end

function draw(a::Actor, screens::GameScreens=game[].screens)
    # Debug logging
    @debug "Drawing actor $(a.label) on window $(a.current_window)"
    @debug "Actor position: ($(a.x), $(a.y))"
    
    # Determine which screen to draw on based on actor's current_window
    screen = a.current_window == :primary ? screens.primary : screens.secondary
    
    # Check if we need to recreate textures for the current renderer
    if !isempty(a.textures) && haskey(a.data, :last_renderer) && a.data[:last_renderer] !== screen.renderer
        @debug "Switching renderers - recreating textures"
        # Destroy old textures
        for tx in a.textures
            SDL_DestroyTexture(tx)
        end
        a.textures = []
        
        # Handle different actor types
        if haskey(a.data, :type) && a.data[:type] == "text"
            @debug "Recreating text surfaces"
            # Recreate text surfaces
            text_font = TTF_OpenFont(a.data[:font_path], a.data[:pt_size])
            outline_font = TTF_OpenFont(a.data[:font_path], a.data[:pt_size])
            
            if text_font == C_NULL || outline_font == C_NULL
                @error "Failed to load font: $(unsafe_string(SDL_GetError()))"
                return
            end
            
            fg = TTF_RenderText_Blended_Wrapped(
                text_font, 
                a.label, 
                SDL_Color(a.data[:font_color]...), 
                UInt32(a.data[:wrap_length])
            )
            
            if fg == C_NULL
                @error "Failed to render text surface: $(unsafe_string(SDL_GetError()))"
                return
            end
            
            surface = if a.data[:outline_size] > 0
                TTF_SetFontOutline(outline_font, Int32(a.data[:outline_size]))
                bg = TTF_RenderText_Blended_Wrapped(
                    outline_font, 
                    a.label, 
                    SDL_Color(a.data[:outline_color]...), 
                    UInt32(a.data[:wrap_length])
                )
                SDL_UpperBlitScaled(fg, C_NULL, bg, Int32[a.data[:outline_size], a.data[:outline_size], a.w, a.h])
                bg
            else
                fg
            end
            
            push!(a.surfaces, surface)
            TTF_CloseFont(text_font)
            TTF_CloseFont(outline_font)
            
        elseif haskey(a.data, :img_fns)
            # Handle image-based actors
            @debug "Reloading surfaces from image files"
            a.surfaces = []
            for fn in a.data[:img_fns]
                surface = IMG_Load(fn)
                if surface == C_NULL
                    error_msg = unsafe_string(SDL_GetError())
                    @error "Failed to reload image $fn: $error_msg"
                    continue
                end
                push!(a.surfaces, surface)
            end
        end
    end
    
    if isempty(a.textures)
        @debug "Creating textures for actor $(a.label)"
        for (i, sf) in enumerate(a.surfaces)
            if sf == C_NULL
                @error "Surface $i is NULL for actor $(a.label)"
                continue
            end
            
            tx = SDL_CreateTextureFromSurface(screen.renderer, sf)
            if tx == C_NULL
                error_msg = unsafe_string(SDL_GetError())
                @error "Failed to create texture $i for $(a.label): $error_msg"
                continue
            end
            push!(a.textures, tx)
            @debug "Successfully created texture $i for $(a.label)"
        end
        
        # Store the renderer we created the textures with
        a.data[:last_renderer] = screen.renderer
        
        for sf in a.surfaces
            SDL_FreeSurface(sf)
            sf=nothing
        end
        a.surfaces = []
    end

    if isempty(a.textures)
        @error "No valid textures for actor $(a.label)"
        return
    end

    @debug "Setting up rendering for $(a.label) with $(length(a.textures)) textures"
    
    if a.alpha < 255
        SDL_SetTextureBlendMode(a.textures[begin], SDL_BLENDMODE_BLEND)
        SDL_SetTextureAlphaMod(a.textures[begin], a.alpha)
    end

    local flip = if a.w < 0 && a.h < 0
        SDL_FLIP_BOTH
    elseif a.h < 0
        SDL_FLIP_VERTICAL
    elseif a.w < 0
        SDL_FLIP_HORIZONTAL
    else
        SDL_FLIP_NONE
    end

    # Draw on the appropriate screen
    result = SDL_RenderCopyEx(
        screen.renderer,
        a.textures[begin],
        C_NULL,
        Ref(SDL_Rect(Int32[a.x, a.y, ceil(a.w * a.scale[1]), ceil(a.h * a.scale[2])]...)),
        a.angle,
        a.rotate_center,
        flip,
    )
    
    if result != 0
        error_msg = unsafe_string(SDL_GetError())
        @error "Failed to render actor $(a.label): $error_msg"
    else
        @debug "Successfully rendered actor $(a.label)"
    end
end

function Base.setproperty!(s::Actor, p::Symbol, x)
    
    if hasfield(Actor, p)
        setfield!(s, p, convert(fieldtype(Actor, p), x))
    else
        position = getfield(s, :position)
        v = getproperty(position, p)

        if v !== nothing
            setproperty!(position, p, x)

        else
            getfield(s, :data)[p] = x
        end
    end
end

function Base.getproperty(s::Actor, p::Symbol)
    if hasfield(Actor, p)
        getfield(s, p)

    else
        position = getfield(s, :position)
        v = getproperty(position, p)

        if v !== nothing
            return v
        else
            data = getfield(s, :data)

            if haskey(data, p)
                return data[p]
            else
                @warn "Unknown data $p requested from Actor($(s.label))"
                return nothing
            end
        end
    end
end

"""Angle to the horizontal, of the line between two actors, in degrees"""
function Base.angle(a::Actor, target::Actor)
    angle(a, a.pos...)
end

Base.angle(a::Actor, txy::Tuple) = angle(a, txy[1], txy[2])

"""Angle to the horizontal, of the line between an actor and a point in space, in degrees"""
function Base.angle(a::Actor, tx, ty)
    myx, myy = a.pos
    dx = tx - myx
    dy = myy - ty
    return deg2rad(atan(dy/dx))
end

"""Distance in pixels between two actors"""
function distance(a::Actor, target::Actor)
    distance(a, target.pos...)
end

"""Distance in pixels between an actor and a point in space"""
function distance(a::Actor, tx, ty)
    myx, myy = a.pos
    dx = tx - myx
    dy = ty - myy
    return sqrt(dx * dx + dy * dy)
end

atan2(y, x) = pi - pi/2 * (1 + sign(x)) * (1 - sign(y^2)) - pi/4 * (2 + sign(x)) * sign(y) -
                            sign(x*y) * atan((abs(x) - abs(y)) / (abs(x) + abs(y)))


function Base.size(s::Ptr{SDL_Surface})
    ss = unsafe_load(s)
    (ss.w, ss.h)
end

function collide(a, x::Integer, y::Integer)
    a=rect(a)
    a.x <= x < (a.x + a.w) && a.y <= y < (a.y + a.h)
end

collide(a, pos::Tuple) = collide(a, pos[1], pos[2])

function collide(c, d)
    a=rect(c)
    b=rect(d)

    return a.x < b.x + b.w &&
        a.y < b.y + b.h &&
        a.x + a.w > b.x &&
        a.y + a.h > b.y
end

rect(a::Actor) = a.position

function handle_mouse_motion!(game_state, evt, screens::GameScreens)
    if game_state.dragging_actor !== nothing
        x, y = Int(evt.motion.x), Int(evt.motion.y)
        actor = game_state.dragging_actor
        
        # Update actor position
        actor.x = x - game_state.drag_offset_x
        actor.y = y - game_state.drag_offset_y
        
        # Check if we've dragged to window edge and switch windows if needed
        if screens.active_screen == :primary && x >= screens.primary.width - 10
            actor.current_window = :secondary
            # Adjust position for new window
            actor.x = 0
        elseif screens.active_screen == :secondary && x <= 10
            actor.current_window = :primary
            # Adjust position for new window
            actor.x = screens.primary.width - 20
        end
    end
end