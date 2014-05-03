//
//  BGAppDelegate.m
//  Miner
//
//  Created by AndrewShmig on 3/15/14.
//  Copyright (c) 2014 Bleeding Games. All rights reserved.
//

#import <GameKit/GameKit.h>
#import "BGAppDelegate.h"
#import "BGSettingsManager.h"
#import "BGResourcePreloader.h"
#import "BGSKView.h"
#import "BGGameViewController.h"
#import "BGLog.h"
#import "Flurry.h"


@implementation BGAppDelegate

- (BOOL)          application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    BGLog();

//    собираем статистику
    [Flurry setCrashReportingEnabled:YES];
    [Flurry startSession:@"QMG6WRKZD397MK5N728Q"];

//    предзагрузка звуков в фоновом режиме для избежания затормаживания
    NSArray *audioResources = @[@"switchON.mp3",
                                @"switchOFF.mp3",
                                @"flagTapOn.mp3",
                                @"grassTap.mp3",
                                @"buttonTap.mp3",
                                @"flagTapOff.mp3",
                                @"explosion.wav"];

    for (NSString *audioName in audioResources) {
        [[BGResourcePreloader shared] preloadAudioResource:audioName];
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
    BGLog();

    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    BGLog();

    [[BGSettingsManager sharedManager] save];

//    останавливаем обновление сцены в фоновом режиме
    [BGGameViewController shared].skView.scene.paused = YES;
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    BGLog();

    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    BGLog();

//    сцена должна обновляться после выхода из бэкграунда только тогда, когда
//    пользователь ушел в бэкграунд с игрового экрана, а не какого-то другого
    UIViewController *topViewController = [[BGGameViewController shared]
            .navigationController.viewControllers lastObject];

    if ([topViewController isMemberOfClass:[BGGameViewController class]]) {
        [BGGameViewController shared].skView.scene.paused = NO;
    }

    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    BGLog();

    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [[BGSettingsManager sharedManager] save];
}

@end
