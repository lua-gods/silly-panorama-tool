#define PI 3.1415926535

uniform float rotX;
uniform float rotY;

mat2 rotate2d(float angle){
   float a = cos(angle);
   float b = sin(angle);
   return mat2(
      a, -b,
      b, a
   );
}

vec4 effect(vec4 glColor, Image tex, vec2 texture_coords, vec2 screen_coords) {
   if (screen_coords.x < -10.0) {
      return vec4(rotX, rotY, 0.0, 0.0);
   }
   vec3 dir = vec3(0.0, 0.0, 1.0);
   dir.zy *= rotate2d((texture_coords.y - 0.5) * PI);
   dir.xz *= rotate2d(texture_coords.x * PI * -2.0);
   dir.zy *= rotate2d(rotX);
   dir.xz *= rotate2d(rotY);
   vec3 pos = dir / dir.z;
   vec2 uv = pos.xy * 0.5 + 0.5;
   if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0 || dir.z > 0) {
      return vec4(0.0);
   }
   uv.y = 1.0 - uv.y;

   return Texel(tex, uv) * glColor;
}