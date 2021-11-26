using GameOne
using Test

@testset "basic" begin
    global g
    @test_nowarn begin 
        g = GameOne.initgame(joinpath("..","example","BasicGame","basic.jl"))
        GameOne.quitSDL(g)
    end
    
end

@testset "basic2" begin
    @test_nowarn begin 
        g = GameOne.initgame(joinpath("..","example","BasicGame","basic2.jl"))
        GameOne.quitSDL(g)
    end
end
