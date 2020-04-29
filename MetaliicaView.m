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

typedef struct tagMTLSceneMatrices {
    GLKMatrix4 projectionMatrix;
    GLKMatrix4 modelviewMatrix;
} MTLSceneMatrices;

@interface MetaliicaView()

@property (nonatomic) CAMetalLayer *metalLayer;

@property (nonatomic) id<MTLDevice> metalDevice;

@property (nonatomic) id<MTLCommandQueue> mtlCommandQueue;

@property (nonatomic) id<MTLRenderPipelineState> renderPipelineState;

@property (nonatomic) id<MTLBuffer> vertexBuffer;

@property (nonatomic) id<MTLBuffer> colorBuffer;

@property (nonatomic) id<MTLBuffer> uniformBuffer;

@property (nonatomic) id<CAMetalDrawable> frameDrawable;

@property (nonatomic) MTLSceneMatrices sceneMatrcies;

@property (nonatomic) id<MTLRenderCommandEncoder> renderEncoder;

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
}

- (void)drawPlanes{
//    static float vertices[] = {
//        0.0, 0.5, 1.5, 1.0,
//        0.5, -0.5, 1.5, 1.0,
//        -0.5, -0.5, 1.5, 1.0
//    };
    
    static float vertices[] = {
        0.0, 5., -15.5, 1.0,
        5., -5., -15.5, 1.0,
        -5., -5., -15.5, 1.0
    };
    
//    static float vertices[] = {
//        0.0, 5., -1.5, 1.0,
//        5., -5., -1.5, 1.0,
//        -5., -5., -1.5, 1.0
//    };

    static float colors[] = {
            1.0, 0.0, 0.0, 1.0,
            0.0, 1.0, 0.0, 1.0,
            0.0, 0.0, 1.0, 1.0
    };
    
    
    GLKMatrix4 mv = GLKMatrix4Multiply( GLKMatrix4MakeTranslation(0, 0, -15.5), GLKMatrix4MakeRotation(M_PI_4 * 3, 0, 1, 0));
    mv = GLKMatrix4Multiply( mv, GLKMatrix4MakeTranslation(0, 0, 15.5));
    
    [self drawVertices:vertices colors:colors length:sizeof(vertices) modelViewMatrix:mv];
    
}

- (void)drawVertices:(float *)vertices colors:(float *)colors length:(int)length modelViewMatrix:(GLKMatrix4)mv{
    [self createBufferWithVertices:vertices colors:colors length:length modelViewMatrix:mv];
    [self render];
}

- (void)createBufferWithVertices:(float *)vertices colors:(float *)colors length:(int)length modelViewMatrix:(GLKMatrix4)mv{
    _vertexBuffer = [_metalDevice newBufferWithBytes:vertices length:length options:MTLResourceOptionCPUCacheModeDefault];
    
    _colorBuffer = [_metalDevice newBufferWithBytes:colors length:length options:MTLResourceOptionCPUCacheModeDefault];
    
    double aspect = fabsf((self.frame.size.width) / (self.frame.size.height));
    
    _sceneMatrcies.modelviewMatrix = mv;
    
    _sceneMatrcies.projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(60.0), aspect, 1.0, 20.0);
    
    _uniformBuffer = [_metalDevice newBufferWithBytes:&_sceneMatrcies length:sizeof(_sceneMatrcies) options:MTLResourceOptionCPUCacheModeDefault];
}

- (void)render{
    _frameDrawable = [_metalLayer nextDrawable];
    
//    NSLog(@"_frameDrawable.texture is %@", _frameDrawable.texture);
    
    id<MTLCommandBuffer> mtlCommandBuffer = [_mtlCommandQueue commandBuffer];

    MTLRenderPassDescriptor *mtlRenderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    mtlRenderPassDescriptor.colorAttachments[0].texture = _frameDrawable.texture;
    mtlRenderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    mtlRenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1.0, 1.0, 1.0, 1.0);
    mtlRenderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;

    id<MTLRenderCommandEncoder> renderEncoder = [mtlCommandBuffer renderCommandEncoderWithDescriptor:mtlRenderPassDescriptor];
    [renderEncoder setRenderPipelineState:_renderPipelineState];
    
    [renderEncoder setVertexBuffer:_vertexBuffer offset:0 atIndex:0];
    [renderEncoder setVertexBuffer:_colorBuffer offset:0 atIndex:1];
    [renderEncoder setVertexBuffer:_uniformBuffer offset:0 atIndex:2];
    
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
    [renderEncoder endEncoding];
    
    [mtlCommandBuffer presentDrawable:_frameDrawable];
    [mtlCommandBuffer commit];
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
