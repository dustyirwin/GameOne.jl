# animation.jl

@kwdef mutable struct SpriteAnimation
    const frame_data::Any                       # Pixel data for each frame
    const frame_times::Vector{Float64}          # Duration of each frame (seconds)
    const frame_ids::Vector{String}             # Unique IDs for each frame
    const w::Int
    const h::Int
    current_frame::Int=1
    timer::Float64=0.0
    looping::Bool=true
end

function update!(anim::SpriteAnimation, dt::Float64)
    anim.timer += dt
    while anim.timer > anim.frame_times[anim.current_frame]
        anim.timer -= anim.frame_times[anim.current_frame]
        anim.current_frame += 1
        
        if anim.current_frame > length(anim.frame_data)
            anim.current_frame = anim.looping ? 1 : length(anim.frame_data)
        end
    end
end

function process_webp(webp_path::String, anim_name::String, anim_dir::String)
  
    if !isdir(anim_dir)
        mkpath(anim_dir)
    else
        @debug "Animation directory already exists: $anim_dir"
        return
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

    frame_delays = [ v[:duration] for (k, v) in sort(frames) ]
    # save frame delays to file
    open(joinpath(anim_dir, "frame_delays.txt"), "w") do f
        for delay in frame_delays
            write(f, "$delay\n")
        end
    end

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