### A Pluto.jl notebook ###
# v0.14.7

using Markdown
using InteractiveUtils

# ╔═╡ 19a5bffa-86b3-11eb-2a1b-d9acf5a05351
begin
	using Pkg

	Pkg.activate("Examples")
	
	try 
		using GameOne 
	catch
		Pkg.add(["Colors"
				"PlutoUI"
				"Images"
				"ImageIO"
				"SimpleDirectMediaLayer"
				"ShiftedArrays"])
		Pkg.add(url="https://github.com/dustyirwin/GameOne.jl")
		Pkg.add(url="https://github.com/Pocket-titan/DarkMode")
	end

	using Colors
	using Images
	using ImageIO
	using PlutoUI
	using GameOne
	using ShiftedArrays
	using SimpleDirectMediaLayer
	
	import DarkMode

	const SDL2 = SimpleDirectMediaLayer

	md"""
	## Game Example One
	This notebook is adapted from aviks/GameZero.jl/example/BasicGame/basic.jl
	"""
end

# ╔═╡ dbac3a3a-86b2-11eb-3ab6-b372402be5ed
# Height of the game window
const HEIGHT = 400

# ╔═╡ 3ca2ae5a-86b3-11eb-05a8-65b38937b812
# Width of the game window
const WIDTH = 400

# ╔═╡ 3fba3626-86b3-11eb-0083-c3b4e3b8f030
# Background color of the game window
const BACKGROUND = colorant"purple"

# ╔═╡ 778c9b2a-86b3-11eb-2bde-17da75aa588f
# Global to store velocities of the actor
begin
	dx = 2
	dy = 2
end

# ╔═╡ 183b510c-86ba-11eb-034a-875bf309b781
alien_imgs = ["images/alien.png", "images/alien_hurt.png"]

# ╔═╡ baa28b8a-86b4-11eb-1dd2-9d9620e7d72d
function ImageActor(img_name::String, img_fns; x=0, y=0, sfs=[], kv...)

	for img_fn in img_fns
    	sf = SDL2.IMG_Load(img_fn)
		push!(sfs, sf)
	end

	@show w, h = Int32.(size(sfs[begin]))

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

# ╔═╡ 13c71904-86b7-11eb-1555-2b946684a23b
function update(a::Actor, dx, dy)

	a.position.x += dx
	a.position.y += dy

	if a.x > 400-a.w || a.x < 2
		dx = -dx
		play_sound("sounds/eep.wav")
	end

	if a.y > 400-a.h || a.y < 2
		dy = -dy
		play_sound("sounds/eep.wav")
	end
	
	a, dx, dy
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
"""

# ╔═╡ Cell order:
# ╟─19a5bffa-86b3-11eb-2a1b-d9acf5a05351
# ╠═dbac3a3a-86b2-11eb-3ab6-b372402be5ed
# ╠═3ca2ae5a-86b3-11eb-05a8-65b38937b812
# ╠═3fba3626-86b3-11eb-0083-c3b4e3b8f030
# ╠═778c9b2a-86b3-11eb-2bde-17da75aa588f
# ╠═183b510c-86ba-11eb-034a-875bf309b781
# ╠═baa28b8a-86b4-11eb-1dd2-9d9620e7d72d
# ╟─85f8f0be-86b3-11eb-0915-8168ea743a8d
# ╠═fd103f2e-86b6-11eb-3c6d-7f88f3307577
# ╠═0e6bcb1c-86b7-11eb-381f-e318bfcaf749
# ╟─1fb97c3e-86b7-11eb-0e87-e1ce13846d21
# ╠═13c71904-86b7-11eb-1555-2b946684a23b
# ╠═77154a94-86b7-11eb-345c-6bcb99dd6664
# ╠═1224bbba-86bc-11eb-3f60-fbd14b6442a8
# ╟─a56bcd38-86b6-11eb-2c04-c579bab3fb95
