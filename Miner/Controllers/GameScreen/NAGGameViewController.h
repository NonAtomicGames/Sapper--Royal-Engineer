//
//  NAGGameViewController.h
//  Miner
//
//  Created by AndrewShmig on 3/15/14.
//  Copyright (c) 2014 Non Atomic Games. All rights reserved.
//

@import UIKit;
@import SpriteKit;


@class NAGSKView;


@interface NAGGameViewController : UIViewController

// вьюха для отображения игровой сцены
@property (nonatomic, strong) NAGSKView *skView;

@end
