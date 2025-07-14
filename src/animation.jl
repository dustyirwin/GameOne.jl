# animation.jl

struct SpriteAnimation
    frames::Vector{GLuint}      # OpenGL texture IDs for each frame
    frame_times::Vector{Float64} # Duration of each frame (seconds)
    current_frame::Int
    timer::Float64
    looping::Bool
end

function SpriteAnimation(frames, frame_times; looping=true)
    SpriteAnimation(frames, frame_times, 1, 0.0, looping)
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