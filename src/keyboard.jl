
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
    UNKNOWN = UInt32(SDL2.SDLK_UNKNOWN);
    BACKSPACE = UInt32(SDL2.SDLK_BACKSPACE);
    TAB = UInt32(SDL2.SDLK_TAB);
    CLEAR = UInt32(SDL2.SDLK_CLEAR);
    RETURN = UInt32(SDL2.SDLK_RETURN);
    PAUSE = UInt32(SDL2.SDLK_PAUSE);
    ESCAPE = UInt32(SDL2.SDLK_ESCAPE);
    SPACE = UInt32(SDL2.SDLK_SPACE);
    EXCLAIM = UInt32(SDL2.SDLK_EXCLAIM);
    QUOTEDBL = UInt32(SDL2.SDLK_QUOTEDBL);
    HASH = UInt32(SDL2.SDLK_HASH);
    DOLLAR = UInt32(SDL2.SDLK_DOLLAR);
    AMPERSAND = UInt32(SDL2.SDLK_AMPERSAND);
    QUOTE = UInt32(SDL2.SDLK_QUOTE);
    LEFTPAREN = UInt32(SDL2.SDLK_LEFTPAREN);
    RIGHTPAREN = UInt32(SDL2.SDLK_RIGHTPAREN);
    ASTERISK = UInt32(SDL2.SDLK_ASTERISK);
    PLUS = UInt32(SDL2.SDLK_PLUS);
    COMMA = UInt32(SDL2.SDLK_COMMA);
    MINUS = UInt32(SDL2.SDLK_MINUS);
    PERIOD = UInt32(SDL2.SDLK_PERIOD);
    SLASH = UInt32(SDL2.SDLK_SLASH);
    K_0 = UInt32(SDL2.SDLK_0);
    K_1 = UInt32(SDL2.SDLK_1);
    K_2 = UInt32(SDL2.SDLK_2);
    K_3 = UInt32(SDL2.SDLK_3);
    K_4 = UInt32(SDL2.SDLK_4);
    K_5 = UInt32(SDL2.SDLK_5);
    K_6 = UInt32(SDL2.SDLK_6);
    K_7 = UInt32(SDL2.SDLK_7);
    K_8 = UInt32(SDL2.SDLK_8);
    K_9 = UInt32(SDL2.SDLK_9);
    COLON = UInt32(SDL2.SDLK_COLON);
    SEMICOLON = UInt32(SDL2.SDLK_SEMICOLON);
    LESS = UInt32(SDL2.SDLK_LESS);
    EQUALS = UInt32(SDL2.SDLK_EQUALS);
    GREATER = UInt32(SDL2.SDLK_GREATER);
    QUESTION = UInt32(SDL2.SDLK_QUESTION);
    AT = UInt32(SDL2.SDLK_AT);
    LEFTBRACKET = UInt32(SDL2.SDLK_LEFTBRACKET);
    BACKSLASH = UInt32(SDL2.SDLK_BACKSLASH);
    RIGHTBRACKET = UInt32(SDL2.SDLK_RIGHTBRACKET);
    CARET = UInt32(SDL2.SDLK_CARET);
    UNDERSCORE = UInt32(SDL2.SDLK_UNDERSCORE);
    BACKQUOTE = UInt32(SDL2.SDLK_BACKQUOTE);
    A = UInt32(SDL2.SDLK_a);
    B = UInt32(SDL2.SDLK_b);
    C = UInt32(SDL2.SDLK_c);
    D = UInt32(SDL2.SDLK_d);
    E = UInt32(SDL2.SDLK_e);
    F = UInt32(SDL2.SDLK_f);
    G = UInt32(SDL2.SDLK_g);
    H = UInt32(SDL2.SDLK_h);
    I = UInt32(SDL2.SDLK_i);
    J = UInt32(SDL2.SDLK_j);
    K = UInt32(SDL2.SDLK_k);
    L = UInt32(SDL2.SDLK_l);
    M = UInt32(SDL2.SDLK_m);
    N = UInt32(SDL2.SDLK_n);
    O = UInt32(SDL2.SDLK_o);
    P = UInt32(SDL2.SDLK_p);
    Q = UInt32(SDL2.SDLK_q);
    R = UInt32(SDL2.SDLK_r);
    S = UInt32(SDL2.SDLK_s);
    T = UInt32(SDL2.SDLK_t);
    U = UInt32(SDL2.SDLK_u);
    V = UInt32(SDL2.SDLK_v);
    W = UInt32(SDL2.SDLK_w);
    X = UInt32(SDL2.SDLK_x);
    Y = UInt32(SDL2.SDLK_y);
    Z = UInt32(SDL2.SDLK_z);
    DELETE = UInt32(SDL2.SDLK_DELETE);
    KP0 = UInt32(SDL2.SDLK_KP_0);
    KP1 = UInt32(SDL2.SDLK_KP_1);
    KP2 = UInt32(SDL2.SDLK_KP_2);
    KP3 = UInt32(SDL2.SDLK_KP_3);
    KP4 = UInt32(SDL2.SDLK_KP_4);
    KP5 = UInt32(SDL2.SDLK_KP_5);
    KP6 = UInt32(SDL2.SDLK_KP_6);
    KP7 = UInt32(SDL2.SDLK_KP_7);
    KP8 = UInt32(SDL2.SDLK_KP_8);
    KP9 = UInt32(SDL2.SDLK_KP_9);
    KP_PERIOD = UInt32(SDL2.SDLK_KP_PERIOD);
    KP_DIVIDE = UInt32(SDL2.SDLK_KP_DIVIDE);
    KP_MULTIPLY = UInt32(SDL2.SDLK_KP_MULTIPLY);
    KP_MINUS = UInt32(SDL2.SDLK_KP_MINUS);
    KP_PLUS = UInt32(SDL2.SDLK_KP_PLUS);
    KP_ENTER = UInt32(SDL2.SDLK_KP_ENTER);
    KP_EQUALS = UInt32(SDL2.SDLK_KP_EQUALS);
    UP = UInt32(SDL2.SDLK_UP);
    DOWN = UInt32(SDL2.SDLK_DOWN);
    RIGHT = UInt32(SDL2.SDLK_RIGHT);
    LEFT = UInt32(SDL2.SDLK_LEFT);
    INSERT = UInt32(SDL2.SDLK_INSERT);
    HOME = UInt32(SDL2.SDLK_HOME);
    END = UInt32(SDL2.SDLK_END);
    PAGEUP = UInt32(SDL2.SDLK_PAGEUP);
    PAGEDOWN = UInt32(SDL2.SDLK_PAGEDOWN);
    F1 = UInt32(SDL2.SDLK_F1);
    F2 = UInt32(SDL2.SDLK_F2);
    F3 = UInt32(SDL2.SDLK_F3);
    F4 = UInt32(SDL2.SDLK_F4);
    F5 = UInt32(SDL2.SDLK_F5);
    F6 = UInt32(SDL2.SDLK_F6);
    F7 = UInt32(SDL2.SDLK_F7);
    F8 = UInt32(SDL2.SDLK_F8);
    F9 = UInt32(SDL2.SDLK_F9);
    F10 = UInt32(SDL2.SDLK_F10);
    F11 = UInt32(SDL2.SDLK_F11);
    F12 = UInt32(SDL2.SDLK_F12);
    F13 = UInt32(SDL2.SDLK_F13);
    F14 = UInt32(SDL2.SDLK_F14);
    F15 = UInt32(SDL2.SDLK_F15);
    NUMLOCK = UInt32(SDL2.SDLK_NUMLOCKCLEAR);
    CAPSLOCK = UInt32(SDL2.SDLK_CAPSLOCK);
    SCROLLOCK = UInt32(SDL2.SDLK_SCROLLLOCK);
    RSHIFT = UInt32(SDL2.SDLK_RSHIFT);
    LSHIFT = UInt32(SDL2.SDLK_LSHIFT);
    RCTRL = UInt32(SDL2.SDLK_RCTRL);
    LCTRL = UInt32(SDL2.SDLK_LCTRL);
    RALT = UInt32(SDL2.SDLK_RALT);
    LALT = UInt32(SDL2.SDLK_LALT);
    # RMETA = UInt32(SDL2.SDLK_RGUI);
    # LMETA = UInt32(SDL2.SDLK_LGUI);
    # LSUPER = UInt32(SDL2.SDLK_LGUI);
    # RSUPER = UInt32(SDL2.SDLK_RGUI);
    MODE = UInt32(SDL2.SDLK_MODE);
    HELP = UInt32(SDL2.SDLK_HELP);
    SYSREQ = UInt32(SDL2.SDLK_SYSREQ);
    MENU = UInt32(SDL2.SDLK_MENU);
    POWER = UInt32(SDL2.SDLK_POWER);
    EURO = UInt32(SDL2.SDLK_CURRENCYUNIT);
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
