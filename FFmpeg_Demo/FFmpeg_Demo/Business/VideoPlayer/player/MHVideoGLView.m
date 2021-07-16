//
//  MHVideoGLView.m
//  FFmpeg_Demo
//
//  Created by mahao on 2021/7/12.
//

#import "MHVideoGLView.h"
#import <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>
#import <GLKit/GLKit.h>
#import <sys/timeb.h>

@interface MHVideoGLView ()
{
    EAGLContext * _context;
    CAEAGLLayer * _eaglLayer;
    GLuint _program;
    GLuint _renderBuffer;
    GLuint _frameBuffer;
    
    GLuint _textures[3];
    GLint _uniformSamplers[3];
}
@end

@implementation MHVideoGLView
+ (Class)layerClass {
    return [CAEAGLLayer class];
}
-(instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor blackColor];
        
        [self createCAEAGLLayer];
        [self createEAGLContext];
        [self createProgram];
        [self setupFrame];
        [self createBuffer];
    }
    return self;
}
- (void)createCAEAGLLayer
{
    _eaglLayer = (CAEAGLLayer*) self.layer;
    _eaglLayer.opaque = YES;
    [self setContentScaleFactor:[[UIScreen mainScreen] scale]];
    _eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
}
- (int)createEAGLContext {
    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!_context) {
        NSLog(@"Failed to initialize OpenGLES 2.0 context");
        return -1;
    }
    if (![EAGLContext setCurrentContext:_context]) {
        _context = nil;
        NSLog(@"Failed to set current OpenGL context");
        return -2;
    }
    glEnable(GL_DEPTH_TEST);
    return 0;
}
- (int)createProgram
{
    //加载shader
    _program = [self loadShaders];
    //链接
    glLinkProgram(_program);
    GLint linkSuccess;
    glGetProgramiv(_program, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) { //连接错误
        GLchar messages[256];
        glGetProgramInfoLog(_program, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"Shader Program Error:%@", messageString);
        return -1;
    }
    glUseProgram(_program); //成功便使用，避免由于未使用导致的的bug
    _uniformSamplers[0] = glGetUniformLocation(_program, "SaY");
    _uniformSamplers[1] = glGetUniformLocation(_program, "SaU");
    _uniformSamplers[2] = glGetUniformLocation(_program, "SaV");
    return 0;
}
- (void)setupFrame
{
    GLfloat width  = self.frame.size.width * [[UIScreen mainScreen] scale];
    GLfloat height = self.frame.size.height * [[UIScreen mainScreen] scale];
    [EAGLContext setCurrentContext:_context];
    glViewport(0, 0, width, height);
}
- (void)destoryBuffer
{
    glDeleteFramebuffers(1, &_frameBuffer);
    _frameBuffer = 0;
    glDeleteRenderbuffers(1, &_renderBuffer);
    _renderBuffer = 0;
}
- (void)createBuffer
{
    [EAGLContext setCurrentContext:_context];
    [self destoryBuffer];
    glGenFramebuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    
    glGenRenderbuffers(1, &_renderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderBuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
}
void bindTexture(GLuint texture, const char *buffer, int w , int h)
{
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D( GL_TEXTURE_2D, 0, GL_LUMINANCE, w, h, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, buffer);
}
-(void)render:(MHVideoFrame *)frame
{
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    const int frameWidth = (int)frame.width;
    const int frameHeight = (int)frame.height;
    const char *pixels[3] = {frame.luma, frame.chromaB, frame.chromaR };
    const int widths[3]  = {frameWidth, frameWidth/2, frameWidth/2};
    const int heights[3] = {frameHeight, frameHeight/2, frameHeight/2};
    
    if (_textures[0] == 0) {
        glGenTextures(3, _textures);
    }
    for (int i = 0; i < 3; i ++) {
        bindTexture(_textures[i], pixels[i], widths[i], heights[i]);
    }
    for (int i = 0; i < 3; ++i) {
        glActiveTexture(GL_TEXTURE0 + i);
        glBindTexture(GL_TEXTURE_2D, _textures[i]);
        glUniform1i(_uniformSamplers[i], i);
    }

    GLfloat positionData[] =
    {
        -1.0, -1.0, 0.0f,
        -1.0, 1.0, 0.0f,
        1.0, -1.0, 0.0f,
        1.0, 1.0, 0.0f,
    };
    GLint position = glGetAttribLocation(_program, "position");
    glVertexAttribPointer(position,3,GL_FLOAT,GL_FALSE,sizeof(GLfloat)*3,positionData);
    glEnableVertexAttribArray(position);

    GLfloat textCoordinateData[] =
    {
        0.0, 1.0, //左上
        0.0, 0.0, //左下
        1.0, 1.0, //右上
        1.0, 0.0, //右下
    };
    GLint textCoordinate = glGetAttribLocation(_program, "textCoordinate");
    glVertexAttribPointer(textCoordinate,2,GL_FLOAT,GL_FALSE,sizeof(GLfloat)*2,textCoordinateData);
    glEnableVertexAttribArray(textCoordinate);
    
    
    
    CGFloat screenScale = [[UIScreen mainScreen] scale];
    CGFloat width  = self.frame.size.width  * screenScale;
    CGFloat height = self.frame.size.height * screenScale;
    CGFloat kwScale = width / frame.width;
    CGFloat khScale = height / frame.height;
    CGFloat scaleW = 1.0;
    CGFloat scaleH = 1.0;
    if (kwScale > khScale) {
        scaleH = 1.0;
        scaleW = frame.width * khScale / width;
    }else{
        scaleW = 1.0;
        scaleH = frame.height * kwScale / height;
    }
    glUniform1f(glGetUniformLocation(_program, "WScale"), scaleW);
    glUniform1f(glGetUniformLocation(_program, "HScale"), scaleH);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}
-(void)destoryPlayer
{
    [self destoryBuffer];
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
    glDeleteTextures(3, _textures);
    glDeleteProgram(_program);
    if(_context){
        _context = NULL;
    }
}
-(void)dealloc
{
    NSLog(@"YXLivePlayer--dealloc");
}
#pragma mark - 初始化着色器
- (GLuint)loadShaders
{
    GLuint vertShader = 0;
    GLuint fragShader = 0;

    //创建着色器程序
    GLint program = glCreateProgram();

    NSURL * vertUrl = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"MHVideoGLShader" ofType:@"vsh"]];
    NSURL * fragUrl = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"MHVideoGLShader" ofType:@"fsh"]];

    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER URL:vertUrl]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }

    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER URL:fragUrl]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    //绑定顶点着色器
    glAttachShader(program, vertShader);
    //绑定片段着色器
    glAttachShader(program, fragShader);
    //两个着色器都已绑定到着色器程序上了，删除
    glDeleteShader(vertShader);
    glDeleteShader(fragShader);
    return program;
}
#pragma mark - 创建着色器
-(BOOL)compileShader:(GLuint *)shader type:(GLenum)type URL:(NSURL *)URL
{
    NSError * error;
    NSString * sourceString = [NSString stringWithContentsOfURL:URL encoding:NSUTF8StringEncoding error:&error];
    if (!sourceString) {
        NSLog(@"Failed to load vertex shader: %@", [error localizedDescription]);
        return NO;
    }
    
    const GLchar * source = (GLchar *)[sourceString UTF8String];
    return [self compileShaderString:shader type:type shaderString:source];
}
-(BOOL)compileShaderString:(GLuint *)shader type:(GLenum)type shaderString:(const GLchar*)shaderString
{
    *shader = glCreateShader(type);
    //加载着色器源码
    glShaderSource(*shader, 1, &shaderString, NULL);
    //编译着色器
    glCompileShader(*shader);
    // 获取结果，没获取到就释放内存
    GLint status = 0;
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0)
    {
        glDeleteShader(*shader);
        return NO;
    }
    return YES;
}
@end
