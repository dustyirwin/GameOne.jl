# GameOne.jl

__GameOne.jl is a WIP non-zero overhead game engine, based on [aviks/GameZero.jl](https://github.com/aviks/GameZero.jl).__

## Known Issues
- None, please submit one!

## Running Games

Games created using GameOne are `.jl` files that live in any directory.
To play the games, start the Julia REPL and:

```
julia> using Pkg

julia> Pkg.activate(".")

julia> using GameOne

julia> rungame("examples/example1.jl")
```

## Acknowledgement
The design of this library is inspired by the Julia library aviks/GameZero.jl, which is based on the python package [PyGameZero](https://pygame-zero.readthedocs.io) by [Daniel Pope](https://github.com/lordmauve).

GameOne uses [SDL2](https://www.libsdl.org/) via the [Julia wrapper](https://github.com/jonathanBieler/SimpleDirectMediaLayer.jl).
