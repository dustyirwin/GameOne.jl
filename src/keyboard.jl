
# Input handling
mutable struct KeyState
    keys::Dict{GLFW.Key, Bool}
    key_pressed::Dict{GLFW.Key, Bool}
    key_released::Dict{GLFW.Key, Bool}
    
    KeyState() = new(Dict{GLFW.Key, Bool}(), Dict{GLFW.Key, Bool}(), Dict{GLFW.Key, Bool}())
end

mutable struct MouseState
    position::Vec2f
    delta::Vec2f
    buttons::Dict{GLFW.MouseButton, Bool}
    button_pressed::Dict{GLFW.MouseButton, Bool}
    button_released::Dict{GLFW.MouseButton, Bool}
    scroll::Vec2f
    
    MouseState() = new(Vec2f(0), Vec2f(0), Dict{GLFW.MouseButton, Bool}(), 
                      Dict{GLFW.MouseButton, Bool}(), Dict{GLFW.MouseButton, Bool}(), Vec2f(0))
end
