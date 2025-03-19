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
    current_screen::UInt32  # 1 for primary, 2 for secondary
    z::Int32

    # Add constructor with type conversions
    function Actor(id::String, label::String, surfaces, textures, position::SDL_Rect, 
                  scale::Vector, rotate_center, angle::Number, alpha::Number, 
                  data::Dict{Symbol,Any}, current_screen=UInt32(1), z::Int32=Int32(0))
        new(id, label, surfaces, textures, position, 
            convert(Vector{Float32}, scale), 
            rotate_center,
            convert(Float64, angle),
            convert(UInt8, alpha),
            data, 
            current_screen, 
            z)
    end
end

function TextActor(text::String, font_path::String; id=randstring(10), x = 0, y = 0, pt_size = 24,
    font_color = Int[255, 255, 255, 255], outline_color = Int[0, 0, 0, 225],
    wrap_length = 800, outline_size = 0, current_screen=UInt32(1), kv...)

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
            :current_screen => current_screen,
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

# future image loading optimizations:
# - use a texture manager to cache textures
# - use a texture atlas for multiple images
function ImageMemActor(img_name::String, img; x=0, y=0, kv...)
    # Convert image to ARGB format
    img = ARGB.(img)
    w, h = Int32.(size(img))
    
    # Create a copy of the image data to avoid referencing the input array
    img_copy = copy(img)
    
    # Create SDL surface from the copied image data
    sf = SDL_CreateRGBSurfaceWithFormatFrom(
        img_copy,
        w,
        h,
        Int32(32),
        Int32(4w),
        SDL_PIXELFORMAT_ARGB32,
    )

    # Check if surface creation failed
    if sf == C_NULL
        error_msg = unsafe_string(SDL_GetError())
        error("Failed to create surface: $error_msg")
    end

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
            :label => img_name,
            :sz => [w,h],
            :mouse_offset => Int32[0,0],
            :type => "imagemem",
            # Store a finalizer function to clean up the surface
            :cleanup => () -> begin
                if sf != C_NULL
                    SDL_FreeSurface(sf)
                end
            end
        )
    )

    # Register finalizer to ensure cleanup when actor is garbage collected
    finalizer(a) do x
        if haskey(x.data, :cleanup)
            x.data[:cleanup]()
        end
    end

    for (k, v) in kv
        setproperty!(a, k, v)
    end
    
    return a
end

function ImageFileActor(name::String, img_fns::Vector{String}, id=randstring(16); x=0, y=0, 
    frame_delays=[], anim=false, webp_path="", current_screen=UInt32(1), kv...)
    
    @debug "Creating ImageFileActor '$name' with $(length(img_fns)) frames"
    
    # Validate input paths
    for path in img_fns
        if !isfile(path)
            error("Image file not found: $path")
        end
    end
    
    n = Int32.(length(img_fns))
    frame_delays = isempty(frame_delays) ? [ Millisecond(100) for _ in 1:n ] : frame_delays
    
    # Register the animation with the texture manager using the actor's name
    if isempty(webp_path)
        register_animation(TEXTURE_MANAGER, name, img_fns)
    else
        register_animation(TEXTURE_MANAGER, name, readdir(webp_path))
    end
    
    # Load first frame to get dimensions
    @debug "Loading first frame to get dimensions: $(img_fns[1])"
    surface = IMG_Load(img_fns[1])
    if surface == C_NULL
        error("Failed to load image $(img_fns[1]): $(unsafe_string(SDL_GetError()))")
    end
    
    # Get dimensions from first surface
    surface_data = unsafe_load(surface)
    w, h = Int32(surface_data.w), Int32(surface_data.h)
    SDL_FreeSurface(surface)
    @debug "Image dimensions: $(w)x$(h)"
    
    r = SDL_Rect(x, y, w, h)
    a = Actor(
        id,
        name,
        nothing,  # No surfaces stored directly
        nothing,  # No textures stored directly
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
            :current_screen => current_screen,
            :animation_name => name  # Use the actor's name consistently for animation
        )
    )

    for (k, v) in kv
        setproperty!(a, k, v)
    end
    
    # Store reference to game screens for cleanup
    screens_ref = Ref{Union{GameScreens, Nothing}}(nothing)
    
    # Register finalizer to clean up resources
    finalizer(a) do x
        @debug "Cleaning up resources for actor $(x.id)"
        if screens_ref[] !== nothing
            renderers = [
                screens_ref[].primary.renderer,
                screens_ref[].secondary.renderer
            ]
            cleanup_actor_resources(TEXTURE_MANAGER, x.id, renderers)
            for fn in x.data[:img_fns]
                for renderer in renderers
                    release_texture(TEXTURE_MANAGER, renderer, fn)
                end
            end
        end
    end
    
    # Update screens reference when game is initialized
    schedule_once(() -> begin
        screens_ref[] = game[].screens
    end, 0.0)
    
    @debug "Successfully created ImageFileActor: $name with id: $id"
    return a
end

function next_frame!(a::Actor)
    @debug "Advancing frame for actor $(a.label) (id: $(a.id))"
    
    if haskey(a.data, :animation_name)
        @debug "Using texture manager animation system"
        advance_animation_frame(TEXTURE_MANAGER, a.id, a.data[:animation_name])
        a.data[:then] = now()
    else
        @debug "Actor $(a.label) has no animation_name"
    end
    
    return a
end

function draw(screens::GameScreens, a::Actor; kv...)
    @debug "Drawing actor $(a.label) (id: $(a.id)) on screen $(a.current_screen)"
    
    # Determine which screen to draw on based on actor's current_screen
    screen = a.current_screen == 1 ? screens.primary : screens.secondary
    
    # Get the current texture
    local texture
    if haskey(a.data, :animation_name) && a.data[:anim]  # Only use animation system if :anim is true
        # Animated actor using texture manager
        @debug "Getting texture for animated actor $(a.label) on renderer $(screen.renderer)"
        texture = get_animation_frame(TEXTURE_MANAGER, screen.renderer, a.id, a.data[:animation_name])
    elseif haskey(a.data, :type) && a.data[:type] == "imagefile"
        # Single image actor using texture manager
        @debug "Getting texture for single image actor $(a.label) on renderer $(screen.renderer)"
        path = a.data[:img_fns][1]
        texture = get_or_load_texture(TEXTURE_MANAGER, screen.renderer, path)
    else
        # Legacy non-animated actors
        @debug "Handling legacy actor $(a.label)"
        if isempty(a.textures)
            if a.surfaces === nothing || isempty(a.surfaces)
                @error "No surfaces available for actor $(a.label)"
                return
            end
            
            @debug "Creating texture for legacy actor $(a.label)"
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
                @debug "Created texture $i for legacy actor $(a.label)"
            end
            
            for sf in a.surfaces
                SDL_FreeSurface(sf)
            end
            a.surfaces = []
        end
        
        if isempty(a.textures)
            @error "No valid textures for actor $(a.label)"
            return
        end
        
        texture = a.textures[begin]
    end
    
    if texture == C_NULL
        @error "Invalid texture for actor $(a.label)"
        return
    end
    
    @debug "Setting up rendering for $(a.label) on renderer $(screen.renderer)"
    
    if a.alpha < 255
        SDL_SetTextureBlendMode(texture, SDL_BLENDMODE_BLEND)
        SDL_SetTextureAlphaMod(texture, a.alpha)
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
        texture,
        C_NULL,
        Ref(SDL_Rect(Int32[a.x, a.y, ceil(Int32(abs(a.w)) * a.scale[1]), ceil(Int32(abs(a.h)) * a.scale[2])]...)),
        a.angle,
        a.rotate_center,
        flip,
    )
    
    if result != 0
        error_msg = unsafe_string(SDL_GetError())
        @error "Failed to render actor $(a.label): $error_msg"
    else
        @debug "Successfully rendered actor $(a.label) on renderer $(screen.renderer)"
    end
end

# custom Rect draw function (for 2px card border)
function draw(screens::GameScreens, r::Rect; fill=true, c::Colorant=colorant"violet")
    screen = r.current_screen == 1 ? screens.primary : screens.secondary
    draw(screen, r, c=c, fill=fill)
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

# Texture management system
mutable struct TextureManager
    # Map from (renderer_ptr, image_path) to SDL texture pointer
    textures::Dict{Tuple{Ptr{SDL2.SDL_Renderer}, String}, Ptr{SDL_Texture}}
    # Map from (renderer_ptr, image_path) to reference count
    ref_counts::Dict{Tuple{Ptr{SDL2.SDL_Renderer}, String}, Int}
    # Map from animation name to array of texture paths
    animations::Dict{String, Vector{String}}
    # Map from animation name to current frame index for each actor
    frame_indices::Dict{Tuple{String, String}, Int}  # (actor_id, anim_name) => current_frame
    
    TextureManager() = new(Dict(), Dict(), Dict(), Dict())
end

# Global texture manager instance
const TEXTURE_MANAGER = TextureManager()

function get_or_load_texture(manager::TextureManager, renderer::Ptr{SDL2.SDL_Renderer}, path::String)::Ptr{SDL_Texture}
    @debug "get_or_load_texture called for path: $path with renderer: $renderer"
    
    key = (renderer, path)
    if haskey(manager.textures, key)
        @debug "Found existing texture for $path on renderer $renderer"
        manager.ref_counts[key] += 1
        return manager.textures[key]
    end
    
    @debug "Loading new texture for $path on renderer $renderer"
    if !isfile(path)
        error("Image file not found: $path")
    end
    
    surface = IMG_Load(path)
    if surface == C_NULL
        error("Failed to load image $path: $(unsafe_string(SDL_GetError()))")
    end
    
    @debug "Created surface for $path"
    
    # Create texture for this specific renderer
    texture = SDL_CreateTextureFromSurface(renderer, surface)
    SDL_FreeSurface(surface)
    
    if texture == C_NULL
        error("Failed to create texture from $path: $(unsafe_string(SDL_GetError()))")
    end
    
    # Set texture blend mode
    SDL_SetTextureBlendMode(texture, SDL_BLENDMODE_BLEND)
    
    @debug "Successfully created texture for $path on renderer $renderer"
    
    manager.textures[key] = texture
    manager.ref_counts[key] = 1
    return texture
end

function register_animation(manager::TextureManager, name::String, frame_paths::Vector{String})
    @debug "Registering animation '$name' with $(length(frame_paths)) frames"
    manager.animations[name] = frame_paths
end

function get_animation_frame(manager::TextureManager, renderer::Ptr{SDL2.SDL_Renderer}, actor_id::String, anim_name::String)::Ptr{SDL2.SDL_Texture}
    @debug "Getting animation frame for actor $actor_id, animation $anim_name"
    
    if !haskey(manager.animations, anim_name)
        error("Animation '$anim_name' not found in texture manager")
    end
    
    frame_paths = manager.animations[anim_name]
    key = (actor_id, anim_name)
    
    if !haskey(manager.frame_indices, key)
        @debug "Initializing frame index for actor $actor_id, animation $anim_name"
        manager.frame_indices[key] = 1
    end
    
    current_frame = manager.frame_indices[key]
    path = frame_paths[current_frame]
    
    @debug "Using frame $current_frame (path: $path) for actor $actor_id"
    return get_or_load_texture(manager, renderer, path)
end

function advance_animation_frame(manager::TextureManager, actor_id::String, anim_name::String)
    @debug "Advancing animation frame for actor $actor_id, animation $anim_name"
    
    key = (actor_id, anim_name)
    if haskey(manager.frame_indices, key)
        frame_paths = manager.animations[anim_name]
        current_frame = manager.frame_indices[key]
        next_frame = mod1(current_frame + 1, length(frame_paths))
        manager.frame_indices[key] = next_frame
        @debug "Advanced from frame $current_frame to $next_frame"
    else
        @warn "No frame index found for actor $actor_id, animation $anim_name"
    end
end

function release_texture(manager::TextureManager, renderer::Ptr{SDL2.SDL_Renderer}, path::String)
    key = (renderer, path)
    if haskey(manager.ref_counts, key)
        manager.ref_counts[key] -= 1
        if manager.ref_counts[key] <= 0
            if haskey(manager.textures, key)
                SDL_DestroyTexture(manager.textures[key])
                delete!(manager.textures, key)
            end
            delete!(manager.ref_counts, key)
        end
    end
end

function cleanup_actor_resources(manager::TextureManager, actor_id::String, renderers::Vector{Ptr{SDL2.SDL_Renderer}})
    # Remove animation frame indices for this actor
    for key in keys(manager.frame_indices)
        if key[1] == actor_id
            delete!(manager.frame_indices, key)
        end
    end
    
    # Clean up textures for all renderers
    for renderer in renderers
        for (key, _) in manager.textures
            if key[1] == renderer
                release_texture(manager, renderer, key[2])
            end
        end
    end
end