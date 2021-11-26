module MouseButtons
export MouseButton
@enum MouseButton::UInt8 begin
    LEFT = 1
    MIDDLE = 2
    RIGHT = 3
    WHEEL_UP = 4
    WHEEL_DOWN = 5
end
end

module Keys
import SimpleDirectMediaLayer
const SDL2 = SimpleDirectMediaLayer.LibSDL2
export Key
@enum Key::UInt32 begin
    UNKNOWN = SDL2.SDLK_UNKNOWN |> UInt32;
    BACKSPACE = SDL2.SDLK_BACKSPACE |> UInt32;
    TAB = SDL2.SDLK_TAB |> UInt32;
    CLEAR = SDL2.SDLK_CLEAR |> UInt32;
    RETURN = SDL2.SDLK_RETURN |> UInt32;
    PAUSE = SDL2.SDLK_PAUSE |> UInt32;
    ESCAPE = SDL2.SDLK_ESCAPE |> UInt32;
    SPACE = SDL2.SDLK_SPACE |> UInt32;
    EXCLAIM = SDL2.SDLK_EXCLAIM |> UInt32;
    QUOTEDBL = SDL2.SDLK_QUOTEDBL |> UInt32;
    HASH = SDL2.SDLK_HASH |> UInt32;
    DOLLAR = SDL2.SDLK_DOLLAR |> UInt32;
    AMPERSAND = SDL2.SDLK_AMPERSAND |> UInt32;
    QUOTE = SDL2.SDLK_QUOTE |> UInt32;
    LEFTPAREN = SDL2.SDLK_LEFTPAREN |> UInt32;
    RIGHTPAREN = SDL2.SDLK_RIGHTPAREN |> UInt32;
    ASTERISK = SDL2.SDLK_ASTERISK |> UInt32;
    PLUS = SDL2.SDLK_PLUS |> UInt32;
    COMMA = SDL2.SDLK_COMMA |> UInt32;
    MINUS = SDL2.SDLK_MINUS |> UInt32;
    PERIOD = SDL2.SDLK_PERIOD |> UInt32;
    SLASH = SDL2.SDLK_SLASH |> UInt32;
    K_0 = SDL2.SDLK_0 |> UInt32;
    K_1 = SDL2.SDLK_1 |> UInt32;
    K_2 = SDL2.SDLK_2 |> UInt32;
    K_3 = SDL2.SDLK_3 |> UInt32;
    K_4 = SDL2.SDLK_4 |> UInt32;
    K_5 = SDL2.SDLK_5 |> UInt32;
    K_6 = SDL2.SDLK_6 |> UInt32;
    K_7 = SDL2.SDLK_7 |> UInt32;
    K_8 = SDL2.SDLK_8 |> UInt32;
    K_9 = SDL2.SDLK_9 |> UInt32;
    COLON = SDL2.SDLK_COLON |> UInt32;
    SEMICOLON = SDL2.SDLK_SEMICOLON |> UInt32;
    LESS = SDL2.SDLK_LESS |> UInt32;
    EQUALS = SDL2.SDLK_EQUALS |> UInt32;
    GREATER = SDL2.SDLK_GREATER |> UInt32;
    QUESTION = SDL2.SDLK_QUESTION |> UInt32;
    AT = SDL2.SDLK_AT |> UInt32;
    LEFTBRACKET = SDL2.SDLK_LEFTBRACKET |> UInt32;
    BACKSLASH = SDL2.SDLK_BACKSLASH |> UInt32;
    RIGHTBRACKET = SDL2.SDLK_RIGHTBRACKET |> UInt32;
    CARET = SDL2.SDLK_CARET |> UInt32;
    UNDERSCORE = SDL2.SDLK_UNDERSCORE |> UInt32;
    BACKQUOTE = SDL2.SDLK_BACKQUOTE |> UInt32;
    A = SDL2.SDLK_a |> UInt32;
    B = SDL2.SDLK_b |> UInt32;
    C = SDL2.SDLK_c |> UInt32;
    D = SDL2.SDLK_d |> UInt32;
    E = SDL2.SDLK_e |> UInt32;
    F = SDL2.SDLK_f |> UInt32;
    G = SDL2.SDLK_g |> UInt32;
    H = SDL2.SDLK_h |> UInt32;
    I = SDL2.SDLK_i |> UInt32;
    J = SDL2.SDLK_j |> UInt32;
    K = SDL2.SDLK_k |> UInt32;
    L = SDL2.SDLK_l |> UInt32;
    M = SDL2.SDLK_m |> UInt32;
    N = SDL2.SDLK_n |> UInt32;
    O = SDL2.SDLK_o |> UInt32;
    P = SDL2.SDLK_p |> UInt32;
    Q = SDL2.SDLK_q |> UInt32;
    R = SDL2.SDLK_r |> UInt32;
    S = SDL2.SDLK_s |> UInt32;
    T = SDL2.SDLK_t |> UInt32;
    U = SDL2.SDLK_u |> UInt32;
    V = SDL2.SDLK_v |> UInt32;
    W = SDL2.SDLK_w |> UInt32;
    X = SDL2.SDLK_x |> UInt32;
    Y = SDL2.SDLK_y |> UInt32;
    Z = SDL2.SDLK_z |> UInt32;
    DELETE = SDL2.SDLK_DELETE |> UInt32;
    KP0 = SDL2.SDLK_KP_0 |> UInt32;
    KP1 = SDL2.SDLK_KP_1 |> UInt32;
    KP2 = SDL2.SDLK_KP_2 |> UInt32;
    KP3 = SDL2.SDLK_KP_3 |> UInt32;
    KP4 = SDL2.SDLK_KP_4 |> UInt32;
    KP5 = SDL2.SDLK_KP_5 |> UInt32;
    KP6 = SDL2.SDLK_KP_6 |> UInt32;
    KP7 = SDL2.SDLK_KP_7 |> UInt32;
    KP8 = SDL2.SDLK_KP_8 |> UInt32;
    KP9 = SDL2.SDLK_KP_9 |> UInt32;
    KP_PERIOD = SDL2.SDLK_KP_PERIOD |> UInt32;
    KP_DIVIDE = SDL2.SDLK_KP_DIVIDE |> UInt32;
    KP_MULTIPLY = SDL2.SDLK_KP_MULTIPLY |> UInt32;
    KP_MINUS = SDL2.SDLK_KP_MINUS |> UInt32;
    KP_PLUS = SDL2.SDLK_KP_PLUS |> UInt32;
    KP_ENTER = SDL2.SDLK_KP_ENTER |> UInt32;
    KP_EQUALS = SDL2.SDLK_KP_EQUALS |> UInt32;
    UP = SDL2.SDLK_UP |> UInt32;
    DOWN = SDL2.SDLK_DOWN |> UInt32;
    RIGHT = SDL2.SDLK_RIGHT |> UInt32;
    LEFT = SDL2.SDLK_LEFT |> UInt32;
    INSERT = SDL2.SDLK_INSERT |> UInt32;
    HOME = SDL2.SDLK_HOME |> UInt32;
    END = SDL2.SDLK_END |> UInt32;
    PAGEUP = SDL2.SDLK_PAGEUP |> UInt32;
    PAGEDOWN = SDL2.SDLK_PAGEDOWN |> UInt32;
    F1 = SDL2.SDLK_F1 |> UInt32;
    F2 = SDL2.SDLK_F2 |> UInt32;
    F3 = SDL2.SDLK_F3 |> UInt32;
    F4 = SDL2.SDLK_F4 |> UInt32;
    F5 = SDL2.SDLK_F5 |> UInt32;
    F6 = SDL2.SDLK_F6 |> UInt32;
    F7 = SDL2.SDLK_F7 |> UInt32;
    F8 = SDL2.SDLK_F8 |> UInt32;
    F9 = SDL2.SDLK_F9 |> UInt32;
    F10 = SDL2.SDLK_F10 |> UInt32;
    F11 = SDL2.SDLK_F11 |> UInt32;
    F12 = SDL2.SDLK_F12 |> UInt32;
    F13 = SDL2.SDLK_F13 |> UInt32;
    F14 = SDL2.SDLK_F14 |> UInt32;
    F15 = SDL2.SDLK_F15 |> UInt32;
    NUMLOCK = SDL2.SDLK_NUMLOCKCLEAR |> UInt32;
    CAPSLOCK = SDL2.SDLK_CAPSLOCK |> UInt32;
    SCROLLOCK = SDL2.SDLK_SCROLLLOCK |> UInt32;
    RSHIFT = SDL2.SDLK_RSHIFT |> UInt32;
    LSHIFT = SDL2.SDLK_LSHIFT |> UInt32;
    RCTRL = SDL2.SDLK_RCTRL |> UInt32;
    LCTRL = SDL2.SDLK_LCTRL |> UInt32;
    RALT = SDL2.SDLK_RALT |> UInt32;
    LALT = SDL2.SDLK_LALT |> UInt32;
    # RMETA = SDL2.SDLK_RGUI |> UInt32;
    # LMETA = SDL2.SDLK_LGUI |> UInt32;
    # LSUPER = SDL2.SDLK_LGUI |> UInt32;
    # RSUPER = SDL2.SDLK_RGUI |> UInt32;
    MODE = SDL2.SDLK_MODE |> UInt32;
    HELP = SDL2.SDLK_HELP |> UInt32;
    SYSREQ = SDL2.SDLK_SYSREQ |> UInt32;
    MENU = SDL2.SDLK_MENU |> UInt32;
    POWER = SDL2.SDLK_POWER |> UInt32;
    EURO = SDL2.SDLK_CURRENCYUNIT |> UInt32;
end
end

module Keymods
export Keymod
@enum Keymod::UInt16 begin
    NONE = 0
    LSHIFT = 1
    RSHIFT = 2
    LCTRL = 64
    RCTRL = 128
    LALT = 256
    RALT = 512
    LMETA = 1024
    RMETA = 2048
    NUM = 4096
    CAPS = 8192
    MODE = 16384
    CTRL = 192
    SHIFT = 3
    ALT = 768
    META = 3072
end
end

using .MouseButtons
using .Keys
using .Keymods

struct Keyboard
    pressed::Array{UInt32, 1}
end

Keyboard() = Keyboard(Array{Any, 1}())

function Base.getproperty(k::Keyboard, s::Symbol)
    s = Symbol(uppercase(string(s)))

    if isdefined(GameOne.Keys, s)
        UInt32(getfield(GameOne.Keys, s)) in getfield(k, :pressed)
    end

    if isdefined(GameOne.Keymods, s)
        UInt32(getfield(GameOne.Keymods, s)) in getfield(k, :pressed)
    end

    false
end

Base.push!(k::Keyboard, item) = push!(getfield(k, :pressed), item)

function Base.delete!(k::Keyboard, item)
    a = getfield(k, :pressed)
    deleteat!(a, a.==item)
end
