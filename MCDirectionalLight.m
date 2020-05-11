//
//  MCDirectionalLight.m
//  Metallica
//
//  Created by Liang,Zhiyuan(GIS)2 on 2020/5/2.
//  Copyright © 2020 Liang,Zhiyuan(MTD). All rights reserved.
//

#import "MCDirectionalLight.h"
#import <Metal/Metal.h>

@interface MCDirectionalLight()

@property (nonatomic) MCSceneMatrices camMatrices;

@end

@implementation MCDirectionalLight

- (id)init{
    self = [super init];
    if (self) {
        MCSceneMatrices camMatrices;
//        camMatrices.projectionMatrix = GLKMatrix4MakeOrtho(-53, 53, 53, -53, -53, 53);
//        camMatrices.projectionMatrix = GLKMatrix4MakeOrtho(-1, 1, 1, -1, -100, 100);
        GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(-3, 3, -3, 3, -100, 100);
        
        //to cater to metal NDC space
//        GLKMatrix4 shadowScale = GLKMatrix4MakeScale(0.5f, -0.5f, 1.0);
//        GLKMatrix4 shadowTranslate = GLKMatrix4MakeTranslation(0.5, 0.5, 0);
//        GLKMatrix4 shadowTransform = GLKMatrix4Multiply(shadowTranslate, shadowScale);
        GLKMatrix4 shadowScale = GLKMatrix4MakeScale(1, 1, 0.5);
        GLKMatrix4 shadowTranslate = GLKMatrix4MakeTranslation(0, 0, 0.5);
        GLKMatrix4 shadowTransform = GLKMatrix4Multiply(shadowTranslate, shadowScale);
        
        camMatrices.projectionMatrix = GLKMatrix4Multiply(shadowTransform, projectionMatrix);
        
        self.camMatrices = camMatrices;
    }
    return self;
}

- (MCSceneMatrices)matrices{
    return self.camMatrices;
}

- (void)updateMatrices{
//    float cam_harizontal_vec_z =  (-1 - _direction.x)/_direction.z;
    float cam_harizontal_vec_z =  (-_direction.x)/_direction.z;
//    lookAtDirection.x * 1 + lookAtDirection.z * z = -1;
    GLKVector3 camHoriVec = {1, 0, cam_harizontal_vec_z};
    GLKVector3 fixedUp = GLKVector3CrossProduct(camHoriVec, _direction);
    
    GLKVector3 position = GLKVector3Negate(_direction);
    position = GLKVector3MultiplyScalar(position, 6);
    GLKMatrix4 mv = GLKMatrix4MakeLookAt(position.x, position.y, position.z, 0, 0, 0, fixedUp.x, fixedUp.y, fixedUp.z);
 
    MCSceneMatrices matrcies = self.camMatrices;
    matrcies.modelviewMatrix = mv;

    self.camMatrices = matrcies;
}

@end
