const std = @import("std");
const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
});
//c.GLuint == c_uint
var rendering_program: c.GLuint = undefined;
const numVAOs = 1;
var vao: [numVAOs]c.GLuint = undefined;

fn createShaderProgram() c.GLuint {
    //define GLSL code
    const v_shader_source: [*c]const u8 =
        \\#version 430
        \\void main(void)
        \\{
        \\  gl_Position = vec4(0.0, 0.0, 0.0, 1.0);
        \\}
    ;
    const f_shader_source: [*c]const u8 =
        \\#version 430
        \\out vec4 color;
        \\void main(void)
        \\{
        \\  color = vec4(0.0, 0.0, 1.0, 1.0);
        \\}
    ;

    //create empty shaders and return id/index
    const v_shader = c.glCreateShader(c.GL_VERTEX_SHADER);
    const f_shader = c.glCreateShader(c.GL_FRAGMENT_SHADER);

    //load GLSL code into empty shader objects
    c.glShaderSource(v_shader, 1, &v_shader_source, null);
    c.glShaderSource(f_shader, 1, &f_shader_source, null);
    c.glCompileShader(v_shader);
    c.glCompileShader(f_shader);

    //create program, attach shaders
    const vf_program = c.glCreateProgram();
    c.glAttachShader(vf_program, v_shader);
    c.glAttachShader(vf_program, f_shader);
    //request that GLSL compiler ensure that they are compatible
    c.glLinkProgram(vf_program);
    return vf_program;
}

fn init(window: ?*c.GLFWwindow) !void {
    _ = window;
    rendering_program = createShaderProgram();
    c.glGenVertexArrays(numVAOs, &vao);
    c.glBindVertexArray(vao[0]);
}

fn display() void {
    //load the program into the OpenGL pipeline stages (onto the GPU)
    //it does not run the shaders just loads them onto hardware
    c.glUseProgram(rendering_program);
    //initiates pipeline processing
    c.glDrawArrays(c.GL_POINTS, 0, 1);
    // c.glClearColor(1.0, 0.0, 0.0, 1.0);
    //whenever we call this the color buffer will be filled with the color
    //configured by glClearColor
    // c.glClear(c.GL_COLOR_BUFFER_BIT);
}

pub fn main() !void {
    //check platform needed
    if (c.glfwPlatformSupported(c.GLFW_PLATFORM_X11) == c.GLFW_TRUE) {
        c.glfwInitHint(c.GLFW_PLATFORM, c.GLFW_PLATFORM_X11);
    }

    // init glfw library
    if (c.glfwInit() != c.GLFW_TRUE) {
        std.log.err("Error while initializing", .{});
        return error.Initialize;
    }

    //set version of opengl and core profile (smaller subset of openGL)
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 4);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 3);
    c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);
    c.glfwWindowHint(c.GLFW_OPENGL_DEBUG_CONTEXT, c.GL_TRUE);
    //this is needed for wayland/X11 and glad not needed for glew
    c.glfwWindowHint(c.GLFW_CONTEXT_CREATION_API, c.GLFW_EGL_CONTEXT_API);

    //create window object
    const window = c.glfwCreateWindow(800, 600, "LearnOpenGL", null, null);
    if (window == null) {
        std.log.err("Failed to create GLFW window", .{});
        c.glfwTerminate();
        return error.Initialize;
    }
    defer c.glfwDestroyWindow(window);
    // as soon as we exit the render loop we clean/delete all of glfw resources that were allocated
    defer c.glfwTerminate();

    _ = c.glfwSetErrorCallback(errorCallback);

    c.glfwMakeContextCurrent(window);
    //set callback function
    _ = c.glfwSetFramebufferSizeCallback(window, frameBufferSizeCallback);
    //init glew
    // const err = c.glewInit();
    // if (err != c.GLEW_OK) {
    //     const e = c.glewGetErrorString(err);
    //     std.debug.print("err: {d} message: {s}\n", .{ err, e });
    //     std.log.err("Failed intializating glew", .{});
    //     return error.Initialize;
    // }
    // c.__glewDebugMessageCallback.?(glDebugCallback, null);
    if (c.gladLoadGL() == 0) {
        std.log.err("Failed to initialize GLAD", .{});
        return error.Initialize;
    }
    c.glfwSwapInterval(1);
    try init(window);

    //this func check if glfw has been instructed to close
    while (c.glfwWindowShouldClose(window) == 0) {
        processInput(window);
        display();
        //swap color buffer that is used to render, this render iteration is shown as output to the screen
        c.glfwSwapBuffers(window);
        //check if any events are triggered like keyboard input or mouse movement
        c.glfwPollEvents();
    }
}

fn processInput(window: ?*c.GLFWwindow) void {
    if (c.glfwGetKey(window, c.GLFW_KEY_ESCAPE) == c.GLFW_PRESS) {
        //0 -> FALSE | 1 -> TRUE, using GLFW_TRUE for better readibilty
        c.glfwSetWindowShouldClose(window, c.GLFW_TRUE);
    }
}

// this callback function is called each time the window is resized
fn frameBufferSizeCallback(window: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
    _ = window;
    std.debug.print("window resized", .{});
    c.glViewport(0, 0, width, height);
}

fn errorCallback(err: c_int, description: [*c]const u8) callconv(.C) void {
    _ = description;
    _ = err;
    std.debug.print("error happend\n", .{});
    // std.log.err("glfw err {d}: {s}", .{ err, description });
}

fn glDebugCallback(source: c.GLenum, typ: c.GLenum, id: c.GLuint, severity: c.GLenum, length: c.GLsizei, message: [*c]const c.GLchar, user_param: ?*const anyopaque) callconv(.C) void {
    _ = severity;
    _ = source;
    _ = typ;
    _ = length;
    _ = id;
    _ = user_param;
    std.log.err("{s}", .{message});
}
