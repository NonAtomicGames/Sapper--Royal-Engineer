//
//  BGOptionsViewController.m
//  Miner
//
//  Created by AndrewShmig on 3/15/14.
//  Copyright (c) 2014 Bleeding Games. All rights reserved.
//

#import "BGOptionsViewController.h"
#import "BGUISwitch.h"
#import "BGSettingsManager.h"


@interface BGOptionsViewController ()
@property (nonatomic) UIImageView *backgroundImageView;
@property (nonatomic) BGUISwitch *soundSwitch;
@property (nonatomic) BGUISwitch *adsSwitch;
@end


@implementation BGOptionsViewController

#pragma mark - View

- (void)viewDidLoad
{
//    создаем фоновую вьюху и устанавливаем фоновое изображение для экрана
    self.backgroundImageView = [[UIImageView alloc]
                                             initWithFrame:[UIScreen mainScreen].bounds];
    self.backgroundImageView.image = [UIImage imageNamed:@"miner_config.jpg"];

    [self.view addSubview:self.backgroundImageView];

//    создаем переключатель для звука
    self.soundSwitch = [[BGUISwitch alloc]
                                    initWithPosition:CGPointMake(10, 10)
                                             onImage:[UIImage imageNamed:@"switch_1.png"]
                                            offImage:[UIImage imageNamed:@"switch_0.png"]];
    self.soundSwitch.on = ([BGSettingsManager sharedManager].soundStatus == BGMinerSoundStatusOn);
    [self.soundSwitch addTarget:self
                         action:@selector(soundButtonTapped:)
               forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:self.soundSwitch];

//    создаем переключатель для рекламы
    self.adsSwitch = [[BGUISwitch alloc] initWithPosition:CGPointMake(200, 200)
                                                  onImage:[UIImage imageNamed:@"switch_1.png"]
                                                 offImage:[UIImage imageNamed:@"switch_0.png"]];
    self.adsSwitch.on = ([BGSettingsManager sharedManager].adsStatus == BGMinerAdsStatusOn);
    [self.adsSwitch addTarget:self
                       action:@selector(adsButtonTapped:)
             forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:self.adsSwitch];
}

#pragma mark - Target actions

- (void)soundButtonTapped:(id)sender
{
    NSLog(@"%s", __FUNCTION__);

//    при переключении тумблера звука меняем настройки
    BGMinerSoundStatus soundStatus = [BGSettingsManager sharedManager].soundStatus;

    if (soundStatus == BGMinerSoundStatusOn)
        [BGSettingsManager sharedManager].soundStatus = BGMinerSoundStatusOff;
    else
        [BGSettingsManager sharedManager].soundStatus = BGMinerSoundStatusOn;
}

- (void)adsButtonTapped:(id)sender
{
    NSLog(@"%s", __FUNCTION__);

//    при переключении тумблера показа рекламы сохраним настройки
    BGMinerAdsStatus adsStatus = [BGSettingsManager sharedManager].adsStatus;

    if (adsStatus == BGMinerAdsStatusOn)
        [BGSettingsManager sharedManager].adsStatus = BGMinerAdsStatusOff;
    else
        [BGSettingsManager sharedManager].adsStatus = BGMinerAdsStatusOn;
}

@end
