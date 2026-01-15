uniform Image MainTex;

void effect() {
   vec3 color = (Texel(MainTex, VaryingTexCoord.xy) * VaryingColor).rgb;

   vec2 offset = abs(VaryingTexCoord.xy * 2.0 - 1.0);
   float weight = 1.0 - max(offset.x, offset.y);
   weight *= weight;

   color.rgb *= weight;

   love_Canvases[0] = vec4(color, 1.0);
   love_Canvases[1] = vec4(weight, 0.0, 0.0, 1.0);
}