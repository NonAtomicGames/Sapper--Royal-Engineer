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
#import "BGGameViewController.h"
#import "Flurry.h"


@implementation BGViewController

#pragma mark - View

- (void)viewDidLoad
{
    BGLog();

    [super viewDidLoad];

    self.gameViewController = [BGGameViewController shared];
}

- (void)viewDidAppear:(BOOL)animated
{
    BGLog();

    [super viewDidAppear:animated];

//    проверяем авторизацию текущего пользователя GameCenter
    [self authorizeLocalGameCenterPlayer];

    //    разрешаем на этом экране работать рекламе
    self.canDisplayBannerAds = ([BGSettingsManager sharedManager]
            .adsStatus == BGMinerAdsStatusOn);
}

#pragma mark - Actions

- (IBAction)playButtonTapped:(id)sender
{
    //    проигрываем звук нажатия
    [[[BGResourcePreloader shared]
                           playerFromGameConfigForResource:@"buttonTap.mp3"]
                           play];

    [self.navigationController pushViewController:self.gameViewController
                                         animated:YES];
}

- (IBAction)configButtonTapped:(id)sender
{
    //    проигрываем звук нажатия
    [[[BGResourcePreloader shared]
                           playerFromGameConfigForResource:@"buttonTap.mp3"]
                           play];
}

#pragma mark - Private

- (void)authorizeLocalGameCenterPlayer
{
//        проверим, авторизован ли пользователь в Game Center и, если да, то
//        опубликуем его счет. Просить авторизоваться не будем.
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    __weak GKLocalPlayer *weakLocalPlayer = localPlayer;

    localPlayer.authenticateHandler = ^(UIViewController *view, NSError *error)
    {
        if (weakLocalPlayer.isAuthenticated) {
//            пользователь авторизован, всё хорошо
        }
    };
}

@end
