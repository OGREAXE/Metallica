//
//  MCCamera.m
//  Metallica
//
//  Created by Liang,Zhiyuan(GIS)2 on 2020/4/29.
//  Copyright © 2020 Liang,Zhiyuan(MTD). All rights reserved.
//

#import "MCCamera.h"

@interface MCCamera()

@property (nonatomic) MCSceneMatrices camMatrices;

@property (nonatomic) GLKVector3 lastHorizontalVec; //in case the cross product is zero

@end

@implementation MCCamera

- (id)initWithFov:(float)fov aspect:(float)aspect near:(float)near far:(float)far{
    self = [super init];
    if (self) {
        MCSceneMatrices camMatrices;
        
        GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(fov, aspect, near, far);
        
        //to cater to metal NDC space
        GLKMatrix4 scaleMatrix = GLKMatrix4MakeScale(1, 1, 0.5);
        GLKMatrix4 translateMatrix = GLKMatrix4MakeTranslation(0, 0, 0.5);
        GLKMatrix4 transformMatrix = GLKMatrix4Multiply(translateMatrix, scaleMatrix);
      
        camMatrices.projectionMatrix = GLKMatrix4Multiply(transformMatrix, projectionMatrix);
        self.camMatrices = camMatrices;
        
        _lastHorizontalVec = GLKVector3Make(1, 0, 0);
    }
    return self;
}

+ (MCCamera *)cameraWithFov:(float)fov aspect:(float)aspect near:(float)near far:(float)far{
    MCCamera *cam = [[MCCamera alloc] initWithFov:fov aspect:aspect near:near far:far];
    return cam;
}

- (MCSceneMatrices)matrices{
    return self.camMatrices;
}

- (void)lookAt:(GLKVector3)point{
    _lookAtPoint = point;
}

- (void)updateMatrices_{
    GLKVector3 lookAtDirection = GLKVector3Subtract(_lookAtPoint, _position);
//    float cam_harizontal_vec_z =  (-1 - lookAtDirection.x)/lookAtDirection.z;
    float cam_harizontal_vec_z =  (-lookAtDirection.x)/lookAtDirection.z;
//    lookAtDirection.x * 1 + lookAtDirection.z * z = -1;
    GLKVector3 camHoriVec = {1, 0, cam_harizontal_vec_z};
    GLKVector3 fixedUp = GLKVector3CrossProduct(camHoriVec, lookAtDirection);
    GLKMatrix4 mv = GLKMatrix4MakeLookAt(_position.x, _position.y, _position.z, _lookAtPoint.x, _lookAtPoint.y, _lookAtPoint.z, fixedUp.x, fixedUp.y, fixedUp.z);
    
    MCSceneMatrices matrcies = self.camMatrices;
    matrcies.modelviewMatrix = mv;
    self.camMatrices = matrcies;
}

- (void)updateMatrices{
    GLKVector3 lookAtDirection = GLKVector3Subtract(_lookAtPoint, _position);
    GLKVector3 camHoriVec = GLKVector3CrossProduct(GLKVector3Make(0, 1, 0), lookAtDirection);
    
    if (camHoriVec.x == 0 && camHoriVec.z == 0 ) {
        //looking up or down vertically
        camHoriVec = _lastHorizontalVec;
    }
    
    _lastHorizontalVec = camHoriVec;
    
    GLKVector3 fixedUp = GLKVector3CrossProduct(lookAtDirection, camHoriVec);
    GLKMatrix4 mv = GLKMatrix4MakeLookAt(_position.x, _position.y, _position.z, _lookAtPoint.x, _lookAtPoint.y, _lookAtPoint.z, fixedUp.x, fixedUp.y, fixedUp.z);
    
    MCSceneMatrices matrcies = self.camMatrices;
    matrcies.modelviewMatrix = mv;
    self.camMatrices = matrcies;
}

@end
