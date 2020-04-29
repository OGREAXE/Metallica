//
//  MCCamera.h
//  Metallica
//
//  Created by Liang,Zhiyuan(GIS)2 on 2020/4/29.
//  Copyright © 2020 Liang,Zhiyuan(MTD). All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

typedef struct tagMTLSceneMatrices {
    GLKMatrix4 projectionMatrix;
    GLKMatrix4 modelviewMatrix;
} MCSceneMatrices;

NS_ASSUME_NONNULL_BEGIN

@interface MCCamera : NSObject

@property (nonatomic) GLKVector3 position;

//@property (nonatomic) GLKVector3 up;

@property (nonatomic, readonly) GLKVector3 lookAtPoint;

@property (nonatomic, readonly) MCSceneMatrices matrices;

- (void)lookAt:(GLKVector3)point;

+ (MCCamera *)cameraWithFov:(float)fov aspect:(float)aspect near:(float)near far:(float)far;

- (void)updateMatrices;

@end

NS_ASSUME_NONNULL_END
