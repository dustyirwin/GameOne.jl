#version 150
uniform mat4 u_projection;
uniform mat4 u_view;
in vec2 a_position;
void main() {
    gl_Position = u_projection * u_view * vec4(a_position, 0.0, 1.0);
}