# glcontext.jl - GLFW window creation and OpenGL context management

using GLFW
using ModernGL

# Core data structures
mutable struct GLContext
    window::GLFW.Window
    width::Int32
    height::Int32
    title::String
    vsync::Bool
    samples::Int32
    monitor::GLFW.Monitor
    #windowhint::GLFW.WindowHint
    #framebuffer_size_callback::Function
    #error_callback::Function
    
    GLContext() = new()
end


# Global GLFW state
const GLFW_INITIALIZED = Ref{Bool}(false)
const GLFW_ERROR_CALLBACK = Ref{Ptr{Nothing}}(C_NULL)

# GLFW error callback
function glfw_error_callback(error_code::Cint, description::Ptr{Cchar})
    desc = unsafe_string(description)
    @error "GLFW Error ($error_code): $desc"
    return nothing
end

# Initialize GLFW (call once per application)
function init_glfw()
    if GLFW_INITIALIZED[]
        return true
    end
    
    # Set error callback before init
    GLFW_ERROR_CALLBACK[] = @cfunction(glfw_error_callback, Cvoid, (Cint, Ptr{Cchar}))
    GLFW.SetErrorCallback(nothing)
    
    if !GLFW.Init()
        @error "Failed to initialize GLFW"
        return false
    end
    
    GLFW_INITIALIZED[] = true
    @info "GLFW initialized successfully"
    return true
end

# Shutdown GLFW (call at application exit)
function shutdown_glfw()
    if GLFW_INITIALIZED[]
        GLFW.Terminate()
        GLFW_INITIALIZED[] = false
        @info "GLFW terminated"
    end
end

# Create OpenGL context with GLFW
function create_gl_context(width::Int32, height::Int32, title::String; 
                          vsync::Bool = true, 
                          samples::Int32 = Int32(4),
                          monitor::Union{GLFW.Monitor, Nothing} = nothing,
                          opengl_version::Tuple{Int,Int} = (3, 3))::GLContext
    
    if !init_glfw()
        error("Failed to initialize GLFW")
    end
    
    # Set OpenGL context hints
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 3)
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 2)
    GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE)
    GLFW.WindowHint(GLFW.OPENGL_FORWARD_COMPAT, GL_TRUE)  # Required on macOS
    
    # Window hints
    GLFW.WindowHint(GLFW.RESIZABLE, GL_TRUE)
    GLFW.WindowHint(GLFW.VISIBLE, GL_TRUE)  # Will show after OpenGL setup
    GLFW.WindowHint(GLFW.FOCUSED, GL_TRUE)
    GLFW.WindowHint(GLFW.AUTO_ICONIFY, GL_TRUE)
    GLFW.WindowHint(GLFW.DOUBLEBUFFER, GL_TRUE)
    
    # Multisampling
    if samples > 0
        GLFW.WindowHint(GLFW.SAMPLES, samples)
    end
    
    # create monitor
    monitor = GLFW.GetPrimaryMonitor()
    if monitor == C_NULL
        GLFW.Terminate()
        error("Failed to get primary monitor")
    end

    # Create window
    window = GLFW.CreateWindow(width, height, title, monitor)
    if window == C_NULL
        GLFW.Terminate()
        error("Failed to create GLFW window")
    end
    
    # Make OpenGL context current
    GLFW.MakeContextCurrent(window)

    # Set swap interval (vsync)
    GLFW.SwapInterval(vsync ? 1 : 0)
    
    # Show window after OpenGL setup
    GLFW.ShowWindow(window)
    
    # Get actual framebuffer size (may differ from window size on high-DPI displays)
    fb_width, fb_height = GLFW.GetFramebufferSize(window)
    glViewport(0, 0, fb_width, fb_height)
    
    # Enable OpenGL debug output in debug builds
    @static if haskey(ENV, "GAMEONE_DEBUG") || haskey(ENV, "DEBUG")
        enable_gl_debug()
    end
    
    @info "OpenGL Context Created" window_size=(width, height) framebuffer_size=(fb_width, fb_height) opengl_version=opengl_version
    
    # Create GLContext struct
    context = GLContext()
    context.window = window
    context.width = Int32(fb_width)
    context.height = Int32(fb_height)
    context.title = title
    context.vsync = vsync
    context.samples = samples
    context.monitor = monitor

    GLFW.MakeContextCurrent(context.window)

    return context
end

# Resize OpenGL context
function resize_gl_context!(context::GLContext, width::Int32, height::Int32)
    context.width = width
    context.height = height
    glViewport(0, 0, width, height)
    @debug "OpenGL context resized" new_size=(width, height)
end

# Check if context should close
function should_close(context::GLContext)::Bool
    return GLFW.WindowShouldClose(context.window)
end

# Set window should close
function set_should_close!(context::GLContext, should_close::Bool = true)
    GLFW.SetWindowShouldClose(context.window, should_close)
end

# Swap buffers
function swap_buffers(context::GLContext)
    GLFW.SwapBuffers(context.window)
end

# Poll events
function poll_events()
    GLFW.PollEvents()
end

# Wait for events (blocks until event received)
function wait_events()
    GLFW.WaitEvents()
end

# Get window size
function get_window_size(context::GLContext)::Tuple{Int32, Int32}
    width, height = GLFW.GetWindowSize(context.window)
    return (Int32(width), Int32(height))
end

# Get framebuffer size (actual OpenGL viewport size)
function get_framebuffer_size(context::GLContext)::Tuple{Int32, Int32}
    width, height = GLFW.GetFramebufferSize(context.window)
    return (Int32(width), Int32(height))
end

# Set window title
function set_window_title!(context::GLContext, title::String)
    context.title = title
    GLFW.SetWindowTitle(context.window, title)
end

# Destroy OpenGL context
function destroy_gl_context!(context::GLContext)
    if context.window != C_NULL
        GLFW.DestroyWindow(context.window)
        context.window = C_NULL
        @debug "OpenGL context destroyed"
    end
end

# OpenGL debug callback
function gl_debug_callback(source::GLenum, type::GLenum, id::GLuint, 
                          severity::GLenum, length::GLsizei, 
                          message::Ptr{GLchar}, userParam::Ptr{Cvoid})
    
    msg = unsafe_string(message, length)
    
    # Filter out low-priority messages
    if severity == GL_DEBUG_SEVERITY_NOTIFICATION
        return nothing
    end
    
    source_str = if source == GL_DEBUG_SOURCE_API
        "API"
    elseif source == GL_DEBUG_SOURCE_WINDOW_SYSTEM
        "Window System"
    elseif source == GL_DEBUG_SOURCE_SHADER_COMPILER
        "Shader Compiler"
    elseif source == GL_DEBUG_SOURCE_THIRD_PARTY
        "Third Party"
    elseif source == GL_DEBUG_SOURCE_APPLICATION
        "Application"
    else
        "Other"
    end
    
    type_str = if type == GL_DEBUG_TYPE_ERROR
        "Error"
    elseif type == GL_DEBUG_TYPE_DEPRECATED_BEHAVIOR
        "Deprecated"
    elseif type == GL_DEBUG_TYPE_UNDEFINED_BEHAVIOR
        "Undefined Behavior"
    elseif type == GL_DEBUG_TYPE_PORTABILITY
        "Portability"
    elseif type == GL_DEBUG_TYPE_PERFORMANCE
        "Performance"
    elseif type == GL_DEBUG_TYPE_MARKER
        "Marker"
    else
        "Other"
    end
    
    if severity == GL_DEBUG_SEVERITY_HIGH
        @error "OpenGL [$source_str/$type_str]: $msg" id=id
    elseif severity == GL_DEBUG_SEVERITY_MEDIUM
        @warn "OpenGL [$source_str/$type_str]: $msg" id=id
    else
        @debug "OpenGL [$source_str/$type_str]: $msg" id=id
    end
    
    return nothing
end

# Enable OpenGL debug output
function enable_gl_debug()
    if glDebugMessageCallback != C_NULL
        glEnable(GL_DEBUG_OUTPUT)
        glEnable(GL_DEBUG_OUTPUT_SYNCHRONOUS)
        
        callback_func = @cfunction(gl_debug_callback, Cvoid, 
            (GLenum, GLenum, GLuint, GLenum, GLsizei, Ptr{GLchar}, Ptr{Cvoid}))
        glDebugMessageCallback(callback_func, C_NULL)
        
        # Filter out notification messages
        glDebugMessageControl(GL_DONT_CARE, GL_DONT_CARE, GL_DEBUG_SEVERITY_NOTIFICATION, 0, C_NULL, false)
        
        @info "OpenGL debug output enabled"
    else
        @warn "OpenGL debug output not available"
    end
end

# Get OpenGL version info
function get_gl_info()
    vendor = unsafe_string(glGetString(GL_VENDOR))
    renderer = unsafe_string(glGetString(GL_RENDERER))
    version = unsafe_string(glGetString(GL_VERSION))
    glsl_version = unsafe_string(glGetString(GL_SHADING_LANGUAGE_VERSION))
    
    return (vendor=vendor, renderer=renderer, version=version, glsl_version=glsl_version)
end

# Check OpenGL extensions
function has_gl_extension(extension::String)::Bool
    extensions_count = Ref{GLint}(0)
    glGetIntegerv(GL_NUM_EXTENSIONS, extensions_count)
    
    for i in 0:(extensions_count[] - 1)
        ext = unsafe_string(glGetStringi(GL_EXTENSIONS, GLuint(i)))
        if ext == extension
            return true
        end
    end
    return false
end

# Set up framebuffer callback for window resize
function setup_framebuffer_callback!(context::GLContext, callback::Function)
    # Store callback in window user pointer for retrieval
    GLFW.SetWindowUserPointer(context.window, pointer_from_objref(callback))
    
    # Set the framebuffer size callback
    function framebuffer_callback(window::GLFW.Window, width::Cint, height::Cint)
        # Retrieve callback from user pointer
        callback_ptr = GLFW.GetWindowUserPointer(window)
        if callback_ptr != C_NULL
            callback_func = unsafe_pointer_to_objref(callback_ptr)::Function
            callback_func(Int32(width), Int32(height))
        end
        return nothing
    end
    
    GLFW.SetFramebufferSizeCallback(context.window, framebuffer_callback)
end