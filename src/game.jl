using .GameOne

# Modern Game structure
@kwdef mutable struct Game
    name::String="AnimatGame" * randstring(5)
    location::String=pwd()
    game_module::Union{Module, Nothing}=nothing
    screen::Union{Any, Nothing}=nothing
    keyboard::KeyState=KeyState()
    mouse::MouseState=MouseState()
    delta_time::Float32=0.0f0
    frame_count::Int64=0
    fps::Float32=0.0f0
    render::Union{Function, Nothing}=nothing
    update::Union{Function, Nothing}=nothing
    draw::Union{Function, Nothing}=nothing
    onkey::Union{Function, Nothing}=nothing
    onmousedown::Union{Function, Nothing}=nothing
    onmouseup::Union{Function, Nothing}=nothing
    onmousemove::Union{Function, Nothing}=nothing
    imgui::Union{Function, Nothing}=nothing
    imgui_settings::Union{Dict{String,Any}, Nothing}=nothing
    imgui_preinit::Union{Function, Nothing}=nothing
    state::Vector{Dict{String,Any}}=Vector{Dict{String,Any}}()
    socket::Vector{TCPSocket}=Vector{TCPSocket}()
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