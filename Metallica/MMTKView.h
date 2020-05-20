//
//  MMTKView.h
//  Metallica
//
//  Created by Liang,Zhiyuan(GIS)2 on 2020/5/20.
//  Copyright © 2020 Liang,Zhiyuan(MTD). All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MetalKit/MetalKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MMTKView : MTKView

- (void)renderView;

- (void)updateSunPosition:(CGFloat)x y:(CGFloat)y z:(CGFloat)z;

@end

NS_ASSUME_NONNULL_END
