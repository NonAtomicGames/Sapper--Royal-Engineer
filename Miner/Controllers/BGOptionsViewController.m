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
#import "BGUISegmentedControl.h"


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
    self.backgroundImageView.image = [UIImage imageNamed:@"miner_config"];

    [self.originalContentView addSubview:self.backgroundImageView];

//    кнопка назад
    UIImage *backNormal = [UIImage imageNamed:@"back"];
    UIImage *backHighlighted = [UIImage imageNamed:@"back_down"];
    UIButton *back = [[UIButton alloc]
            initWithFrame:CGRectMake(14, 22, backNormal.size.width, backNormal.size.height)];
    [back setImage:backNormal forState:UIControlStateNormal];
    [back setImage:backHighlighted forState:UIControlStateHighlighted];
    [back addTarget:self
             action:@selector(back:)
   forControlEvents:UIControlEventTouchUpInside];

    [self.originalContentView addSubview:back];

//    создаем подпись к элементу изменения размера поля
    UIImageView *fieldSizeImageView = [[UIImageView alloc]
            initWithImage:[UIImage imageNamed:@"field_size"]];
    CGRect fieldSizeRect = fieldSizeImageView.bounds;
    fieldSizeImageView.frame = CGRectMake(88, 70, fieldSizeRect.size.width, fieldSizeRect.size.height);

    [self.originalContentView addSubview:fieldSizeImageView];

//    переключение размера поля
    UIImage *backgroundImageFieldSize = [UIImage imageNamed:@"field_deafult"];
    CGRect frameFieldSize = CGRectMake(35, 97, backgroundImageFieldSize.size.width, backgroundImageFieldSize.size.height);
    BGUISegmentedControl *fieldSizeSCView = [[BGUISegmentedControl alloc]
                                                                   initWithFrame:frameFieldSize];
    fieldSizeSCView.backgroundImage = backgroundImageFieldSize;
    [fieldSizeSCView addNewSegmentImage:[UIImage imageNamed:@"button_down_128"]];
    [fieldSizeSCView addNewSegmentImage:[UIImage imageNamed:@"button_down_1510"]];
    [fieldSizeSCView addNewSegmentImage:[UIImage imageNamed:@"button_down_2416"]];

    if ([BGSettingsManager sharedManager].cols == kSmallFieldCols)
        fieldSizeSCView.selectedSegmentIndex = 0;
    else if ([BGSettingsManager sharedManager].cols == kMediumFieldCols)
        fieldSizeSCView.selectedSegmentIndex = 1;
    else
        fieldSizeSCView.selectedSegmentIndex = 2;

    [fieldSizeSCView addTarget:self
                        action:@selector(fieldSizeChanged:)];

    [self.originalContentView addSubview:fieldSizeSCView];

//    создаем подпись к элементу изменения сложности игры
    UIImageView *difficultyImageView = [[UIImageView alloc]
            initWithImage:[UIImage imageNamed:@"difficulty"]];
    CGRect difficultyRect = difficultyImageView.bounds;
    difficultyImageView.frame = CGRectMake(102, 169, difficultyRect.size.width, difficultyRect.size.height);

    [self.originalContentView addSubview:difficultyImageView];

//    переключение сложности игры
    UIImage *backgroundImageDifficulty = [UIImage imageNamed:@"difficult_default"];
    CGRect frame = CGRectMake(35, 195, backgroundImageDifficulty.size.width, backgroundImageDifficulty.size.height);
    BGUISegmentedControl *fieldDifficultySCView = [[BGUISegmentedControl alloc]
                                                                         initWithFrame:frame];
    fieldDifficultySCView.backgroundImage = backgroundImageDifficulty;
    [fieldDifficultySCView addNewSegmentImage:[UIImage imageNamed:@"button_down_easy"]];
    [fieldDifficultySCView addNewSegmentImage:[UIImage imageNamed:@"button_down_norm"]];
    [fieldDifficultySCView addNewSegmentImage:[UIImage imageNamed:@"button_down_hard"]];

    if ([BGSettingsManager sharedManager].level == BGMinerLevelOne)
        fieldDifficultySCView.selectedSegmentIndex = 0; // easy
    else if ([BGSettingsManager sharedManager].level == BGMinerLevelTwo)
        fieldDifficultySCView.selectedSegmentIndex = 1; // norm
    else
        fieldDifficultySCView.selectedSegmentIndex = 2; // hard

    [fieldDifficultySCView addTarget:self
                              action:@selector(levelChanged:)];

    [self.originalContentView addSubview:fieldDifficultySCView];

//    создаем подпись к переключателю звука
    UIImageView *soundImageView = [[UIImageView alloc]
            initWithImage:[UIImage imageNamed:@"sounds"]];
    CGRect soundsBounds = soundImageView.bounds;
    soundImageView.frame = CGRectMake(60, 372.5, soundsBounds.size.width, soundsBounds.size.height);

    [self.originalContentView addSubview:soundImageView];

//    создаем переключатель для звука
    self.soundSwitch = [[BGUISwitch alloc]
                                    initWithPosition:CGPointMake(48, 398)
                                             onImage:[UIImage imageNamed:@"switch_1"]
                                            offImage:[UIImage imageNamed:@"switch_0"]];
    self.soundSwitch.on = ([BGSettingsManager sharedManager].soundStatus == BGMinerSoundStatusOn);
    [self.soundSwitch addTarget:self
                         action:@selector(soundButtonTapped:)];

    [self.originalContentView addSubview:self.soundSwitch];

//    создаем подпись к переключателю рекламы
    UIImageView *adsImageView = [[UIImageView alloc]
            initWithImage:[UIImage imageNamed:@"ads"]];
    CGRect adsBounds = adsImageView.bounds;
    adsImageView.frame = CGRectMake(208, 372.5, adsBounds.size.width, adsBounds.size.height);

    [self.originalContentView addSubview:adsImageView];

//    создаем переключатель для рекламы
    self.adsSwitch = [[BGUISwitch alloc] initWithPosition:CGPointMake(181, 398)
                                                  onImage:[UIImage imageNamed:@"switch_1"]
                                                 offImage:[UIImage imageNamed:@"switch_0"]];
    self.adsSwitch.on = ([BGSettingsManager sharedManager].adsStatus == BGMinerAdsStatusOn);
    [self.adsSwitch addTarget:self
                       action:@selector(adsButtonTapped:)];

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

- (void)levelChanged:(id)newlySelectedIndexNumber
{
    NSLog(@"%s", __FUNCTION__);

    NSUInteger selected = [((NSNumber *) newlySelectedIndexNumber) unsignedIntegerValue] + 1;
    BGMinerLevel newLevel = (BGMinerLevel) selected;

    [BGSettingsManager sharedManager].level = newLevel;
}

- (void)fieldSizeChanged:(id)newlySelectedIndexNumber
{
    NSLog(@"%s", __FUNCTION__);

    NSUInteger selected = [((NSNumber *) newlySelectedIndexNumber) unsignedIntegerValue];
    NSUInteger cols;
    NSUInteger rows;

    switch (selected) {
        default:

        case 0: // размер поля 12х8
            cols = kSmallFieldCols;
            rows = kSmallFieldRows;
            break;

        case 1: // размер поля 15х10
            cols = kMediumFieldCols;
            rows = kMediumFieldRows;
            break;

        case 2: // размер поля 24х16
            cols = kBigFieldCols;
            rows = kBigFieldRows;
            break;
    }

    [BGSettingsManager sharedManager].cols = cols;
    [BGSettingsManager sharedManager].rows = rows;
}

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
