# Use a pre-allocated event buffer instead of creating new ones
const EVENT_BUFFER = Ref{SDL2.SDL_Event}()

function pollEvents!()
    while Bool(SDL2.SDL_PollEvent(EVENT_BUFFER))
        evt = EVENT_BUFFER[]
        # ... event handling ...
    end

    return evt
end

function getEventType(e::Array{UInt8})
    bitcat(UInt32, e[4:-1:1])
end

function getEventType(e::SDL2.SDL_Event)
    bitcat(UInt32, e[4:-1:1])
end

# TextInputEvent only?
function getTextInputEventChar(e::Array{UInt8})
    Char(e[13])
end

function getTextEditEventChar(e::Array{UInt8})
    Char(e[14])
end

function getTextEditEventString(e::Array{UInt8})
    join([string.(e[13:32])]...)
end

function bitcat(::Type{T}, arr)::T where T<:Number
    out = zero(T)

    for x in arr
        out = out << T(sizeof(x) * 8)
        out |= convert(T, x)  # the `convert` prevents signed T from promoting to Int64.
    end

    out
end
