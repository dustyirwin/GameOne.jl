# animation.jl


mutable struct SpriteAnimation
    const textures::Vector{Any}      # OpenGL texture IDs for each frame
    frame_times::Vector{Float64} # Duration of each frame (seconds)
    current_frame::Int
    timer::Float64
    looping::Bool
end

function create_sprite_animation(frame_data, w::Int, h::Int, frame_times::Vector{Float64}; looping=true)
    textures = [CImGui.create_image_texture(w, h) for _ in frame_data]
    for (i, tex) in enumerate(textures)
        CImGui.update_image_texture(tex, frame_data[i], w, h)
    end
    SpriteAnimation(textures, frame_times, 1, 0.0, looping)
end

function update!(anim::SpriteAnimation, dt::Float64)
    anim.timer += dt
    while anim.timer > anim.frame_times[anim.current_frame]
        anim.timer -= anim.frame_times[anim.current_frame]
        anim.current_frame += 1
        if anim.current_frame > length(anim.frames)
            anim.current_frame = anim.looping ? 1 : length(anim.frames)
        end
    end
end

function current_texture(anim::SpriteAnimation)
    anim.frames[anim.current_frame]
end

function process_webp(webp_path::String, anim_name::String, anim_dir::String)
  
    if !isdir(anim_dir)
        mkpath(anim_dir)
    end

    webp_txt = joinpath(anim_dir, "webp_info_$anim_name.txt")

    webpmux() do webpmux
        redirect_stdio(stdout=webp_txt) do
            run(`$webpmux -info $webp_path`)
        end
    end

  webp_info = readlines(webp_txt)

  n = [parse(Int32, split(ln)[4]) |> Int32 for ln in webp_info if occursin("frames:", ln)][1]

  frame_data = webp_info[6:end]
  frames = Dict()

  for i in 1:n
    d = Dict(
      :width => parse(Int32, split(frame_data[i])[2]),
      :height => parse(Int32, split(frame_data[i])[3]),
      :x_offset => parse(Int32, split(frame_data[i])[5]),
      :y_offset => parse(Int32, split(frame_data[i])[6]),
      :duration => parse(Int32, split(frame_data[i])[7]),
      :dispose => split(frame_data[i])[8],
    )

    frames[i] = d
  end

  frame_delays = [Millisecond(v[:duration]) for (k, v) in sort(frames)]

    # exporting each webp frame as a keyframe
  for i in 1:n
        tmp_png = joinpath(anim_dir, "frame_$(lpad(i,3,"0")).png")
        tmp_webp = joinpath(anim_dir, "frame_$(lpad(i,3,"0")).webp")

        if !isfile(tmp_png)

            if !isfile(tmp_webp)
                webpmux() do webpmux
                run(`$webpmux -get frame $i $webp_path -o $tmp_webp`)
                end
            end

            dwebp() do dwebp
                run(`$dwebp -quiet $tmp_webp -o $tmp_png`)
            end

        end

        if isfile(tmp_webp)
            rm(tmp_webp)
        end
    end
end