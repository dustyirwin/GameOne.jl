using ModernGL
using GeometryBasics
using StaticArrays
using Logging

# Vertex structure must match your shader layout!
struct Vertex
    position::Vec2f
    tex_coords::Vec2f
    color::Vec4f
    tex_id::Float32
end

# BatchRenderer holds OpenGL buffers and batching state
mutable struct BatchRenderer
    vao::GLuint
    vbo::GLuint
    ebo::GLuint
    shader::ShaderWatcher
    max_vertices::Int32
    max_indices::Int32
    vertex_count::Int32
    index_count::Int32
    vertices::Vector{Vertex}
    indices::Vector{UInt32}
    textures::Vector{GLuint}
    projection_matrix::Mat4f
    view_matrix::Mat4f
end

# Initialize a batch renderer
function BatchRenderer(shader::ShaderWatcher; max_quads=1000)
    max_vertices = max_quads * 4
    max_indices = max_quads * 6
    vao = Ref{GLuint}(0)
    vbo = Ref{GLuint}(0)
    ebo = Ref{GLuint}(0)
    glGenVertexArrays(1, vao)
    glGenBuffers(1, vbo)
    glGenBuffers(1, ebo)
    glBindVertexArray(vao[])
    glBindBuffer(GL_ARRAY_BUFFER, vbo[])
    glBufferData(GL_ARRAY_BUFFER, max_vertices*sizeof(Vertex), C_NULL, GL_DYNAMIC_DRAW)
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo[])
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, max_indices*sizeof(UInt32), C_NULL, GL_DYNAMIC_DRAW)
    # Vertex attrib pointers (must match Vertex struct and shader)
    stride = sizeof(Vertex)
    glEnableVertexAttribArray(0) # position
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, stride, Ptr{Cvoid}(0))
    glEnableVertexAttribArray(1) # tex_coords
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, stride, Ptr{Cvoid}(8))
    glEnableVertexAttribArray(2) # color
    glVertexAttribPointer(2, 4, GL_FLOAT, GL_FALSE, stride, Ptr{Cvoid}(16))
    glEnableVertexAttribArray(3) # tex_id
    glVertexAttribPointer(3, 1, GL_FLOAT, GL_FALSE, stride, Ptr{Cvoid}(32))
    glBindVertexArray(0)
    BatchRenderer(
        vao[], vbo[], ebo[], shader,
        max_vertices, max_indices, 0, 0,
        Vector{Vertex}(undef, max_vertices),
        Vector{UInt32}(undef, max_indices),
        Vector{GLuint}(),
        Mat4f(I), Mat4f(I)
    )
end

# Begin a new batch
function begin_batch!(br::BatchRenderer)
    br.vertex_count = 0
    br.index_count = 0
    empty!(br.textures)
end

# End and flush the batch to the GPU
function end_batch!(br::BatchRenderer)
    if br.vertex_count == 0 || br.index_count == 0
        return
    end
    maybe_reload!(br.shader)
    use_shader(br.shader.program)
    # Set projection/view uniforms
    set_uniform(br.shader.program, "u_projection", br.projection_matrix)
    set_uniform(br.shader.program, "u_view", br.view_matrix)
    # Upload vertex/index data
    glBindBuffer(GL_ARRAY_BUFFER, br.vbo)
    glBufferSubData(GL_ARRAY_BUFFER, 0, br.vertex_count*sizeof(Vertex), pointer(br.vertices))
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, br.ebo)
    glBufferSubData(GL_ELEMENT_ARRAY_BUFFER, 0, br.index_count*sizeof(UInt32), pointer(br.indices))
    # Bind textures
    for (i, tex) in enumerate(br.textures)
        glActiveTexture(GL_TEXTURE0 + (i-1))
        glBindTexture(GL_TEXTURE_2D, tex)
    end
    glBindVertexArray(br.vao)
    glDrawElements(GL_TRIANGLES, br.index_count, GL_UNSIGNED_INT, Ptr{Cvoid}(0))
    glBindVertexArray(0)
end

# Draw a quad (add to batch)
function draw_quad!(br::BatchRenderer, pos::Vec2f, size::Vec2f, color::Vec4f, tex::GLuint=0, tex_coords=ntuple(i->Vec2f(0),4))
    if br.vertex_count + 4 > br.max_vertices || br.index_count + 6 > br.max_indices
        end_batch!(br)
        begin_batch!(br)
    end
    tex_slot = 0
    if tex != 0
        tex_slot = findfirst(==(tex), br.textures)
        if tex_slot === nothing
            push!(br.textures, tex)
            tex_slot = length(br.textures)
        end
    end
    vbase = br.vertex_count + 1
    # Default tex_coords: (0,0),(1,0),(1,1),(0,1)
    if tex_coords == ntuple(i->Vec2f(0),4)
        tex_coords = (Vec2f(0,0), Vec2f(1,0), Vec2f(1,1), Vec2f(0,1))
    end
    br.vertices[br.vertex_count+1] = Vertex(pos, tex_coords[1], color, Float32(tex_slot-1))
    br.vertices[br.vertex_count+2] = Vertex(pos + Vec2f(size[1],0), tex_coords[2], color, Float32(tex_slot-1))
    br.vertices[br.vertex_count+3] = Vertex(pos + size, tex_coords[3], color, Float32(tex_slot-1))
    br.vertices[br.vertex_count+4] = Vertex(pos + Vec2f(0,size[2]), tex_coords[4], color, Float32(tex_slot-1))
    br.indices[br.index_count+1] = vbase-1
    br.indices[br.index_count+2] = vbase
    br.indices[br.index_count+3] = vbase+1
    br.indices[br.index_count+4] = vbase-1
    br.indices[br.index_count+5] = vbase+1
    br.indices[br.index_count+6] = vbase+2
    br.vertex_count += 4
    br.index_count += 6
end

# Clear the screen
function clear_screen!(color::Vec4f)
    glClearColor(color[1], color[2], color[3], color[4])
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
end

# Example: draw a colored quad
function draw_colored_quad!(br::BatchRenderer, pos::Vec2f, size::Vec2f, color::Vec4f)
    draw_quad!(br, pos, size, color)
end

# Example: draw a textured quad
function draw_textured_quad!(br::BatchRenderer, pos::Vec2f, size::Vec2f, tex::GLuint, color::Vec4f=Vec4f(1,1,1,1))
    draw_quad!(br, pos, size, color, tex)
end

# Present the frame (swap buffers)
function present!(context::GLContext)
    swap_buffers(context)
end