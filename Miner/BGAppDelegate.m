//
//  BGAppDelegate.m
//  Miner
//
//  Created by AndrewShmig on 3/15/14.
//  Copyright (c) 2014 Bleeding Games. All rights reserved.
//

#import "BGAppDelegate.h"
#import "BGSettingsManager.h"
#import "BGAudioPreloader.h"
#import "BGSKView.h"
#import "BGGameViewController.h"
#import "BGLog.h"


@implementation BGAppDelegate

- (BOOL)          application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
//    предзагрузка звуков в фоновом режиме для избежания затормаживания
    NSArray *audioResources = @[@"switchON.mp3",
                                @"switchOFF.mp3",
                                @"flagTapOn.mp3",
                                @"grassTap.mp3",
                                @"buttonTap.mp3",
                                @"flagTapOff.mp3"];

    for (NSString *audioName in audioResources) {
        NSArray *parts = [audioName componentsSeparatedByString:@"."];
        NSString *name = parts[0];
        NSString *type = parts[1];

        [[BGAudioPreloader shared] preloadResource:name
                                            ofType:type];
    }

//    предсоздание игрового экрана
    [BGGameViewController shared];

//    предзагрузка дефолтов
    [BGSettingsManager sharedManager];

    // Override point for customization after application launch.
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [[BGSettingsManager sharedManager] save];

//    останавливаем обновление сцены в фоновом режиме
    [BGGameViewController shared].skView.scene.paused = YES;
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [[BGSettingsManager sharedManager] save];
}

@end
