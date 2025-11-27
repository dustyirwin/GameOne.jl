using ModernGL
using Logging
using Dates


mutable struct Shader
    program::GLuint
    vertex_shader::GLuint
    fragment_shader::GLuint
    uniforms::Dict{String, GLint}
    path::String  # For hot-reloading
    last_modified::Float64
    
    Shader() = new(0, 0, 0, Dict{String, GLint}(), "", 0.0)
end


# Get OpenGL version information
function get_gl_info()
    version = unsafe_string(glGetString(GL_VERSION))
    glsl_version = unsafe_string(glGetString(GL_SHADING_LANGUAGE_VERSION))
    return (version=version, glsl_version=glsl_version)
end


# Utility: Read a file as a string
function read_shader_file(path::String)
    println("Reading shader file: ", abspath(path))
    src = open(path, "r") do io
        read(io, String)
    end
    #println("Full shader source:\n", src)
    #println("Shader bytes: ", collect(codeunits(src)))
    return src
end

# Compile a single shader (vertex or fragment)
function compile_shader(src::String, shader_type::GLenum)
    shader = glCreateShader(shader_type)
    # Ensure null-terminated C string and correct pointer type
    cstr = Vector{UInt8}(src * '\0')
    cstr_ptr = Ref{Ptr{UInt8}}(pointer(cstr))
    glShaderSource(shader, 1, cstr_ptr, C_NULL)
    glCompileShader(shader)

    info = get_gl_info()
    println("OpenGL version: ", info.version)
    println("GLSL version: ", info.glsl_version)

    # Check for errors (unchanged)
    status = Ref{GLint}(0)
    glGetShaderiv(shader, GL_COMPILE_STATUS, status)
    if status[] == GL_FALSE
        loglen = Ref{GLint}(0)
        glGetShaderiv(shader, GL_INFO_LOG_LENGTH, loglen)
        buf = Vector{UInt8}(undef, loglen[])
        glGetShaderInfoLog(shader, loglen[], C_NULL, pointer(buf))
        error("Shader compile error: $(String(buf))")
    end
    return shader
end

# Link shaders into a program
function link_program(vs::GLuint, fs::GLuint)
    program = glCreateProgram()
    glAttachShader(program, vs)
    glAttachShader(program, fs)
    glLinkProgram(program)

    # Check for errors
    status = Ref{GLint}(0)
    glGetProgramiv(program, GL_LINK_STATUS, status)
    if status[] == GL_FALSE
        loglen = Ref{GLint}(0)
        glGetProgramiv(program, GL_INFO_LOG_LENGTH, loglen)
        buf = Vector{UInt8}(undef, loglen[])
        glGetProgramInfoLog(program, loglen[], C_NULL, pointer(buf))
        error("Shader link error: $(String(buf))")
    end
    return program
end

# Load, compile, and link a shader program from files
function create_shader(vert_path::String, frag_path::String)
    vert_src = read_shader_file(vert_path)
    frag_src = read_shader_file(frag_path)
    vs = compile_shader(vert_src, GL_VERTEX_SHADER)
    fs = compile_shader(frag_src, GL_FRAGMENT_SHADER)
    prog = link_program(vs, fs)
    glDeleteShader(vs)
    glDeleteShader(fs)
    @info "Shader compiled and linked" vert=vert_path frag=frag_path
    return prog
end

# Hot-reloading: Track file modification times
mutable struct ShaderWatcher
    vert_path::String
    frag_path::String
    last_vert_mtime::Float64
    last_frag_mtime::Float64
    program::GLuint
end

function ShaderWatcher(vert_path::String, frag_path::String)
    last_vert = stat(vert_path).mtime
    last_frag = stat(frag_path).mtime
    prog = create_shader(vert_path, frag_path)
    ShaderWatcher(vert_path, frag_path, last_vert, last_frag, prog)
end

# Check and reload shader if source files changed
function maybe_reload!(watcher::ShaderWatcher)
    vert_mtime = stat(watcher.vert_path).mtime
    frag_mtime = stat(watcher.frag_path).mtime
    if vert_mtime != watcher.last_vert_mtime || frag_mtime != watcher.last_frag_mtime
        @info "Hot-reloading shader" vert=watcher.vert_path frag=watcher.frag_path
        try
            prog = create_shader(watcher.vert_path, watcher.frag_path)
            glDeleteProgram(watcher.program)
            watcher.program = prog
            watcher.last_vert_mtime = vert_mtime
            watcher.last_frag_mtime = frag_mtime
        catch e
            @error "Shader hot-reload failed: $e"
        end
    end
end

# Utility: Use a shader program
function use_shader(prog::GLuint)
    glUseProgram(prog)
end

# Utility: Set uniform (float, int, vec2, vec3, vec4, mat4)
function set_uniform(prog::GLuint, name::String, value)
    loc = glGetUniformLocation(prog, name)
    if loc == -1
        @warn "Uniform not found" name
        return
    end
    if isa(value, Float32)
        glUniform1f(loc, value)
    elseif isa(value, Int32)
        glUniform1i(loc, value)
    elseif isa(value, AbstractVector{Float32}) && length(value) == 2
        glUniform2f(loc, value[1], value[2])
    elseif isa(value, AbstractVector{Float32}) && length(value) == 3
        glUniform3f(loc, value[1], value[2], value[3])
    elseif isa(value, AbstractVector{Float32}) && length(value) == 4
        glUniform4f(loc, value[1], value[2], value[3], value[4])
    elseif isa(value, AbstractMatrix{Float32}) && size(value) == (4,4)
        glUniformMatrix4fv(loc, 1, GL_FALSE, pointer(value))
    else
        @warn "Unsupported uniform type" name value
    end
end