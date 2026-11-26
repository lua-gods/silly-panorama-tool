uniform vec2 blur_dir;
uniform float blur_mode;

vec4 effect(vec4 texcolor, Image tex, vec2 texcoord, vec2 screen_coords) {
   vec4 color = Texel(tex, texcoord);
   if (color.a > 0.8 && blur_mode < 0.5) {
      color.a = 1.0;
      return color * texcolor;
   }
   // float weight = color.a;
   // color *= weight;
   color = vec4(0.0);
   float weight = 0.0;
   for (float x = -3.5; x < 4.0; x++) {
      vec2 dir = blur_dir * x;
      vec2 uv = texcoord + dir / love_ScreenSize.xy;
      uv.x = fract(uv.x);
      vec4 myColor = Texel(tex, uv);
      float myWeight = myColor.a > 0.999 ? 1.0 : 0.0;
      // float myWeight = myColor.a;
      // myColor.rgb /= myColor.a;
      myWeight = mix(myWeight, 1.0, blur_mode);
      myColor.rgb = min(myColor.rgb, vec3(1.0));
      weight += myWeight;
      color += myColor * myWeight;
   }
   if (weight > 0.05) {
      color /= weight;
      color.rgb /= color.a;
   } else {
      color = vec4(0.0);
   }
   return color * texcolor;
   /*
   vec4 color = Texel(tex, texcoord);
   if (color.a > 0.8) {
      color.a = 1.0;
      return color * texcolor;
   }
   float weight = color.a;
   color *= weight;
   color = vec4(0.0);
   weight = 0.0;
   vec2 dir = vec2(2.0, 0.0);
   for (int x = -3; x < 4; x++) {
      for (int y = -3; y < 4; y++) {
         vec2 dir = vec2(x, y) * 2.0;
         vec4 myColor = Texel(tex, texcoord + dir / love_ScreenSize.xy);
         float myWeight = myColor.a > 0.999 ? 1.0 : 0.0;
         // float myWeight = myColor.a;
         // myColor.rgb /= myColor.a;
         myColor.rgb = min(myColor.rgb, vec3(1.0));
         weight += myWeight;
         color += myColor * myWeight;
      }
   }
   if (weight > 0.05) {
      color /= weight;
      color.rgb /= color.a;
   } else {
      color = vec4(0.0);
   }
   return color * texcolor;
   //*/
}