uniform sampler2D tex_orginal;

vec4 effect(vec4 glcolor, Image tex, vec2 texcoord, vec2 screen_coords) {
   vec4 color = Texel(tex, texcoord);
   vec4 color2 = Texel(tex_orginal, texcoord);
   color.a = 1.0 - color2.a;
   return color * glcolor;
}