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

@interface MetaliicaView()

@property (nonatomic) CAMetalLayer *metalLayer;

@property (nonatomic) id<MTLDevice> metalDevice;

@property (nonatomic) id<MTLCommandQueue> mtlCommandQueue;

@property (nonatomic) id<MTLRenderPipelineState> renderPipelineState;

@property (nonatomic) id<MTLBuffer> vertexBuffer;

@property (nonatomic) id<MTLBuffer> colorBuffer;

@property (nonatomic) id<MTLBuffer> uniformBuffer;

@property (nonatomic) id<CAMetalDrawable> frameDrawable;

//@property (nonatomic) MCSceneMatrices sceneMatrcies;

//@property (nonatomic) id<MTLRenderCommandEncoder> renderEncoder;

@property (nonatomic) MCCamera *camera;

@end

@implementation MetaliicaView

- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self initMetalContext];
    }
    
    return self;
}

- (void)initMetalContext{
    [self.layer addSublayer:self.metalLayer];
    
    id<MTLDevice> mtlDevice = self.metalDevice;
    
    _mtlCommandQueue = [mtlDevice newCommandQueue];

    id<MTLLibrary> mtlLibrary = [mtlDevice newDefaultLibrary];
    id<MTLFunction> vertexProgram = [mtlLibrary newFunctionWithName:@"vertexShader"];
    id<MTLFunction> fragmentProgram = [mtlLibrary newFunctionWithName:@"fragmentShader"];
    MTLRenderPipelineDescriptor *mtlRenderPipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    [mtlRenderPipelineDescriptor setVertexFunction:vertexProgram];
    [mtlRenderPipelineDescriptor setFragmentFunction:fragmentProgram];
    mtlRenderPipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;

    _renderPipelineState = [mtlDevice newRenderPipelineStateWithDescriptor:mtlRenderPipelineDescriptor error:nil];
    
    double aspect = fabsf((self.frame.size.width) / (self.frame.size.height));
    _camera = [MCCamera cameraWithFov:GLKMathDegreesToRadians(60.0) aspect:aspect near:1. far:20.];
    _camera.position = GLKVector3Make(3, 3, 3);
    [_camera lookAt:GLKVector3Make(0, 0, 0)];
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

- (void)drawPlanes{
    _frameDrawable = [_metalLayer nextDrawable];
    
    MTLRenderPassDescriptor *mtlRenderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    mtlRenderPassDescriptor.colorAttachments[0].texture = _frameDrawable.texture;
    mtlRenderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    mtlRenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1.0, 1.0, 1.0, 1.0);
    mtlRenderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    
    id<MTLCommandBuffer> mtlCommandBuffer = [_mtlCommandQueue commandBuffer];
    id<MTLRenderCommandEncoder> renderEncoder = [mtlCommandBuffer renderCommandEncoderWithDescriptor:mtlRenderPassDescriptor];
    
    [renderEncoder setRenderPipelineState:_renderPipelineState];
    
    float w = 1;
    [self drawPlane:GLKVector3Make(w/2, w/2, 0) width:w height:w normal:GLKVector3Make(0, 0, 1) color:UIColor.redColor encoder:renderEncoder]; //xy
    [self drawPlane:GLKVector3Make(w/2, 0, w/2) width:w height:w normal:GLKVector3Make(0, 1, 0) color:UIColor.greenColor encoder:renderEncoder]; //xz
    [self drawPlane:GLKVector3Make(0, w/2, w/2) width:w height:w normal:GLKVector3Make(1, 0, 0) color:UIColor.blueColor encoder:renderEncoder]; //yz
    
    [renderEncoder endEncoding];
    
    [mtlCommandBuffer presentDrawable:_frameDrawable];
    [mtlCommandBuffer commit];
//    [self commitBuffer];
}

//- (void)drawPlanes_{
////    static float vertices[] = {
////        0.0, 0.5, 1.5, 1.0,
////        0.5, -0.5, 1.5, 1.0,
////        -0.5, -0.5, 1.5, 1.0
////    };
//
//    float vertBuf[1024];
//    float colorBuf[1024];
//
//    //xy plane
//    float w = 1;
//
//    //xy plane
//    float vertices0[] = {
//        0., 0., 0, 1.0,
//        w, w, 0, 1.0,
//        0., w, 0, 1.0,
//
//        0., 0., 0, 1.0,
//        w, 0., 0, 1.0,
//        w, w, 0, 1.0,
//    };
//
//    float colors0[] = {
//        1.0, 0.0, 0.0, 1.0,
//        1.0, 0.0, 0.0, 1.0,
//        1.0, 0.0, 0.0, 1.0,
//        1.0, 0.0, 0.0, 1.0,
//        1.0, 0.0, 0.0, 1.0,
//        1.0, 0.0, 0.0, 1.0
//    };
//
//    //xz plane
//    float vertices1[] = {
//        0., 0., 0, 1.0,
//        w, 0, w, 1.0,
//        0., 0, w, 1.0,
//
//        0., 0., 0, 1.0,
//        w, 0., w, 1.0,
//        w, 0, 0, 1.0,
//    };
//
//    float colors1[] = {
//        0.0, 1.0, 0.0, 1.0,
//        0.0, 1.0, 0.0, 1.0,
//        0.0, 1.0, 0.0, 1.0,
//        0.0, 1.0, 0.0, 1.0,
//        0.0, 1.0, 0.0, 1.0,
//        0.0, 1.0, 0.0, 1.0
//    };
//
//    //yz plane
//    float vertices2[] = {
//        0., 0., 0, 1.0,
//        0., w, w, 1.0,
//        0., 0., w, 1.0,
//
//        0., 0., 0, 1.0,
//        0., w, w, 1.0,
//        0., w, 0, 1.0,
//    };
//
//    float colors2[] = {
//        0.0, 0.0, 1.0, 1.0,
//        0.0, 0.0, 1.0, 1.0,
//        0.0, 0.0, 1.0, 1.0,
//        0.0, 0.0, 1.0, 1.0,
//        0.0, 0.0, 1.0, 1.0,
//        0.0, 0.0, 1.0, 1.0
//    };
//
//    int elementCount = 4 * 6;
//
//    memcpy(vertBuf, vertices0, elementCount * sizeof(float));
//    memcpy(vertBuf + elementCount, vertices1, elementCount * sizeof(float));
//    memcpy(vertBuf + 2 * elementCount, vertices2, elementCount * sizeof(float));
//
//    memcpy(colorBuf, colors0, elementCount * sizeof(float));
//    memcpy(colorBuf + elementCount, colors1, elementCount * sizeof(float));
//    memcpy(colorBuf + 2 * elementCount, colors2, elementCount * sizeof(float));
//
//    [self drawVertices:vertBuf colors:colorBuf length:3 * elementCount * sizeof(float)];
//
//}

- (void)drawVertices:(float *)vertices colors:(float *)colors length:(int)length encoder:(id<MTLRenderCommandEncoder>)renderEncoder{
    [self createBufferWithVertices:vertices colors:colors length:length];
    [self render:renderEncoder];
}

- (void)createBufferWithVertices:(float *)vertices colors:(float *)colors length:(int)length{
    _vertexBuffer = [_metalDevice newBufferWithBytes:vertices length:length options:MTLResourceOptionCPUCacheModeDefault];
    
    _colorBuffer = [_metalDevice newBufferWithBytes:colors length:length options:MTLResourceOptionCPUCacheModeDefault];
    
    [self.camera updateMatrices];
    
    MCSceneMatrices matrices = self.camera.matrices;
    
    _uniformBuffer = [_metalDevice newBufferWithBytes:&matrices length:sizeof(matrices) options:MTLResourceOptionCPUCacheModeDefault];
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


@end
