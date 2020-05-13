//
//  ViewController.m
//  Metallica
//
//  Created by Liang,Zhiyuan(MTD) on 2020/4/27.
//  Copyright © 2020 Liang,Zhiyuan(MTD). All rights reserved.
//

#import "ViewController.h"
#import "MetaliicaView.h"
#import <Metal/Metal.h>
#import <GLKit/GLKit.h>

@interface ViewController ()

@property (nonatomic) MetaliicaView *mtView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _mtView = [[MetaliicaView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_mtView];
    
    CADisplayLink *dLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayUpdate)];
    
    [dLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    _mtView.frame = self.view.bounds;
//    [_mtView drawPlanes];
    
    [_mtView renderView];
}

float rotAngle = 0;

- (void)displayUpdate{
    GLKVector3 sunPosition = GLKVector3Make(0.0, 2.2, 1);
    
    float rate = M_PI/36.0;
    
    rotAngle += rate;
    
    if (rotAngle > 2.0 * M_PI) {
        rotAngle = rotAngle - 2.0 * M_PI;
    }
    
    GLKMatrix3 rotmat = GLKMatrix3MakeRotation(rotAngle, 0, 1, 0);
    
    sunPosition = GLKMatrix3MultiplyVector3(rotmat, sunPosition);
    
    [_mtView updateSunPosition:sunPosition.x y:sunPosition.y z:sunPosition.z];
    
    [_mtView renderView];
}

@end
