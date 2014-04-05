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

@implementation BGViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    //    разрешаем на этом экране отображаться рекламе
    self.canDisplayBannerAds = ([BGSettingsManager sharedManager].adsStatus == BGMinerAdsStatusOn);
}

@end
