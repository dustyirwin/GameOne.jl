using CImGui
using CImGui.lib
using CImGui.CSyntax
import GLFW
import ModernGL as GL
using Colors
using FileIO
using ImageIO
using ImageCore: channelview


# Set up the backend
CImGui.set_backend(:GlfwOpenGL3)

# Create ImGui context and enable docking/viewports
ctx = CImGui.CreateContext()
io = CImGui.GetIO()
io.ConfigFlags = unsafe_load(io.ConfigFlags) | CImGui.ImGuiConfigFlags_DockingEnable
io.ConfigFlags = unsafe_load(io.ConfigFlags) | CImGui.ImGuiConfigFlags_ViewportsEnable
CImGui.StyleColorsDark()
style = Ptr{CImGui.ImGuiStyle}(CImGui.GetStyle())
if unsafe_load(io.ConfigFlags) & CImGui.ImGuiConfigFlags_ViewportsEnable == CImGui.ImGuiConfigFlags_ViewportsEnable
    style.WindowRounding = 5.0f0
    col = CImGui.c_get(style.Colors, CImGui.ImGuiCol_WindowBg)
    CImGui.c_set!(style.Colors, CImGui.ImGuiCol_WindowBg, CImGui.ImVec4(col.x, col.y, col.z, 1.0f0))
end

# Load an image as a texture (replace with your image path)
img_width, img_height = 256, 256
image_id = Ref{Any}(nothing)
image_path = joinpath(@__DIR__,"images","alien.png")  # <-- set this to your image


# Use FileIO and ImageIO to load images as arrays

img = load(image_path)
@info "Loaded image" typeof=typeof(img) eltype=eltype(img) size=size(img)

if eltype(img) <: Colors.RGBA
    img_rgba = img
elseif ndims(img) == 2
    imgf = float.(img)
    img_rgba = RGBA{N0f8}.(imgf, imgf, imgf, 1)
elseif ndims(img) == 3 && size(img, 3) == 3
    imgf1 = float.(img[:,:,1])
    imgf2 = float.(img[:,:,2])
    imgf3 = float.(img[:,:,3])
    img_rgba = RGBA{N0f8}.(imgf1, imgf2, imgf3, 1)
elseif ndims(img) == 3 && size(img, 3) == 4
    imgf1 = float.(img[:,:,1])
    imgf2 = float.(img[:,:,2])
    imgf3 = float.(img[:,:,3])
    imgf4 = float.(img[:,:,4])
    img_rgba = RGBA{N0f8}.(imgf1, imgf2, imgf3, imgf4)
else
    error("Unsupported image format")
end


h, w = size(img_rgba)
@info "img_rgba shape" shape=size(img_rgba) eltype=eltype(img_rgba)

# Fix: flatten RGBA array in row-major order for OpenGL
img_data_gl = permutedims(img_rgba, (2,1))  # (w, h)
@info "img_data_gl shape" shape=size(img_data_gl)
@info "Texture dimensions" w=w h=h
img_data_gl_flat = vec(reinterpret(UInt32, img_data_gl))

 # Create the OpenGL texture
CImGui.render(ctx) do
    if image_id[] === nothing
        image_id[] = CImGui.create_image_texture(w, h)
    end
    CImGui.update_image_texture(image_id[], img_data_gl_flat, w, h)
    if CImGui.Begin("Image Window")
        CImGui.Image(image_id[], CImGui.ImVec2(w, h))
        CImGui.End()
    end
end