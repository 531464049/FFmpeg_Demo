

precision highp float;
attribute highp vec4  position;
attribute highp vec2  textCoordinate;
varying   highp vec2  coordinate;

uniform   highp float WScale;  //贴图x轴放大缩小倍数
uniform   highp float HScale;  //贴图y轴放大缩小倍数

void main( )
{
    highp mat4 WScaleMat = mat4(WScale, 0.0, 0.0, 0.0,
                          0.0, HScale, 0.0, 0.0,
                          0.0, 0.0, 1.0, 0.0,
                          0.0, 0.0, 0.0, 1.0);
    gl_Position = position * WScaleMat;
    coordinate = textCoordinate;
}
