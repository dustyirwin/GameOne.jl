using ModernGL
using FileIO
using ImageIO
using Logging
using ImageCore
using libwebp_jll


# Ensure img is always HxWx4 Array{UInt8,3}
function prepare_image(img)
    # Convert to RGBA if needed
    if ndims(img) == 2
        img = colorview(RGBA, img, fill(1.0, size(img)))
    elseif size(img,3) == 3
        img = colorview(RGBA, img)
    end
    # Convert to UInt8 array, HxWx4
    img_u8 = permutedims(reinterpret(UInt8, reshape(img, :, size(img,2), size(img,3))), (2,1,3))
    return img_u8
end

# Upload a Julia array (HxWxC or HxW) as an OpenGL texture, with optional mipmaps and compression
function upload_texture(img; 
    internal_format=GL_RGBA, 
    format=GL_RGBA, 
    minfilter=GL_LINEAR_MIPMAP_LINEAR, 
    magfilter=GL_LINEAR, 
    mipmaps=true, 
    compress=false
    )
    img_u8 = prepare_image(img)
    h, w, c = size(img_u8)
    tex = Ref{GLuint}(0)
    glGenTextures(1, tex)
    glBindTexture(GL_TEXTURE_2D, tex[])

    # Choose compressed internal format if requested and supported
    if compress && has_gl_extension("GL_ARB_texture_compression")
        if has_gl_extension("GL_EXT_texture_compression_s3tc")
            internal_format = GL_COMPRESSED_RGBA_S3TC_DXT5_EXT
        elseif has_gl_extension("GL_EXT_texture_compression_rgtc")
            internal_format = GL_COMPRESSED_RGBA
        else
            @warn "No supported compression format found, using uncompressed RGBA"
            internal_format = GL_RGBA
        end
    end

    glTexImage2D(GL_TEXTURE_2D, 0, internal_format, w, h, 0, format, GL_UNSIGNED_BYTE, pointer(img_u8))
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, minfilter)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, magfilter)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)

    if mipmaps
        glGenerateMipmap(GL_TEXTURE_2D)
    end

    glBindTexture(GL_TEXTURE_2D, 0)
    return tex[]
end

# Load a static image file as an OpenGL texture
function load_texture(path::String; mipmaps=true, compress=false)
    img = load(path)
    texid = upload_texture(img; mipmaps=mipmaps, compress=compress)
    @debug "Loaded texture" path texid mipmaps compress
    return texid
end

# Load all frames of an animated webp/gif as OpenGL textures
function load_animated_textures(path::String; mipmaps=true, compress=false)
    # generating webp frames
    #process_webp(path)
    
    imgstack = if occursin("webp",lowercase(path))
    else
        load(path)
    end
    @show typeof(imgstack)
    @show size(imgstack)
    @show eltype(imgstack)
    if ndims(imgstack) == 4
        nframes = size(imgstack, 4)
        frames = Vector{GLuint}(undef, nframes)
        for i in 1:nframes
            frame = imgstack[:,:,:,i]
            frames[i] = upload_texture(frame; mipmaps=mipmaps, compress=compress)
        end
        return frames
    elseif ndims(imgstack) == 3
        return [upload_texture(imgstack; mipmaps=mipmaps, compress=compress)]
    else
        error("Unexpected image stack dimensions: $(size(imgstack))")
    end
end

# load an image into GL format
function load_gl_img(image_path::String)
    img = load(image_path)
    img_rgba = Array(RGBA.(img))  # Ensure it's an Array
    h, w = size(img_rgba)  # Julia: (height, width)
    img_gl = permutedims(img_rgba, (2, 1))  # OpenGL expects (width, height)
    img_data_gl_flat = vec(reinterpret(UInt8, img_gl))
    return img_data_gl_flat, Int32(w), Int32(h)
end

function draw_background(window, image_id)
    # Make sure the OpenGL context is current
    GLFW.MakeContextCurrent(window)
    # Get the window position and size
    wx, wy = GLFW.GetWindowPos(window)
    ww, wh = GLFW.GetWindowSize(window)
    # Draw the image to fill the window
    draw_list = CImGui.GetBackgroundDrawList()
    if image_id[] !== nothing
        CImGui.ImDrawList_AddImage(
            draw_list,
            image_id[],
            CImGui.ImVec2(wx, wy),              # Top-left corner of the window
            CImGui.ImVec2(wx + ww, wy + wh),    # Bottom-right corner of the window
            CImGui.ImVec2(0, 0),                 # Texture coordinates
            CImGui.ImVec2(1, 1),                 # UV coords
            CImGui.ImVec4(1.0, 1.0, 1.0, 1.0)
        )
    end
end

function draw_image(window, image_id, x, y, w, h, angle_degrees::Float32=0.0f0, alpha::Float32=1.0f0)
    """
    Draw an image, optionally rotated by angle_degrees (clockwise) around its center.
    When rotating, the original w/h are used for the image texture, but positioned in the x,y,w,h box.
    """
    # Make sure the OpenGL context is current
    GLFW.MakeContextCurrent(window)
    
    # Get the window position and size
    wx, wy = GLFW.GetWindowPos(window)

    # Draw the image on the background layer (behind ImGui windows)
    draw_list = CImGui.GetBackgroundDrawList()
    
    if image_id !== nothing && image_id isa Ref && image_id[] !== nothing
        if angle_degrees == 0.0f0
            # Fast path: normal unrotated drawing
            CImGui.ImDrawList_AddImage(
                draw_list,
                image_id[],
                CImGui.ImVec2(wx + x, wy + y),              # Top-left corner
                CImGui.ImVec2(wx + x + w, wy + y + h),      # Bottom-right corner
                CImGui.ImVec2(0, 0),                        # Texture coordinates
                CImGui.ImVec2(1, 1),                        # UV coords
                CImGui.ImVec4(1.0, 1.0, 1.0, alpha)         # R G B A
            )
        else
            # Rotated drawing using quad
            # For 90-degree rotation, we need to swap w/h for the actual texture dimensions
            # because a portrait card becomes landscape when rotated 90 degrees
            texture_w = angle_degrees == 90.0f0 || angle_degrees == -90.0f0 ? h : w
            texture_h = angle_degrees == 90.0f0 || angle_degrees == -90.0f0 ? w : h
            
            # Calculate center point of the image
            cx = wx + x + w / 2
            cy = wy + y + h / 2
            
            # Convert angle to radians
            angle_rad = deg2rad(angle_degrees)
            cos_a = cos(angle_rad)
            sin_a = sin(angle_rad)
            
            # Calculate the four corners using TEXTURE dimensions, relative to center
            hw = texture_w / 2
            hh = texture_h / 2
            
            # Original corners (relative to center)
            corners = [
                (-hw, -hh),  # Top-left
                (hw, -hh),   # Top-right
                (hw, hh),    # Bottom-right
                (-hw, hh)    # Bottom-left
            ]
            
            # Rotate corners around center
            rotated = map(corners) do (dx, dy)
                rx = dx * cos_a - dy * sin_a
                ry = dx * sin_a + dy * cos_a
                CImGui.ImVec2(cx + rx, cy + ry)
            end
            
            # UV coordinates for the four corners
            uv0 = CImGui.ImVec2(0, 0)  # Top-left
            uv1 = CImGui.ImVec2(1, 0)  # Top-right
            uv2 = CImGui.ImVec2(1, 1)  # Bottom-right
            uv3 = CImGui.ImVec2(0, 1)  # Bottom-left
            
            # Draw using quad
            color = CImGui.ImVec4(1.0, 1.0, 1.0, alpha)
            col32 = CImGui.ColorConvertFloat4ToU32(color)
            
            CImGui.ImDrawList_AddImageQuad(
                draw_list,
                image_id[],
                rotated[1], rotated[2], rotated[3], rotated[4],  # p1, p2, p3, p4
                uv0, uv1, uv2, uv3,                               # uv1, uv2, uv3, uv4
                col32
            )
        end
    end
end

export Texture, upload_texture, load_texture, load_animated_textures, load_gl_img
export prepare_image, draw_background, draw_image