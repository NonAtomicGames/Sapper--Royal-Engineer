//
//  BGSettingsManager.h
//  Miner
//
//  Created by AndrewShmig on 3/15/14.
//  Copyright (c) 2014 Bleeding Games. All rights reserved.
//


// размеры полей
static const NSUInteger kSmallFieldCols = 12;
static const NSUInteger kSmallFieldRows = 8;

static const NSUInteger kMediumFieldCols = 15;
static const NSUInteger kMediumFieldRows = 10;

static const NSUInteger kBigFieldCols = 24;
static const NSUInteger kBigFieldRows = 16;


// уровни, статус звука и рекламы
typedef NS_ENUM(NSUInteger, BGMinerLevel) {
    BGMinerLevelOne = 1,
    BGMinerLevelTwo,
    BGMinerLevelThree
};

typedef NS_ENUM(NSUInteger, BGMinerSoundStatus) {
    BGMinerSoundStatusOn,
    BGMinerSoundStatusOff
};

typedef NS_ENUM(NSUInteger, BGMinerAdsStatus) {
    BGMinerAdsStatusOn,
    BGMinerAdsStatusOff
};


@interface BGSettingsManager : NSObject

@property (nonatomic, readwrite) NSUInteger rows;
@property (nonatomic, readwrite) NSUInteger cols;
@property (nonatomic, readwrite) NSUInteger bombs;
@property (nonatomic, readwrite) BGMinerLevel level;
@property (nonatomic, readwrite) BGMinerSoundStatus soundStatus;
@property (nonatomic, readwrite) BGMinerAdsStatus adsStatus;

+ (instancetype)sharedManager;

- (void)save;

@end
