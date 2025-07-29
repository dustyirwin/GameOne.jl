using .GameOne

# Modern Game structure
mutable struct Game
    name::String
    location::String
    game_module::Module
    screen::Union{Any, Nothing}
    keyboard::KeyState
    mouse::MouseState
    delta_time::Float32
    frame_count::Int64
    fps::Float32
    render::Union{Function, Nothing}
    update::Function
    onkey::Union{Function, Nothing}
    onmousedown::Union{Function, Nothing}
    onmouseup::Union{Function, Nothing}
    onmousemove::Union{Function, Nothing}
    imgui::Union{Function, Nothing}
    imgui_settings::Union{Dict{String,Any}, Nothing}
    imgui_preinit::Union{Function, Nothing}
    state::Vector{Dict{String,Any}}
    socket::Vector{TCPSocket}
end

# Game constants
const timer = WallTimer()
const game = Ref{Game}()
const playing = Ref{Bool}(false)
const paused = Ref{Bool}(false)
const window_paused = Ref{Int32}(0)

# Hot-reloading shader cache
const SHADER_CACHE = Dict{String, Shader}()
const SHADER_WATCH_LIST = Set{String}()

struct QuitException <: Exception end

function imgui_preinit(ctx::Ptr{CImGui.ImGuiContext})
    # Ensure ImGui context exists
    if ctx == C_NULL
        @error "ImGui context is null in imgui_preinit"
        return
    end
    io = CImGui.GetIO()
    io.ConfigFlags = unsafe_load(io.ConfigFlags) | CImGui.ImGuiConfigFlags_DockingEnable
    io.ConfigFlags = unsafe_load(io.ConfigFlags) | CImGui.ImGuiConfigFlags_ViewportsEnable

    style = Ptr{CImGui.ImGuiStyle}(CImGui.GetStyle())
    if unsafe_load(io.ConfigFlags) & CImGui.ImGuiConfigFlags_ViewportsEnable == CImGui.ImGuiConfigFlags_ViewportsEnable
        style.WindowRounding = 5.0f0
        col = CImGui.c_get(style.Colors, CImGui.ImGuiCol_WindowBg)
        CImGui.c_set!(style.Colors, CImGui.ImGuiCol_WindowBg, CImGui.ImVec4(col.x, col.y, col.z, 1.0f0))
    end
end