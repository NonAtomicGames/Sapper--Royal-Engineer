//
//  BGAppDelegate.h
//  Miner
//
//  Created by AndrewShmig on 3/15/14.
//  Copyright (c) 2014 Bleeding Games. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BGAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

- (void)authorizeLocalGameCenterPlayer;

@end
