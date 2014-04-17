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

// TODO: добавить комментарии
@interface BGGameViewController : UIViewController

@property (nonatomic, strong) BGSKView *skView;

+ (instancetype)shared;

@end
