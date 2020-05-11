//
//  MCDirectionalLight.h
//  Metallica
//
//  Created by Liang,Zhiyuan(GIS)2 on 2020/5/2.
//  Copyright © 2020 Liang,Zhiyuan(MTD). All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import <Metal/Metal.h>
#import "MCCamera.h"

NS_ASSUME_NONNULL_BEGIN

@interface MCDirectionalLight : NSObject

@property (nonatomic) GLKVector3 direction;

@property (nonatomic) UIColor *color;

@property (nonatomic) id<MTLTexture> shadowMap;

@property (nonatomic) MCSceneMatrices matrices;

- (void)updateMatrices;

@end

NS_ASSUME_NONNULL_END
