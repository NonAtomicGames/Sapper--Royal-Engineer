//
//  BGOptionsViewController.m
//  Miner
//
//  Created by AndrewShmig on 3/15/14.
//  Copyright (c) 2014 Bleeding Games. All rights reserved.
//

#import "BGOptionsViewController.h"
#import "BGSettingsManager.h"


@interface BGOptionsViewController ()
@end


@implementation BGOptionsViewController

#pragma mark - View load process

- (void)viewDidLoad
{
//    loads settings from NSUserDefaults
    self.soundSwitch.on = [BGSettingsManager sharedManager].soundStatus == BGMinerSoundStatusOn ? YES : NO;
    self.adsSwitch.on = [BGSettingsManager sharedManager].adsStatus == BGMinerAdsStatusOn ? YES : NO;
    self.levelSegmentedControl.selectedSegmentIndex = ([BGSettingsManager sharedManager].level - 1);

    if([BGSettingsManager sharedManager].cols == 12)
        self.fieldSizeSegmentedControl.selectedSegmentIndex = 0;
    else if([BGSettingsManager sharedManager].cols == 9)
        self.fieldSizeSegmentedControl.selectedSegmentIndex = 1;
    else
        self.fieldSizeSegmentedControl.selectedSegmentIndex = 2;
}

#pragma mark - IBActions

- (IBAction)back:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)adsStatusChanged
{
    if ([BGSettingsManager sharedManager].adsStatus == BGMinerAdsStatusOn)
        [BGSettingsManager sharedManager].adsStatus = BGMinerAdsStatusOff;
    else
        [BGSettingsManager sharedManager].adsStatus = BGMinerAdsStatusOn;
}

- (IBAction)soundStatusChanged
{
    if ([BGSettingsManager sharedManager].soundStatus == BGMinerSoundStatusOn)
        [BGSettingsManager sharedManager].soundStatus = BGMinerSoundStatusOff;
    else
        [BGSettingsManager sharedManager].soundStatus = BGMinerSoundStatusOn;
}

- (IBAction)levelChanged
{
    NSInteger selectedIndex = self.levelSegmentedControl.selectedSegmentIndex;
    [BGSettingsManager sharedManager].level = (BGMinerLevel) (selectedIndex + 1);
}

- (IBAction)fieldSizeChanged
{
    NSInteger selectedIndex = self.fieldSizeSegmentedControl.selectedSegmentIndex;

    switch(selectedIndex){
        case 0:
            [BGSettingsManager sharedManager].cols = 12;
            [BGSettingsManager sharedManager].rows = 9;
            break;

        case 1:
            [BGSettingsManager sharedManager].cols = 9;
            [BGSettingsManager sharedManager].rows = 6;
            break;

        case 2:
            [BGSettingsManager sharedManager].cols = 6;
            [BGSettingsManager sharedManager].rows = 3;
            break;

        default:
            break;
    }
}

@end
