# math.jl - Lightweight 2D/3D math utilities
using LinearAlgebra
using StaticArrays

# 2D/3D Transform matrices
function create_orthographic_matrix(left::Float32, right::Float32, bottom::Float32, top::Float32, 
                                  near::Float32 = -1.0f0, far::Float32 = 1.0f0)::Mat4f
    return Mat4f(
        2.0f0 / (right - left), 0.0f0, 0.0f0, -(right + left) / (right - left),
        0.0f0, 2.0f0 / (top - bottom), 0.0f0, -(top + bottom) / (top - bottom),
        0.0f0, 0.0f0, -2.0f0 / (far - near), -(far + near) / (far - near),
        0.0f0, 0.0f0, 0.0f0, 1.0f0
    )
end

function create_translation_matrix(x::Float32, y::Float32, z::Float32 = 0.0f0)::Mat4f
    return Mat4f(
        1.0f0, 0.0f0, 0.0f0, x,
        0.0f0, 1.0f0, 0.0f0, y,
        0.0f0, 0.0f0, 1.0f0, z,
        0.0f0, 0.0f0, 0.0f0, 1.0f0
    )
end

function create_scale_matrix(x::Float32, y::Float32, z::Float32 = 1.0f0)::Mat4f
    return Mat4f(
        x, 0.0f0, 0.0f0, 0.0f0,
        0.0f0, y, 0.0f0, 0.0f0,
        0.0f0, 0.0f0, z, 0.0f0,
        0.0f0, 0.0f0, 0.0f0, 1.0f0
    )
end

function create_rotation_matrix_z(angle::Float32)::Mat4f
    c = cos(angle)
    s = sin(angle)
    return Mat4f(
        c, -s, 0.0f0, 0.0f0,
        s, c, 0.0f0, 0.0f0,
        0.0f0, 0.0f0, 1.0f0, 0.0f0,
        0.0f0, 0.0f0, 0.0f0, 1.0f0
    )
end

# Color utilities
function color_to_vec4f(c::Colorant)::Vec4f
    return Vec4f(red(c), green(c), blue(c), alpha(c))
end

function vec4f_to_color(v::Vec4f)::ARGB{Float32}
    return ARGB{Float32}(v[4], v[1], v[2], v[3])
end