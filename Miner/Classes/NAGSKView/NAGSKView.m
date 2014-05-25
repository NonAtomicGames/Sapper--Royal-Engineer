//
//  NAGSKView.m
//  Miner
//
//  Created by AndrewShmig on 5/24/14.
//  Copyright (c) 2014 Non Atomic Games. All rights reserved.
//

#import "NAGSKView.h"
#import "NAGGameScene.h"


@implementation NAGSKView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self) {
        NAGGameScene *gameScene = [[NAGGameScene alloc]
                                                 initWithSize:self.bounds.size];
        [self presentScene:gameScene];
    }

    return self;
}

@end
