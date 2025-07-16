using CImGui
using FileIO, Colors
using ModernGL, GLFW
using ImageCore: permutedims, Array

CImGui.set_backend(:GlfwOpenGL3)
ctx = CImGui.CreateContext()
# enable docking and multi-viewport
io = CImGui.GetIO()
io.ConfigFlags = unsafe_load(io.ConfigFlags) | CImGui.ImGuiConfigFlags_DockingEnable
io.ConfigFlags = unsafe_load(io.ConfigFlags) | CImGui.ImGuiConfigFlags_ViewportsEnable


image_path = joinpath(@__DIR__, "images", "FireElem1","Visible0.png")
img = load(image_path)


img_rgba = Array(RGBA.(img))  # Ensure it's an Array
h, w = size(img_rgba)  # Julia: (height, width)
img_gl = permutedims(img_rgba, (2, 1))  # OpenGL expects (width, height)
img_data_gl_flat = vec(reinterpret(UInt8, img_gl))

image_id = Ref{Any}(nothing)


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