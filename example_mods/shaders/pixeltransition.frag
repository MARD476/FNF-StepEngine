#pragma header

uniform float progress_trans;

uniform vec4 transition_color;

void main()
{
    vec2 iResolution = openfl_TextureSize;
    vec2 uv = openfl_TextureCoordv;

    float t = progress_trans * 3.0;

    float Speed = 15.0;

    float res = floor(pow(t, 1.4) * Speed) * 2.0 + 0.01;

    uv *= iResolution / res;
    uv = floor(uv);
    uv /= iResolution / res;

    uv += res * 0.002;

    vec4 texture_pixelada = flixel_texture2D(bitmap, uv);

    float fade_start = 1.0;
    float fade_end = 2.0;

    float mix_factor = smoothstep(
        fade_start,
        fade_end,
        t
    );

    gl_FragColor = mix(
        texture_pixelada,
        transition_color,
        mix_factor
    );
}