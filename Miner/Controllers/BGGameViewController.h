//
//  BGGameViewController.h
//  Miner
//
//  Created by AndrewShmig on 3/15/14.
//  Copyright (c) 2014 Bleeding Games. All rights reserved.
//

@import UIKit;
@import SpriteKit;


@class BGSKView;


@interface BGGameViewController : UIViewController

// вьюха для отображения игровой сцены
@property (nonatomic, strong) BGSKView *skView;

// уникальный объект игрового экрана
// используется для того, чтобы ускорить загрузку и отображение содержимого сцены
+ (instancetype)shared;

@end
