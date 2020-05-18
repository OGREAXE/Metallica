//
//  MetaliicaView.h
//  Metallica
//
//  Created by Liang,Zhiyuan(MTD) on 2020/4/27.
//  Copyright © 2020 Liang,Zhiyuan(MTD). All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MetaliicaView : UIView

- (void)renderView;

- (void)updateSunPosition:(CGFloat)x y:(CGFloat)y z:(CGFloat)z;

@end

NS_ASSUME_NONNULL_END
