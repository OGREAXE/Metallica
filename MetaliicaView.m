//
//  MetaliicaView.m
//  Metallica
//
//  Created by Liang,Zhiyuan(MTD) on 2020/4/27.
//  Copyright © 2020 Liang,Zhiyuan(MTD). All rights reserved.
//

#import "MetaliicaView.h"
#import <Metal/Metal.h>
#import <GLKit/GLKit.h>
#import "MCCamera.h"
#import <math.h>
#import "MCDirectionalLight.h"

@interface MetaliicaView()

@property (nonatomic) CAMetalLayer *metalLayer;

@property (nonatomic) id<MTLDevice> metalDevice;

@property (nonatomic) id<MTLCommandQueue> mtlCommandQueue;

@property (nonatomic) id<MTLRenderPipelineState> renderPipelineState;

@property (nonatomic) id<MTLRenderPipelineState> shadowGenPipelineState;

@property (nonatomic) id<MTLDepthStencilState> meshDepthStencilState;

@property (nonatomic) id<MTLDepthStencilState> shadowDepthStencilState;

@property (nonatomic) id<MTLBuffer> vertexBuffer;

@property (nonatomic) id<MTLBuffer> colorBuffer;

@property (nonatomic) id<MTLBuffer> uniformBuffer;

@property (nonatomic) id<CAMetalDrawable> frameDrawable;

@property (nonatomic) id<MTLTexture> depthTexture;

//@property (nonatomic) MCSceneMatrices sceneMatrcies;

//@property (nonatomic) id<MTLRenderCommandEncoder> renderEncoder;

@property (nonatomic) MCCamera *camera;

@property (nonatomic) MCDirectionalLight *sun;

//@property (nonatomic) MCSceneMatrices currentMatrices;

@property (nonatomic) MCSceneUniform currentUniform;

@property (nonatomic) UIImageView *depthRevealView;

@property (nonatomic) float *depthBuf;

@end

@implementation MetaliicaView

- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self initMetalContext];
        
        UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 60, 200, 200)];
        imgView.backgroundColor = [UIColor blackColor];
        [self addSubview:imgView];
        
        _depthRevealView = imgView;
        _depthBuf = (float *)malloc(sizeof(float) * 2048  * 2048);
    }
    
    return self;
}

- (void)initMetalContext{
    [self.layer addSublayer:self.metalLayer];
    
    id<MTLDevice> mtlDevice = self.metalDevice;
    
    _mtlCommandQueue = [mtlDevice newCommandQueue];

    id<MTLLibrary> mtlLibrary = [mtlDevice newDefaultLibrary];
    
    NSError *error;
    
    {
        id<MTLFunction> vertexProgram = [mtlLibrary newFunctionWithName:@"vertexShader"];
        id<MTLFunction> fragmentProgram = [mtlLibrary newFunctionWithName:@"fragmentShader"];
        
        MTLRenderPipelineDescriptor *mtlRenderPipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        [mtlRenderPipelineDescriptor setVertexFunction:vertexProgram];
        [mtlRenderPipelineDescriptor setFragmentFunction:fragmentProgram];
        mtlRenderPipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
        mtlRenderPipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;

        _renderPipelineState = [mtlDevice newRenderPipelineStateWithDescriptor:mtlRenderPipelineDescriptor error:nil];
    }
    
    {
        //shadow gen
        id <MTLFunction> shadowVertexFunction = [mtlLibrary newFunctionWithName:@"shadow_vertex"];

        MTLRenderPipelineDescriptor *renderPipelineDescriptor = [MTLRenderPipelineDescriptor new];
        renderPipelineDescriptor.label = @"Shadow Gen";
        renderPipelineDescriptor.vertexDescriptor = nil;
        renderPipelineDescriptor.vertexFunction = shadowVertexFunction;
        renderPipelineDescriptor.fragmentFunction = nil;
        renderPipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;

        _shadowGenPipelineState = [mtlDevice newRenderPipelineStateWithDescriptor:renderPipelineDescriptor error:&error];
    }
    
    {
        MTLDepthStencilDescriptor *depthStateDesc = [MTLDepthStencilDescriptor new];
        depthStateDesc.label = @"Shadow Gen";
//        depthStateDesc.depthCompareFunction = MTLCompareFunctionGreaterEqual;
        depthStateDesc.depthCompareFunction = MTLCompareFunctionLessEqual;
        depthStateDesc.depthWriteEnabled = YES;
        _shadowDepthStencilState = [mtlDevice newDepthStencilStateWithDescriptor:depthStateDesc];
    }
    
    {
        MTLDepthStencilDescriptor *depthStateDesc = [MTLDepthStencilDescriptor new];
        depthStateDesc.label = @"mesh render";
//        depthStateDesc.depthCompareFunction = MTLCompareFunctionGreaterEqual;
        depthStateDesc.depthCompareFunction = MTLCompareFunctionLessEqual;
        depthStateDesc.depthWriteEnabled = YES;
        _meshDepthStencilState = [mtlDevice newDepthStencilStateWithDescriptor:depthStateDesc];
    }
    
    double aspect = fabsf((self.frame.size.width) / (self.frame.size.height));
    _camera = [MCCamera cameraWithFov:GLKMathDegreesToRadians(60.0) aspect:aspect near:1. far:20.];
    _camera.position = GLKVector3Make(3, 1.5, 3);
//    _camera.position = GLKVector3Make(0, 10, 0);
    [_camera lookAt:GLKVector3Make(0, 0, 0)];
    
    _sun = [[MCDirectionalLight alloc] init];
    _sun.position = GLKVector3Make(0.01, 2.2, 0.01);
    [_sun lookAt:GLKVector3Make(0, 0, 0)];
    
    {
        MTLTextureDescriptor *shadowTextureDesc =
            [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatDepth32Float
                                                               width:2048
                                                              height:2048
                                                           mipmapped:NO];
        
        shadowTextureDesc.resourceOptions = MTLResourceStorageModeShared;
        shadowTextureDesc.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
        
        _sun.shadowMap = [self.metalDevice newTextureWithDescriptor:shadowTextureDesc];
        _sun.shadowMap.label = @"Shadow Map";
    }
    
    {
        MTLTextureDescriptor *depthTextureDesc =
        [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatDepth32Float
                                                           width:2048
                                                          height:2048
                                                       mipmapped:NO];

        depthTextureDesc.resourceOptions = MTLResourceStorageModePrivate;
        depthTextureDesc.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
        
        _depthTexture = [self.metalDevice newTextureWithDescriptor:depthTextureDesc];
        _depthTexture.label = @"depth texture";
    }
    
    
//    CIImage *image = [CIImage imageWithMTLTexture:_sun.shadowMap options:nil];
//    UIImage *uiImg = [UIImage imageWithCIImage:image];
//
//    UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 100, 100)];
//    imgView.image = uiImg;
//    [self addSubview:imgView];
}

- (void)renderView{
    id<MTLCommandBuffer> commandBuffer = [_mtlCommandQueue commandBuffer];
    
    [self drawDirectionalLight:commandBuffer];
    
    [self drawPlanes:commandBuffer];
    [commandBuffer presentDrawable:_frameDrawable];
    
    [commandBuffer commit];
    
    [self debugDrawDepthMap];
}

- (CGImageRef)imageRefFromBGRABytes:(unsigned char *)imageBytes imageSize:(CGSize)imageSize {
 
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(imageBytes,
                                                imageSize.width,
                                                imageSize.height,
                                                8,
                                                imageSize.width * 4,
                                                colorSpace,
                                                kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    return imageRef;
}

- (void)drawDirectionalLight:(id<MTLCommandBuffer>)commandBuffer{
    MTLRenderPassDescriptor *shadowRenderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    
    shadowRenderPassDescriptor.depthAttachment.texture = _sun.shadowMap;
    shadowRenderPassDescriptor.depthAttachment.loadAction = MTLLoadActionClear;
    shadowRenderPassDescriptor.depthAttachment.storeAction = MTLStoreActionStore;
    shadowRenderPassDescriptor.depthAttachment.clearDepth = 1.0;
    
//    id<MTLCommandBuffer> commandBuffer = [_mtlCommandQueue commandBuffer];
    
    id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:shadowRenderPassDescriptor];
    
    [encoder setRenderPipelineState:_shadowGenPipelineState];
    [encoder setDepthStencilState:_shadowDepthStencilState];
    [encoder setDepthBias:0.015 slopeScale:7 clamp:0.02]; //will display incorrect shadow glitch without this line
    
    [self.sun updateMatrices];
    _currentUniform.shadowMatrices = self.sun.matrices;
    
    [self drawPlanesWithEncoder:encoder];
    
    [encoder endEncoding];
}

- (void)drawPlanes:(id<MTLCommandBuffer>)mtlCommandBuffer{
    _frameDrawable = [_metalLayer nextDrawable];
    
    MTLRenderPassDescriptor *mtlRenderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    mtlRenderPassDescriptor.colorAttachments[0].texture = _frameDrawable.texture;
    mtlRenderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    mtlRenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1.0, 1.0, 1.0, 1.0);
    mtlRenderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    
    mtlRenderPassDescriptor.depthAttachment.texture = _depthTexture;
    
//    id<MTLCommandBuffer> mtlCommandBuffer = [_mtlCommandQueue commandBuffer];
    id<MTLRenderCommandEncoder> renderEncoder = [mtlCommandBuffer renderCommandEncoderWithDescriptor:mtlRenderPassDescriptor];
    
    [renderEncoder setRenderPipelineState:_renderPipelineState];
    [renderEncoder setDepthStencilState:_meshDepthStencilState];
    
    [self.camera updateMatrices];
    _currentUniform.meshMatrices = self.camera.matrices;
    
    [renderEncoder setFragmentTexture:_sun.shadowMap atIndex:3];
    [renderEncoder setFragmentBuffer:_uniformBuffer offset:0 atIndex:1];
    
    [self drawPlanesWithEncoder:renderEncoder];
    
    [renderEncoder endEncoding];
    
//    [mtlCommandBuffer presentDrawable:_frameDrawable];
//    [mtlCommandBuffer commit];
}

- (void)drawPlanesWithEncoder:(id<MTLRenderCommandEncoder>)renderEncoder{
    float w = 1;
    [self drawPlane:GLKVector3Make(w/2, w/2, 0) width:w height:w normal:GLKVector3Make(0, 0, 1) color:UIColor.redColor encoder:renderEncoder]; //xy
    [self drawPlane:GLKVector3Make(w/2, 0, w/2) width:w height:w normal:GLKVector3Make(0, 1, 0) color:UIColor.greenColor encoder:renderEncoder]; //xz
    [self drawPlane:GLKVector3Make(0, w/2, w/2) width:w height:w normal:GLKVector3Make(1, 0, 0) color:UIColor.blueColor encoder:renderEncoder]; //yz
    
    [self drawPlane:GLKVector3Make(0, -2, 0) width:3 * w height:3 * w normal:GLKVector3Make(0, 1, 0) color:UIColor.magentaColor encoder:renderEncoder]; //ground
}

- (void)drawPlane:(GLKVector3)position width:(float)width height:(float)height normal:(GLKVector3)normal color:(UIColor *)color encoder:(id<MTLRenderCommandEncoder>)renderEncoder{
    //original normal is (0, 0, 1)
    float vertices[] = {
        - width/2, - height/2., 0, 1.0,
        width/2, height/2, 0, 1.0,
        - width/2., height/2, 0, 1.0,
        
        - width/2., - height/2, 0, 1.0,
        width/2., - height/2, 0, 1.0,
        width/2., height/2, 0, 1.0,
    };
    
    normal = GLKVector3Normalize(normal);
    float angle = acosf(GLKVector3DotProduct(normal, GLKVector3Make(0, 0, 1)));
    GLKVector3 axis = GLKVector3CrossProduct(normal, GLKVector3Make(0, 0, 1));
    if (GLKVector3AllEqualToVector3(axis, GLKVector3Make(0, 0, 0))) {
        axis = GLKVector3Make(0, 1, 0);
    }
    
    for (int i = 0; i < 6; i++) {
        GLKMatrix3 rotMat = GLKMatrix3MakeRotation(angle, axis.x, axis.y, axis.z);
        int arrOffset = i * 4;
        GLKVector3 rotatedVertex = GLKVector3Make(vertices[arrOffset], vertices[arrOffset + 1], vertices[arrOffset + 2]);
        rotatedVertex = GLKMatrix3MultiplyVector3(rotMat, rotatedVertex);
        
        vertices[arrOffset] = rotatedVertex.x + position.x;
        vertices[arrOffset + 1] = rotatedVertex.y  + position.y;
        vertices[arrOffset + 2] = rotatedVertex.z +  + position.z;
    }
    
    CGFloat red = 0;
    CGFloat green = 0;
    CGFloat blue = 0;
    CGFloat alpha = 0;
    
    [color getRed:&red green:&green blue:&blue alpha:&alpha];
    
    float colors[] = {
        red, green, blue, alpha,
        red, green, blue, alpha,
        red, green, blue, alpha,
        red, green, blue, alpha,
        red, green, blue, alpha,
        red, green, blue, alpha,
    };
    
    [self drawVertices:vertices colors:colors length:4 * 6 * sizeof(float) encoder:renderEncoder];
}

- (void)drawVertices:(float *)vertices colors:(float *)colors length:(int)length encoder:(id<MTLRenderCommandEncoder>)renderEncoder{
    [self createBufferWithVertices:vertices colors:colors length:length];
    [self render:renderEncoder];
}

- (void)createBufferWithVertices:(float *)vertices colors:(float *)colors length:(int)length{
    _vertexBuffer = [_metalDevice newBufferWithBytes:vertices length:length options:MTLResourceOptionCPUCacheModeDefault];
    
    _colorBuffer = [_metalDevice newBufferWithBytes:colors length:length options:MTLResourceOptionCPUCacheModeDefault];
    
    _uniformBuffer = [_metalDevice newBufferWithBytes:&_currentUniform length:sizeof(_currentUniform) options:MTLResourceOptionCPUCacheModeDefault];
}

- (void)render:(id<MTLRenderCommandEncoder>)renderEncoder{
    
//    NSLog(@"_frameDrawable.texture is %@", _frameDrawable.texture);
    
//    id<MTLCommandBuffer> mtlCommandBuffer = [_mtlCommandQueue commandBuffer];

//    id<MTLRenderCommandEncoder> renderEncoder = [mtlCommandBuffer renderCommandEncoderWithDescriptor:mtlRenderPassDescriptor];
    
    [renderEncoder setVertexBuffer:_vertexBuffer offset:0 atIndex:0];
    [renderEncoder setVertexBuffer:_colorBuffer offset:0 atIndex:1];
    [renderEncoder setVertexBuffer:_uniformBuffer offset:0 atIndex:2];
    
//    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:_vertexBuffer.length];
    int vertCount = (_vertexBuffer.length/ sizeof(float))/4;
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:vertCount];
    
    //index
//    int indices[] = {0, 1, 2, 0, 1, 4, 6, 7, 8, 6, 7, 11};
//    id<MTLBuffer> indexBuffer = [_metalDevice newBufferWithBytes:indices length:sizeof(int) * 12 options:MTLResourceOptionCPUCacheModeDefault];
//    [renderEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle indexCount:12 indexType:MTLIndexTypeUInt32 indexBuffer:indexBuffer indexBufferOffset:0];

    //
//    [mtlCommandBuffer presentDrawable:_frameDrawable];
//    [mtlCommandBuffer commit];
}

- (CAMetalLayer *)metalLayer{
    if (!_metalLayer) {
        id<MTLDevice> device = self.metalDevice;
        CAMetalLayer *metalLayer = [CAMetalLayer layer];
        metalLayer.device = device;
        metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
        metalLayer.framebufferOnly = YES;
        
        metalLayer.frame = self.layer.frame;
        CGSize drawableSize = self.bounds.size;
        drawableSize.width *= self.contentScaleFactor;
        drawableSize.height *= self.contentScaleFactor;
        metalLayer.drawableSize = drawableSize;
        
        _metalLayer =  metalLayer;
    }
    
    return _metalLayer;;
}

- (id<MTLDevice>)metalDevice{
    if (!_metalDevice) {
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        _metalDevice = device;
    }
    return _metalDevice;
}

- (void)debugDrawDepthMap{
//    {
//        GLKVector4 testV = GLKVector4Make(-1, 0, 1, 1); //578
////        GLKVector4 testV = GLKVector4Make(0, 0, -3, 1); //584
//        GLKVector4 testV_mvp = GLKMatrix4MultiplyVector4(_sun.matrices.modelviewMatrix, testV);
//        GLKVector4 testV_ndc = GLKMatrix4MultiplyVector4(_sun.matrices.projectionMatrix, testV_mvp);
//    }
    //depth
    float *depthBuf = _depthBuf;
    memset(depthBuf, 0, sizeof(float) * 2048  * 2048);

    [_sun.shadowMap getBytes:depthBuf bytesPerRow:sizeof(float) * 2048 fromRegion:MTLRegionMake2D(0, 0, 2048, 2048) mipmapLevel:0];
    
    float maxDetpth = 0, minDepth = 1;
    for (int i = 0; i < 2048 * 2048; i++) {
        float k = depthBuf[i];
        if (k > maxDetpth && k != 1) {
            maxDetpth = k;
        }
        if (k < minDepth && k != 0) {
            minDepth = k;
        }
    }
    
//    NSLog(@"max depth is %.5f, min depth is %.5f", maxDetpth, minDepth);
    
    for (int i = 0; i < 2048 * 2048; i++) {
        if (YES /*depthBuf[i] != 0 && depthBuf[i] != 1*/) {
            float k = depthBuf[i];
            
            unsigned char *p = depthBuf + i;
            
            float decay = (maxDetpth - k)/(maxDetpth - minDepth);
            
            p[0] = (unsigned char)(256.0f * decay);
            p[1] = (unsigned char)(256.0f * decay);
            p[2] = (unsigned char)(256.0f * decay);
            p[3] = 1;
        }
    }
    
    CGImageRef imageRef = [self imageRefFromBGRABytes:(unsigned char *)depthBuf imageSize:CGSizeMake(2048, 2048)];
    UIImage *image = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    _depthRevealView.image = image;
}

@end
