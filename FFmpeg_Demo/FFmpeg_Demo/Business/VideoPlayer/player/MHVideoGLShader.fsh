
precision highp float;
varying   highp vec2  coordinate;

uniform   highp sampler2D SaY;
uniform   highp sampler2D SaU;
uniform   highp sampler2D SaV;


void main()
{
    highp vec3 Yuv;
    Yuv.x = texture2D(SaY,coordinate).r;
    Yuv.y = texture2D(SaU,coordinate).r-0.5;
    Yuv.z = texture2D(SaV,coordinate).r-0.5;
    //Rgb = Matrix * Yuv;
    highp vec3 Rgb = mat3(    1.0,      1.0,     1.0,
                   0.0, -0.39465, 2.03211,
               1.13983, -0.58080,     0.0) * Yuv;
    gl_FragColor = vec4(Rgb,1.0);
}


