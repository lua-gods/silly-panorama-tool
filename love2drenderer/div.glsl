uniform Image weightTex;

vec4 effect(vec4 glColor, Image tex, vec2 texture_coords, vec2 screen_coords) {
   vec3 color = (Texel(tex, texture_coords) * glColor).rgb;
   float weight = Texel(weightTex, texture_coords).r;
   if (weight < 0.00001) {
      return vec4(0.0);
   }
   return vec4(color.rgb / weight, 1.0);
}