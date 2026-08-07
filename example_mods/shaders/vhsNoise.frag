#pragma header

uniform float iTime;

float rand(vec2 co)
{
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void main()
{
    vec2 uv = openfl_TextureCoordv;

    //----------------------------------
    // VHS Horizontal Distortion
    //----------------------------------

    float wave = sin((uv.y * 10.0) + iTime * 7.0) * 0.0009;

    wave += sin((uv.y * 18.0) + iTime * 3.0) * 0.0002;

    uv.x += wave;

    //----------------------------------
    // Random VHS Glitch
    //----------------------------------

    float g = step(0.985, rand(vec2(iTime * 4.0, floor(uv.y * 300.0))));

    uv.x += g * 0.004;

    //----------------------------------
    // RGB Split
    //----------------------------------

    float split = 0.0005;

    vec4 r = flixel_texture2D(bitmap, uv + vec2(split,0.0));
    vec4 gCol = flixel_texture2D(bitmap, uv);
    vec4 b = flixel_texture2D(bitmap, uv - vec2(split,0.0));

    vec4 color;

    color.r = r.r;
    color.g = gCol.g;
    color.b = b.b;
    color.a = gCol.a;

    //----------------------------------
    // Scanlines
    //----------------------------------

    float scan = sin(uv.y * 900.0);

    color.rgb *= 1.0 - scan * 0.025;

    //----------------------------------
    // VHS Noise
    //----------------------------------

    float noise = rand(uv * iTime * 80.0);

    color.rgb += (noise - 0.5) * 0.08;

    //----------------------------------
    // Film Grain
    //----------------------------------

    float grain = rand(vec2(
        floor(uv.x * 700.0),
        floor(uv.y * 700.0 + iTime * 120.0)
    ));

    color.rgb += (grain - 0.5) * 0.03;

    //----------------------------------
    // Flicker
    //----------------------------------

    float flicker = 0.985 + sin(iTime * 15.0) * 0.02;

    color.rgb *= flicker;

    //----------------------------------
    // Vignette
    //----------------------------------

    vec2 center = uv - 0.5;

    float vig = smoothstep(0.85,0.15,length(center));

    color.rgb *= vig;

    //----------------------------------
    // Slight Green Tint
    //----------------------------------

    color.g += 0.01;

    //----------------------------------

    gl_FragColor = color;
}