### A Pluto.jl notebook ###
# v0.19.8

using Markdown
using InteractiveUtils

# ╔═╡ aa96d7f7-36dc-4c50-9e20-28f2d9410144
begin
	using Pkg
	Pkg.activate("..")
	
	using Colors
	using Images
	using ImageIO
	using PlutoUI
	using GameOne
	using ShiftedArrays
	using SimpleDirectMediaLayer
end

# ╔═╡ dd885c11-fa61-4852-932c-47da57d5ddae
const SDL2 = GameOne.SDL2

# ╔═╡ 19a5bffa-86b3-11eb-2a1b-d9acf5a05351
md"""
## Example One
This notebook is adapted from aviks/GameZero.jl/example/BasicGame/basic.jl
"""

# ╔═╡ dbac3a3a-86b2-11eb-3ab6-b372402be5ed
# Height of the game window
const HEIGHT = 400

# ╔═╡ 3ca2ae5a-86b3-11eb-05a8-65b38937b812
# Width of the game window
const WIDTH = 400

# ╔═╡ 3fba3626-86b3-11eb-0083-c3b4e3b8f030
# Background color of the game window
const BACKGROUND = colorant"purple"

# ╔═╡ 1c3cd8dc-4b5d-4a55-a575-b22173c49a6c
# Global to store velocities of the actor

# ╔═╡ 092d47ac-1281-4f63-8135-45a49053fdd6
dx = 2

# ╔═╡ 3994ece9-30a9-4fef-b133-90651fa254b3
dy = 2

# ╔═╡ 183b510c-86ba-11eb-034a-875bf309b781
alien_imgs = ["images/alien.png", "images/alien_hurt.png"]

# ╔═╡ baa28b8a-86b4-11eb-1dd2-9d9620e7d72d
function ImageActor(img_name::String, img_fns; x=0, y=0, sfs=[], kv...)

	for img_fn in img_fns
    	sf = SDL2.IMG_Load(img_fn)
		push!(sfs, sf)
	end

	w, h = Int32.(size(sfs[begin]))

    r = SDL2.Rect(x, y, w, h)
    a = Actor(
        img_name,
        sfs,
        [],
        r,
        [1,1],
        C_NULL,
        0,
        255,
        Dict(
            :img_fns=>img_fns,
            :label=>img_name,
        )
    )

    for (k, v) in kv
        setproperty!(a, k, v)
    end

	a
end

# ╔═╡ 85f8f0be-86b3-11eb-0915-8168ea743a8d
# Create an `Image` actor object with an image
a = ImageActor("alien", alien_imgs)

# ╔═╡ 06c373c9-d470-4b93-a8bb-e0d6496d885f
#[ pwd() * "/" * fn |> load for fn in a.data[:img_fns] ]

# ╔═╡ fd103f2e-86b6-11eb-3c6d-7f88f3307577
# Start playing background music -- audio not working on linux!
play_music("radetzky_ogg")

# ╔═╡ 0e6bcb1c-86b7-11eb-381f-e318bfcaf749
function draw(g::Game)
    draw(a)
end

# ╔═╡ 1fb97c3e-86b7-11eb-0e87-e1ce13846d21
md"""The update function is called every frame. Within the function, we
change the position of the actor by the velocity if the actor hits the edges, we invert the velocity, and play a sound if the up/down/left/right keys are pressed, we change the velocity to move the actor in the direction of the keypress
"""

# ╔═╡ 1af61533-7dee-49a1-a300-420fbcd3741b
# dx & dy not being brought into game scope?

# ╔═╡ 13c71904-86b7-11eb-1555-2b946684a23b
function update(g::Game)
	#a.position.x += dx
	#a.position.y += dy

	if a.x > 400-a.w || a.x < 2
#		dx = -dx
		play_sound("sounds/eep.wav")
	end

	if a.y > 400-a.h || a.y < 2
#		dy = -dy
		play_sound("sounds/eep.wav")
	end
	
	if g.keyboard.DOWN
#        dy = 2
    elseif g.keyboard.UP
 #       dy = -2
    elseif g.keyboard.LEFT
 #       dx = -2
    elseif g.keyboard.RIGHT
 #       dx = 2
    end
end

# ╔═╡ 1224bbba-86bc-11eb-3f60-fbd14b6442a8
function shift_surface(a::Actor)
	a.surfaces = circshift(a.surfaces, -1)
	a
end

# ╔═╡ 77154a94-86b7-11eb-345c-6bcb99dd6664
# If the "space" key is pressed, change the displayed image to the "hurt" variant.
# Also schedule an event to change it back to normal after one second.
function on_key_down(a::Actor, dx, dy, k)
	if k == Keys.SPACE
		@show "$k :)"
        a = shift_surface()
        schedule_once(shift_surface, 1)

	elseif k == Keys.DOWN
        @show dy = 2

	elseif k == Keys.UP
        @show dy = -2

	elseif k == Keys.LEFT
        @show dx = -2

	elseif k == Keys.RIGHT
        @show dx = 2
	end
	
	a
end

# ╔═╡ a56bcd38-86b6-11eb-2c04-c579bab3fb95
md"""
## That's it!
If all cells resolved successfully, we should be able to execute `rungame("path/to/this_notebook.jl")` from another Julia instance to start this game. 

!!! warning
	Do not run this notebook from itself, this will cause an infinite loop.
"""

# ╔═╡ Cell order:
# ╠═aa96d7f7-36dc-4c50-9e20-28f2d9410144
# ╠═dd885c11-fa61-4852-932c-47da57d5ddae
# ╠═19a5bffa-86b3-11eb-2a1b-d9acf5a05351
# ╠═dbac3a3a-86b2-11eb-3ab6-b372402be5ed
# ╠═3ca2ae5a-86b3-11eb-05a8-65b38937b812
# ╠═3fba3626-86b3-11eb-0083-c3b4e3b8f030
# ╠═1c3cd8dc-4b5d-4a55-a575-b22173c49a6c
# ╠═092d47ac-1281-4f63-8135-45a49053fdd6
# ╠═3994ece9-30a9-4fef-b133-90651fa254b3
# ╠═183b510c-86ba-11eb-034a-875bf309b781
# ╠═baa28b8a-86b4-11eb-1dd2-9d9620e7d72d
# ╠═85f8f0be-86b3-11eb-0915-8168ea743a8d
# ╠═06c373c9-d470-4b93-a8bb-e0d6496d885f
# ╠═fd103f2e-86b6-11eb-3c6d-7f88f3307577
# ╠═0e6bcb1c-86b7-11eb-381f-e318bfcaf749
# ╟─1fb97c3e-86b7-11eb-0e87-e1ce13846d21
# ╠═1af61533-7dee-49a1-a300-420fbcd3741b
# ╠═13c71904-86b7-11eb-1555-2b946684a23b
# ╠═77154a94-86b7-11eb-345c-6bcb99dd6664
# ╠═1224bbba-86bc-11eb-3f60-fbd14b6442a8
# ╟─a56bcd38-86b6-11eb-2c04-c579bab3fb95
