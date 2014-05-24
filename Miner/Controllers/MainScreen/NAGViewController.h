//
//  NAGViewController.h
//  Miner
//
//  Created by AndrewShmig on 3/15/14.
//  Copyright (c) 2014 Bleeding Games. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SpriteKit/SpriteKit.h>


@class NAGGameViewController;


@interface NAGViewController : UIViewController

@property (nonatomic, strong) NAGGameViewController *gameViewController;

- (IBAction)playButtonTapped:(id)sender;

- (IBAction)configButtonTapped:(id)sender;

@end
