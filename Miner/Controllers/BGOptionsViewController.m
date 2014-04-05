//
//  BGOptionsViewController.m
//  Miner
//
//  Created by AndrewShmig on 3/15/14.
//  Copyright (c) 2014 Bleeding Games. All rights reserved.
//

#import <iAd/iAd.h>
#import "BGOptionsViewController.h"
#import "BGUISwitch.h"
#import "BGSettingsManager.h"
#import "BGAudioPreloader.h"


@interface BGOptionsViewController ()
@property (nonatomic) UIImageView *backgroundImageView;
@property (nonatomic) BGUISwitch *soundSwitch;
@property (nonatomic) BGUISwitch *adsSwitch;
@end


@implementation BGOptionsViewController

#pragma mark - View

- (void)viewDidLoad
{
    [super viewDidLoad];

//    создаем фоновую вьюху и устанавливаем фоновое изображение для экрана
    self.backgroundImageView = [[UIImageView alloc]
                                             initWithFrame:[UIScreen mainScreen].bounds];
    self.backgroundImageView.image = [UIImage imageNamed:@"miner_config.jpg"];

    [self.originalContentView addSubview:self.backgroundImageView];

    //    кнопка назад
    UIButton *back = [[UIButton alloc]
                                initWithFrame:CGRectMake(0, 0, 100, 100)];
    back.titleLabel.text = @"Back";
    back.backgroundColor = [UIColor blueColor];
    [back addTarget:self
             action:@selector(back:)
   forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:back];

//    создаем переключатель для звука
    self.soundSwitch = [[BGUISwitch alloc]
                                    initWithPosition:CGPointMake(40, 415)
                                             onImage:[UIImage imageNamed:@"switch_1.png"]
                                            offImage:[UIImage imageNamed:@"switch_0.png"]];
    self.soundSwitch.on = ([BGSettingsManager sharedManager].soundStatus == BGMinerSoundStatusOn);
    [self.soundSwitch addTarget:self
                         action:@selector(soundButtonTapped:)
               forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:self.soundSwitch];

//    создаем переключатель для рекламы
    self.adsSwitch = [[BGUISwitch alloc] initWithPosition:CGPointMake(200, 415)
                                                  onImage:[UIImage imageNamed:@"switch_1.png"]
                                                 offImage:[UIImage imageNamed:@"switch_0.png"]];
    self.adsSwitch.on = ([BGSettingsManager sharedManager].adsStatus == BGMinerAdsStatusOn);
    [self.adsSwitch addTarget:self
                       action:@selector(adsButtonTapped:)
             forControlEvents:UIControlEventTouchUpInside];

    [self.originalContentView addSubview:self.adsSwitch];

//    звуки переключателей
    AVAudioPlayer *onSound = [[BGAudioPreloader shared]
                                                playerForResource:@"switchON"
                                                           ofType:@"mp3"];
    AVAudioPlayer *offSound = [[BGAudioPreloader shared]
                                                 playerForResource:@"switchOFF"
                                                            ofType:@"mp3"];

    self.soundSwitch.onSound = onSound;
    self.adsSwitch.onSound = onSound;
    self.soundSwitch.offSound = offSound;
    self.adsSwitch.offSound = offSound;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    //    данный контроллер может работать с рекламой
    self.canDisplayBannerAds = ([BGSettingsManager sharedManager].adsStatus == BGMinerAdsStatusOn);
}

#pragma mark - Target actions

- (void)soundButtonTapped:(id)sender
{
    NSLog(@"%s", __FUNCTION__);

//    при переключении тумблера звука меняем настройки
    BGMinerSoundStatus soundStatus = [BGSettingsManager sharedManager].soundStatus;

    if (soundStatus == BGMinerSoundStatusOn && self.soundSwitch.activeRegion == BGUISwitchLeftRegion) {
        [BGSettingsManager sharedManager].soundStatus = BGMinerSoundStatusOff;
    } else if (soundStatus == BGMinerSoundStatusOff && self.soundSwitch.activeRegion == BGUISwitchRightRegion) {
        [BGSettingsManager sharedManager].soundStatus = BGMinerSoundStatusOn;
    }
}

- (void)adsButtonTapped:(id)sender
{
    NSLog(@"%s", __FUNCTION__);

//    при переключении тумблера показа рекламы сохраним настройки
    BGMinerAdsStatus adsStatus = [BGSettingsManager sharedManager].adsStatus;

    if (adsStatus == BGMinerAdsStatusOn) {
        [BGSettingsManager sharedManager].adsStatus = BGMinerAdsStatusOff;
        self.canDisplayBannerAds = NO;
    } else {
        [BGSettingsManager sharedManager].adsStatus = BGMinerAdsStatusOn;
        self.canDisplayBannerAds = YES;
    }
}

- (void)back:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
