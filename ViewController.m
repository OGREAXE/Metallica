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

@interface ViewController ()

@property (nonatomic) MetaliicaView *mtView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _mtView = [[MetaliicaView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_mtView];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    _mtView.frame = self.view.bounds;
//    [_mtView drawPlanes];
    
    [_mtView renderView];
}


@end
