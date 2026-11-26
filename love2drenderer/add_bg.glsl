#define PI 3.1415926535

uniform Image MainTex;

uniform mat4 projectionMatrix;

void effect() {
   vec3 dir = (projectionMatrix * vec4(vec3(VaryingTexCoord.xy * 2.0 - 1.0, 1.0), 1.0)).xyz;

   // vec2 dir = ;

   vec2 uv = vec2(
      atan(dir.z, dir.x),
      atan(dir.y, length(dir.xz))
   );

   uv /= PI;
   uv.y *= 2.0;
   uv = uv * 0.5 + 0.5;
   uv.x = fract(uv.x + 0.25);

   vec4 color = (Texel(MainTex, uv) * VaryingColor);

   float weight = color.a * 0.05;
   weight *= weight;

   color *= weight;

   love_Canvases[0] = vec4(color.rgb, 1.0);
   love_Canvases[1] = vec4(weight, 0.0, 0.0, 1.0);
}