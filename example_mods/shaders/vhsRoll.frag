#pragma header

uniform float iTime;
uniform float transition;

float rand(vec2 co)
{
    return fract(sin(dot(co.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

void main()
{
    vec2 uv = openfl_TextureCoordv;
    float t = clamp(transition,0.0,1.0);

    //------------------------------------------
    // Vertical Roll
    //------------------------------------------

    uv.y += t * (
        0.18*sin(iTime*18.0)
        +0.05*sin(iTime*42.0)
    );

    //------------------------------------------
    // Horizontal Tracking
    //------------------------------------------

    uv.x +=
        sin(uv.y*7800.0+iTime*35.0)
        *0.02*t;

    //------------------------------------------
    // Random Horizontal Tear
    //------------------------------------------

    float tear =
        step(
            0.985,
            rand(vec2(
                floor(uv.y*500.0),
                floor(iTime*18.0)))
        );

    uv.x += tear * 0.08 * t;

    //------------------------------------------
    // Screen Jump
    //------------------------------------------

    float jump =
        step(
            0.992,
            rand(vec2(
                floor(iTime*9.0),0.0))
        );

    uv.y += jump * 0.10 * t;

    //------------------------------------------
    // Blur
    //------------------------------------------

    float blur = 0.004 * t;

    vec4 col =
    (
        flixel_texture2D(bitmap,uv)+
        flixel_texture2D(bitmap,uv+vec2( blur,0.0))+
        flixel_texture2D(bitmap,uv+vec2(-blur,0.0))+
        flixel_texture2D(bitmap,uv+vec2(0.0, blur))+
        flixel_texture2D(bitmap,uv+vec2(0.0,-blur))
    )/5.0;

    //------------------------------------------
    // RGB Split
    //------------------------------------------

    float split = 0.006*t;

    vec4 r = flixel_texture2D(bitmap,uv+vec2(split,0.0));
    vec4 g = col;
    vec4 b = flixel_texture2D(bitmap,uv-vec2(split,0.0));

    vec4 color;

    color.r=r.r;
    color.g=g.g;
    color.b=b.b;
    color.a=g.a;

    //------------------------------------------
    // VHS Noise
    //------------------------------------------

    float noise =
        rand(uv*iTime*250.0);

    color.rgb +=
        (noise-0.5)
        *0.18
        *t;

    //------------------------------------------
    // Scanlines
    //------------------------------------------

    float scan =
        sin(uv.y*1200.0);

    color.rgb *=
        1.0
        -scan
        *0.05
        *t;

    //------------------------------------------
    // Thick Tracking Band
    //------------------------------------------

    float bandPos =
        fract(iTime*1.6);

    float band =
        smoothstep(
            0.18,
            0.0,
            abs(uv.y-bandPos)
        );

    color.rgb *=
        1.0
        -
        band
        *
        0.85
        *
        t;

    //------------------------------------------
    // Flicker
    //------------------------------------------

    color.rgb *=
        1.0
        -
        t*0.20
        +
        sin(iTime*25.0)*0.03*t;

    //------------------------------------------
    // Dark
    //------------------------------------------

    color.rgb *=
        mix(
            1.0,
            0.55,
            t
        );

    //------------------------------------------
    // CRT Curvature
    //------------------------------------------

    vec2 p = uv*2.0-1.0;
    p *= 1.0 + dot(p,p)*0.04*t;

    //------------------------------------------

    gl_FragColor = color;
}