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


static AVAudioPlayer *onSwitchPlayer;
static AVAudioPlayer *offSwitchPlayer;


@interface BGOptionsViewController ()
@property (nonatomic) UIImageView *backgroundImageView;
@property (nonatomic) BGUISwitch *soundSwitch;
@property (nonatomic) BGUISwitch *adsSwitch;
@end


@implementation BGOptionsViewController

+ (void)initialize
{
    //  подгрузка аудио файлов
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^
    {
        //    настраиваем звуки
        //    аудио файлы
        NSString *onSound = [[NSBundle mainBundle]
                                       pathForResource:@"switchON"
                                                ofType:@"mp3"];
        NSString *offSound = [[NSBundle mainBundle]
                                        pathForResource:@"switchOFF"
                                                 ofType:@"mp3"];

        onSwitchPlayer = [[AVAudioPlayer alloc]
                                         initWithData:[NSData dataWithContentsOfFile:onSound]
                                                error:nil];
        offSwitchPlayer = [[AVAudioPlayer alloc]
                                          initWithData:[NSData dataWithContentsOfFile:offSound]
                                                 error:nil];

        [onSwitchPlayer prepareToPlay];
        [offSwitchPlayer prepareToPlay];
    });
}

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

    if (soundStatus == BGMinerSoundStatusOn && self.soundSwitch.activeRegion == BGUISwitchLeftRegion) {
        [BGSettingsManager sharedManager].soundStatus = BGMinerSoundStatusOff;
        [offSwitchPlayer play];
    } else if (soundStatus == BGMinerSoundStatusOff && self.soundSwitch.activeRegion == BGUISwitchRightRegion) {
        [BGSettingsManager sharedManager].soundStatus = BGMinerSoundStatusOn;
        [onSwitchPlayer play];
    }
}

- (void)adsButtonTapped:(id)sender
{
    NSLog(@"%s", __FUNCTION__);

//    при переключении тумблера показа рекламы сохраним настройки
    BGMinerAdsStatus adsStatus = [BGSettingsManager sharedManager].adsStatus;

    if (adsStatus == BGMinerAdsStatusOn) {
        [BGSettingsManager sharedManager].adsStatus = BGMinerAdsStatusOff;
        [offSwitchPlayer play];
    } else {
        [BGSettingsManager sharedManager].adsStatus = BGMinerAdsStatusOn;
        [onSwitchPlayer play];
    }
}

@end
