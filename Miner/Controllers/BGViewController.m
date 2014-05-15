//
//  BGViewController.m
//  Miner
//
//  Created by AndrewShmig on 3/15/14.
//  Copyright (c) 2014 Bleeding Games. All rights reserved.
//

#import <iAd/iAd.h>
#import <GameKit/GameKit.h>
#import "BGViewController.h"
#import "BGSettingsManager.h"
#import "BGLog.h"
#import "BGResourcePreloader.h"
#import "BGAppDelegate.h"
#import "BGGameViewController.h"


@implementation BGViewController

#pragma mark - View

- (void)viewDidLoad
{
    BGLog();
    
    [super viewDidLoad];
    
    self.gameViewController = [BGGameViewController shared];
}

- (void)viewWillAppear:(BOOL)animated
{
    BGLog();
    
    [super viewWillAppear:animated];
    
    //    проверяем авторизацию текущего пользователя GameCenter и авторизуем, если надо
    if ([BGSettingsManager sharedManager].gameCenterStatus == BGMinerGameCenterStatusOn) {
        BGAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
        [appDelegate authorizeLocalGameCenterPlayer];
    }

    //    разрешаем на этом экране работать рекламе
    self.canDisplayBannerAds = YES;
}

#pragma mark - Actions

- (IBAction)playButtonTapped:(id)sender
{
    //    проигрываем звук нажатия
    [[[BGResourcePreloader shared]
      playerFromGameConfigForResource:@"buttonTap.mp3"] play];
    
    [self.navigationController pushViewController:self.gameViewController
                                         animated:YES];
}

- (IBAction)configButtonTapped:(id)sender
{
    //    проигрываем звук нажатия
    [[[BGResourcePreloader shared]
      playerFromGameConfigForResource:@"buttonTap.mp3"] play];
}

@end
