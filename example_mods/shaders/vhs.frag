#pragma header

uniform float iTime;

float random(vec2 uv)
{
    return fract(sin(dot(uv.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

void main()
{
    vec2 uv = openfl_TextureCoordv;

    float time = iTime;

    //----------------------------------------
    // RGB Split
    //----------------------------------------

    float split = 0.0015;

    vec4 colR = flixel_texture2D(bitmap, uv + vec2(split,0.0));
    vec4 colG = flixel_texture2D(bitmap, uv);
    vec4 colB = flixel_texture2D(bitmap, uv - vec2(split,0.0));

    vec4 color;

    color.r = colR.r;
    color.g = colG.g;
    color.b = colB.b;
    color.a = colG.a;

    //----------------------------------------
    // Scanlines
    //----------------------------------------

    float scan = sin(uv.y * 850.0) * 0.025;
    color.rgb -= scan;

    //----------------------------------------
    // Noise
    //----------------------------------------

    float noise = random(uv * time * 50.0) * 0.04;
    color.rgb += noise;

    //----------------------------------------
    // Flicker
    //----------------------------------------

    float flicker = 0.98 + sin(time * 11.0) * 0.015;
    color.rgb *= flicker;

    //----------------------------------------
    // Dark Vignette
    //----------------------------------------

    vec2 center = uv - 0.5;

    float vignette = smoothstep(
        2.1,
        0.2,
        length(center)
    );

    color.rgb *= vignette;

    //----------------------------------------
    // Slight desaturation
    //----------------------------------------

    float gray = dot(color.rgb, vec3(0.299,0.587,0.114));

    color.rgb = mix(vec3(gray), color.rgb, 0.55);

    //----------------------------------------
    gl_FragColor = color;
}