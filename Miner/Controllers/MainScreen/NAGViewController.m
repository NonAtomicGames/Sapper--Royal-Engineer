//
//  NAGViewController.m
//  Miner
//
//  Created by AndrewShmig on 3/15/14.
//  Copyright (c) 2014 Non Atomic Games. All rights reserved.
//

#import "NAGViewController.h"
#import "NAGLog.h"
#import "NAGResourcePreloader.h"
#import "NAGGameViewController.h"
#import "FlurryAds.h"
#import "NAGOptionsViewController.h"


@implementation NAGViewController

#pragma mark - View

- (void)viewWillAppear:(BOOL)animated
{
    BGLog();

    [super viewWillAppear:animated];

    [FlurryAds fetchAndDisplayAdForSpace:@"BANNER_MAIN_VIEW"
                                    view:self.view
                                    size:BANNER_BOTTOM];
}

- (void)viewDidAppear:(BOOL)animated
{
    BGLog();

    [super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    BGLog();

    [super viewDidDisappear:animated];

    [FlurryAds removeAdFromSpace:@"BANNER_MAIN_VIEW"];
}

#pragma mark - Actions

- (IBAction)playButtonTapped:(id)sender
{
    //    проигрываем звук нажатия
    [[[NAGResourcePreloader shared]
                            playerFromGameConfigForResource:@"buttonTap.mp3"]
                            play];

    [self.navigationController pushViewController:[NAGGameViewController new]
                                         animated:YES];
}

- (IBAction)configButtonTapped:(id)sender
{
    //    проигрываем звук нажатия
    [[[NAGResourcePreloader shared]
                            playerFromGameConfigForResource:@"buttonTap.mp3"]
                            play];
}

@end
