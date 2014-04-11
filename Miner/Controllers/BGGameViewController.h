//
//  BGGameViewController.h
//  Miner
//
//  Created by AndrewShmig on 3/15/14.
//  Copyright (c) 2014 Bleeding Games. All rights reserved.
//

@import UIKit;
@import SpriteKit;


@interface BGGameViewController : UIViewController

@property (nonatomic, weak) IBOutlet SKView *skView;
@property (nonatomic, strong, readonly) NSTimer *timer;

@end
