using CImGui
using FileIO, Colors
using ImageCore: load, permutedims, Array
using ModernGL, GLFW

CImGui.set_backend(:GlfwOpenGL3)
ctx = CImGui.CreateContext()

image_id = Ref{Any}(nothing)
image_path = joinpath(@__DIR__, "images", "alien.png")

img = load(image_path)
img_rgba = Array(img)  # Already RGBA, just ensure Array

img_h, img_w = size(img_rgba)  # Julia: (height, width)
img_gl = permutedims(img_rgba, (2, 1))  # (width, height)
img_data_gl_flat = vec(reinterpret(UInt8, img_gl))

CImGui.render(ctx) do
    if image_id[] === nothing
        image_id[] = CImGui.create_image_texture(img_w, img_h)
    end
    CImGui.update_image_texture(image_id[], img_data_gl_flat, img_w, img_h)
    if CImGui.Begin("Image Window")
        CImGui.Image(image_id[], CImGui.ImVec2(img_w, img_h))
        CImGui.End()
    end
end