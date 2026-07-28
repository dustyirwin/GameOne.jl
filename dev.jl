# dev.jl

using Pkg
Pkg.activate(@__DIR__)

using Revise

const SIMPLE_GAME_PATH = joinpath(@__DIR__, "examples", "simple_game.jl")

includet(SIMPLE_GAME_PATH)

# Start the game first!
SimpleGame.run_game_async()
println("Game started. Revise is now tracking simple_game.jl via entr().")
println("You can now edit the file to see changes.")

# Now, enter the blocking `entr` loop to watch for changes.
# This will also keep the main thread alive.
Revise.entr([SIMPLE_GAME_PATH]) do
    println("File changed, updating function reference...")
    # We update the Ref to point to the NEWEST version of the function.
    SimpleGame.FNK_REF[] = SimpleGame.imgui
end