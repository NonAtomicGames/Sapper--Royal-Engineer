//
//  BGViewController.m
//  Miner
//
//  Created by AndrewShmig on 3/15/14.
//  Copyright (c) 2014 Bleeding Games. All rights reserved.
//

#import <iAd/iAd.h>
#import "BGViewController.h"
#import "BGSettingsManager.h"
#import "BGSKView.h"
#import "BGGameViewController.h"
#import "BGLog.h"
#import "BGAudioPreloader.h"


@implementation BGViewController

#pragma mark - View

- (void)viewDidAppear:(BOOL)animated
{
    BGLog();

    [super viewDidAppear:animated];

//    разрешаем на этом экране работать рекламе
    self.canDisplayBannerAds = ([BGSettingsManager sharedManager].adsStatus == BGMinerAdsStatusOn);
}

#pragma mark - Actions

- (IBAction)playButtonTapped:(id)sender
{
//    проигрываем звук нажатия
    [[[BGAudioPreloader shared] playerForResource:@"button_tap"
                                           ofType:@"mp3"] play];

    [self.navigationController pushViewController:[BGSKView shared].gameViewController
                                         animated:YES];
}

- (IBAction)configButtonTapped:(id)sender
{
    //    проигрываем звук нажатия
    [[[BGAudioPreloader shared] playerForResource:@"button_tap"
                                           ofType:@"mp3"] play];
}

@end
