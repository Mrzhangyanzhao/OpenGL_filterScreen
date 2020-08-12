//
//  ViewController.m
//  OpenGLESGLSL
//
//  Created by yz on 2020/8/2.
//  Copyright © 2020 yz. All rights reserved.
//

#import "ViewController.h"
#import "FilterBar.h"
#import <GLKit/GLKit.h>

typedef struct {
    GLKVector3 positionCoord; // (X, Y, Z)
    GLKVector2 textureCoord; // (U, V)
} SenceVertex;

@interface ViewController ()<FilterBarDelegate>

@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) CAEAGLLayer *eagLayer;
@property (assign, nonatomic) SenceVertex *vertices;

//着色器程序
@property (assign, nonatomic) GLuint myProgram;
//顶点缓存区
@property (assign, nonatomic) GLuint vertexBuffer;

//纹理id
@property (assign, nonatomic) GLuint textureId;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupFilterBar];
    
    //2.开辟顶点数组内存空间
    self.vertices = malloc(sizeof(SenceVertex) * 4);
    
    //3.初始化顶点(0,1,2,3)的顶点坐标以及纹理坐标
    self.vertices[0] = (SenceVertex){{-1, 1, 0}, {0, 1}};
    self.vertices[1] = (SenceVertex){{-1, -1, 0}, {0, 0}};
    self.vertices[2] = (SenceVertex){{1, 1, 0}, {1, 1}};
    self.vertices[3] = (SenceVertex){{1, -1, 0}, {1, 0}};
    
    [self setupCAEagLayer];
    [self setupContext];
    
    [self bindRenderBuffer:self.eagLayer];
    
    //6.获取处理的图片路径
    NSString *imagePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"timg.jpeg"];
    //读取图片
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    //将JPG图片转换成纹理图片
    GLuint textureID = [self creatTextureWithImage:image];
    //设置纹理ID
    self.textureId = textureID;  // 将纹理 ID 保存，方便后面切换滤镜的时候重用
    
    
    [self renderLayer];
    
    //9.设置默认着色器
//     [self setupShaderProgramWithName:@"namal"]; // 一开始选用默认的着色器
    [self setupShaderProgramWithName:@"SplitScreen9"];
    
    //10.将顶点缓存保存，退出时才释放
    [self startFilerAnimation];
    
    
    
    // Do any additional setup after loading the view.
}

// 开始一个滤镜动画
- (void)startFilerAnimation{
    //使用program
    glUseProgram(self.myProgram);
    //绑定buffer
    glBindBuffer(GL_ARRAY_BUFFER, self.vertexBuffer);
    
    // 清除画布
    glClear(GL_COLOR_BUFFER_BIT);
    glClearColor(1, 1, 1, 1);
    
    // 重绘
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    //渲染到屏幕上
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

//开始绘制
-(void)renderLayer{
    //7.设置视口
    glViewport(0, 0, self.drawableWidth, self.drawableHeight);
    
    //8.设置顶点缓存区
    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    GLsizeiptr bufferSizeBytes = sizeof(SenceVertex) * 4;
    glBufferData(GL_ARRAY_BUFFER, bufferSizeBytes, self.vertices, GL_STATIC_DRAW);
    self.vertexBuffer = vertexBuffer;
}

//设置上下文
-(void)setupContext{
    EAGLContext *context = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!context) {
        NSLog(@"creat context failed");
        return;
    }
    if (![EAGLContext setCurrentContext:context]) {
        NSLog(@"setup current context failed");
        return;
    }
    self.context = context;
}

-(void)setupCAEagLayer{
    CAEAGLLayer *layer = [[CAEAGLLayer alloc] init];
    //设置图层frame
    layer.frame = CGRectMake(30, 100, self.view.frame.size.width-60, self.view.frame.size.height-200);
    //设置图层的scale
    layer.contentsScale = [[UIScreen mainScreen] scale];
    //给View添加layer
    self.eagLayer = layer;
    [self.view.layer addSublayer:self.eagLayer];
}

//绑定渲染缓存区/帧缓存区
-(void)bindRenderBuffer:(CALayer <EAGLDrawable> *)layer{
    //定义渲染/帧缓存区
    GLuint renderBuffer,frameBuffer;
    //2.获取帧渲染缓存区名称,绑定渲染缓存区以及将渲染缓存区与layer建立连接
    glGenRenderbuffers(1, &renderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, renderBuffer);
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];
    
    //获取帧缓存区名称。绑定帧缓存区。将渲染缓存区附着到帧缓存区
    glGenFramebuffers(1, &frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, renderBuffer);
}


//加载纹理
-(GLuint)creatTextureWithImage:(UIImage *)image{
    //uiimage 转化CGImageRef
    CGImageRef spriteImage = image.CGImage;
    if (!spriteImage) {
        exit(1);
    }
    //获取image的width、height 、byte字节
    size_t with = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    void *imageData = malloc(with * height * 4);
    //获取图片字节数 宽 * 高 * 4
//    GLubyte *spriteData = (GLubyte *)calloc(width * height * 4, sizeof(GLubyte));
    
    CGRect rect = CGRectMake(0, 0, with, height);
    
    //获取图片颜色空间
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(spriteImage);
    
    //4.创建上下文
    /*
     参数1：data,指向要渲染的绘制图像的内存地址
     参数2：width,bitmap的宽度，单位为像素
     参数3：height,bitmap的高度，单位为像素
     参数4：bitPerComponent,内存中像素的每个组件的位数，比如32位RGBA，就设置为8
     参数5：bytesPerRow,bitmap的没一行的内存所占的比特数
     参数6：colorSpace,bitmap上使用的颜色空间  kCGImageAlphaPremultipliedLast：RGBA
     */
    CGContextRef context = CGBitmapContextCreate(imageData, with, height, 8, with * 4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    //将图片进行翻转
    CGContextTranslateCTM(context, 0, height);
    CGContextScaleCTM(context, 1.0f, -1.0f);
    CGColorSpaceRelease(colorSpace);
    CGContextClearRect(context, rect);
    
    //对图片进行重新绘制，得到一张新的解压缩后的位图
    CGContextDrawImage(context, rect, spriteImage);
    
    //设置纹理属性
    GLuint textureId;
    glGenTextures(1, &textureId);
    glBindTexture(GL_TEXTURE_2D, textureId);
    
    //在如2d纹理数据
    /*
    参数1：纹理模式，GL_TEXTURE_1D、GL_TEXTURE_2D、GL_TEXTURE_3D
    参数2：加载的层次，一般设置为0
    参数3：纹理的颜色值GL_RGBA
    参数4：宽
    参数5：高
    参数6：border，边界宽度
    参数7：format
    参数8：type
    参数9：纹理数据
    */
    float fw = with,fh=height;
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, fw, fh, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
    //设置纹理属性
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    //绑定纹理
    glBindTexture(GL_TEXTURE_2D, 0);
    //9.释放context,imageData
    CGContextRelease(context);
    free(imageData);
    
    //10.返回纹理ID
    return textureId;

}

//初始化着色器
// 初始化着色器程序
- (void)setupShaderProgramWithName:(NSString *)name {
    //1. 获取着色器program
    GLuint program = [self programWithShaderName:name];
    
    //2. use Program
    glUseProgram(program);
    
    //3. 获取Position,Texture,TextureCoords 的索引位置
    GLuint positionSlot = glGetAttribLocation(program, "position");
    GLuint textureSlot = glGetUniformLocation(program, "Texture");
    GLuint textureCoordsSlot = glGetAttribLocation(program, "textureCoord");
    
    //4.激活纹理,绑定纹理ID
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, self.textureId);
    
    //5.纹理sample
    glUniform1i(textureSlot, 0);
    
    //6.打开positionSlot 属性并且传递数据到positionSlot中(顶点坐标)
    glEnableVertexAttribArray(positionSlot);
    glVertexAttribPointer(positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(SenceVertex), NULL + offsetof(SenceVertex, positionCoord));
    
    //7.打开textureCoordsSlot 属性并传递数据到textureCoordsSlot(纹理坐标)
    glEnableVertexAttribArray(textureCoordsSlot);
    glVertexAttribPointer(textureCoordsSlot, 2, GL_FLOAT, GL_FALSE, sizeof(SenceVertex), NULL + offsetof(SenceVertex, textureCoord));
    
    //8.保存program,界面销毁则释放
    self.myProgram = program;
}

//link program
-(GLuint)programWithShaderName:(NSString *)shaderName{
    //1. 编译顶点着色器/片元着色器
    GLuint vertexShader = [self compileShaderWithName:shaderName type:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShaderWithName:shaderName type:GL_FRAGMENT_SHADER];
    
    //2. 将顶点/片元附着到program
    GLuint program = glCreateProgram();
    glAttachShader(program, vertexShader);
    glAttachShader(program, fragmentShader);
    
    //3.linkProgram
    glLinkProgram(program);
    
    //4.检查是否link成功
    GLint linkSuccess;
    glGetProgramiv(program, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(program, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSAssert(NO, @"program链接失败：%@", messageString);
        exit(1);
    }
    //5.返回program
    return program;
}


//编译shader
- (GLuint)compileShaderWithName:(NSString *)name type:(GLenum)shaderType{
    NSString *shaderPath = [[NSBundle mainBundle] pathForResource:name ofType:shaderType == GL_VERTEX_SHADER ? @"vsh" : @"fsh"];
    NSError *error;
    NSString *shaderString = [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:&error];
    if (!shaderString) {
        NSAssert(NO, @"读取shader失败");
        exit(1);
    }
    
    //创建shader
    GLuint shader = glCreateShader(shaderType);
    //3.获取shader source
    const char *shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLength = (int)[shaderString length];
    glShaderSource(shader, 1, &shaderStringUTF8, &shaderStringLength);
    
    //4.编译shader
    glCompileShader(shader);
    
    //链接shader
    GLint linkStatus;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &linkStatus);
    if (linkStatus == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(shader, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSAssert(NO, @"shader编译失败：%@", messageString);
        exit(1);
    }
    return shader;
}


//获取渲染缓存区的宽
- (GLint)drawableWidth {
    GLint backingWidth;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    return backingWidth;
}
//获取渲染缓存区的高
- (GLint)drawableHeight {
    GLint backingHeight;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
    return backingHeight;
}






// 创建滤镜栏
- (void)setupFilterBar {
    CGFloat filterBarWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat filterBarHeight = 100;
    CGFloat filterBarY = [UIScreen mainScreen].bounds.size.height - filterBarHeight;
    FilterBar *filerBar = [[FilterBar alloc] initWithFrame:CGRectMake(0, filterBarY, filterBarWidth, filterBarHeight)];
    filerBar.delegate = self;
    [self.view addSubview:filerBar];
    
    NSArray *dataSource = @[@"无",@"分屏_2",@"分屏_3",@"分屏_4",@"分屏_6",@"分屏_9"];
    filerBar.itemList = dataSource;
}
- (void)filterBar:(FilterBar *)filterBar didScrollToIndex:(NSUInteger)index{
    NSArray *filterArr = @[@"namal",@"SplitScreen2",@"SplitScreen3",@"SplitScreen4",@"SplitScreen6",@"SplitScreen9"];
    if (index < filterArr.count) {
        NSString *filterName = filterArr[index];
        [self setupShaderProgramWithName:filterName];
        [self startFilerAnimation];
    }
}

@end
