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

function load_animation_frames(folder)
    files = sort(readdir(folder; join=true))
    frames = [begin
        img = load(f)
        arr = try
            Array(RGBA.(img))
        catch
            # Fallback: flatten and reshape using axes
            ax = axes(img)
            reshape(collect(img), map(length, ax)...)
        end
        if eltype(arr) <: Colors.RGBA
            arr
        elseif eltype(arr) <: Colors.RGB
            RGBA.(arr)
        elseif ndims(arr) == 2
            RGBA.(arr, arr, arr, 1)
        elseif ndims(arr) == 3 && size(arr,3) == 3
            RGBA.(arr[:,:,1], arr[:,:,2], arr[:,:,3], 1)
        elseif ndims(arr) == 3 && size(arr,3) == 4
            RGBA.(arr[:,:,1], arr[:,:,2], arr[:,:,3], arr[:,:,4])
        else
            error("Unsupported image format")
        end
    end for f in files]
    @assert all(size(f) == size(frames[1]) for f in frames)
    return frames
end

anim_folder = joinpath(@__DIR__, "images", "FireElem1")
frames = load_animation_frames(anim_folder)
frame_count = length(frames)
h, w = size(frames[1])
current_frame = Ref(1)
last_time = Ref(time())
frame_delay = 1/12  # 12 FPS
anim_image_id = Ref{Any}(nothing)

CImGui.render(ctx) do
    # Animation timing
    now = time()
    if now - last_time[] > frame_delay
        current_frame[] = current_frame[] % frame_count + 1
        last_time[] = now
    end

    frame = frames[current_frame[]]
    frame_gl = permutedims(frame, (2,1))
    frame_flat = vec(reinterpret(UInt8, frame_gl))

    if anim_image_id[] === nothing
        anim_image_id[] = CImGui.create_image_texture(w, h)
    end
    CImGui.update_image_texture(anim_image_id[], frame_flat, w, h)

    if CImGui.Begin("Animation")
        CImGui.Image(anim_image_id[], CImGui.ImVec2(w, h))
        CImGui.End()
    end
end