void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    fragColor = vec4(0);    
    vec2 d = 1.0 / iResolution.xy;
    vec2 uv = (d.xy * float(PIXEL_SIZE)) * floor(fragCoord.xy / float(PIXEL_SIZE));
    
	for (int i = 0; i < PIXEL_SIZE; i++)
		for (int j = 0; j < PIXEL_SIZE; j++)
			fragColor += texture(iChannel0, uv.xy + vec2(d.x * float(i), d.y * float(j)));

	fragColor /= pow(float(PIXEL_SIZE), 2.0);   
}