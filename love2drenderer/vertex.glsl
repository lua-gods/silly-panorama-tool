uniform mat4 projectionMatrix;
uniform mat4 viewMatrix;

vec4 position(mat4 transform_projection, vec4 vertex_position) {
   // The order of operations matters when doing matrix multiplication.
   // return projectionMatrix * transform_projection * vertex_position;
   // return projectionMatrix * viewMatrix * vertex_position;
   return projectionMatrix * vertex_position;
}
