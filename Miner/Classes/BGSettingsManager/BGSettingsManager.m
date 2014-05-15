//
//  BGSettingsManager.m
//  Miner
//
//  Created by AndrewShmig on 3/15/14.
//  Copyright (c) 2014 Bleeding Games. All rights reserved.
//

#import "BGSettingsManager.h"


// размеры минимального поля
static const NSUInteger LEVEL_1_COLS = 12;
static const NSUInteger LEVEL_1_ROWS = 8;

// наименование ключа в юзер дефолтах
static NSString *const kNSUserDefaultSettingsKey = @"BGSettingsManager";


// приватные методы
@interface BGSettingsManager (Private)
- (NSUInteger)randomNumberOfBombsForRows:(NSUInteger)rows
                                    cols:(NSUInteger)cols
                                   level:(BGMinerLevel)level;
@end


// основная реализация
@implementation BGSettingsManager
{
    NSMutableDictionary *_settings;
}

#pragma mark - Class methods

+ (instancetype)sharedManager
{
    static dispatch_once_t once;
    static BGSettingsManager *_sharedManager;

    dispatch_once(&once, ^
    {
        _sharedManager = [[self alloc] init];
    });

    return _sharedManager;
}


#pragma mark - Instance methods

- (instancetype)init
{
    self = [super init];

    if (self) {
        //        загружаем настройки, если они есть.
        _settings = [[NSUserDefaults standardUserDefaults]
                                     valueForKey:kNSUserDefaultSettingsKey];

        if (_settings == nil) {
            _settings = [NSMutableDictionary dictionaryWithDictionary:@{
                    @"rows"        : @(LEVEL_1_ROWS),
                    @"cols"        : @(LEVEL_1_COLS),
                    @"level"       : @(BGMinerLevelOne),
                    @"soundStatus" : @YES,
                    @"gameCenterStatus"   : @YES
            }];
        }
    }

    return self;
}

- (void)save
{
    //    save settings to nsuserdefaults
    [[NSUserDefaults standardUserDefaults]
                     setValue:_settings forKey:kNSUserDefaultSettingsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Getters & Setters

- (NSUInteger)rows
{
    return [_settings[@"rows"] unsignedIntegerValue];
}

- (void)setRows:(NSUInteger)rows
{
    _settings[@"rows"] = @(rows);
}

- (NSUInteger)cols
{
    return [_settings[@"cols"] unsignedIntegerValue];
}

- (void)setCols:(NSUInteger)cols
{
    _settings[@"cols"] = @(cols);
}

- (NSUInteger)bombs
{
    return [self randomNumberOfBombsForRows:self.rows
                                       cols:self.cols
                                      level:self.level];
}

- (BGMinerLevel)level
{
    return (BGMinerLevel) [_settings[@"level"] unsignedIntegerValue];
}

- (void)setLevel:(BGMinerLevel)level
{
    _settings[@"level"] = @(level);
}

- (BGMinerSoundStatus)soundStatus
{
    BOOL soundOn = [_settings[@"soundStatus"] boolValue];
    return (soundOn ? BGMinerSoundStatusOn : BGMinerSoundStatusOff);
}

- (void)setSoundStatus:(BGMinerSoundStatus)soundStatus
{
    _settings[@"soundStatus"] = (soundStatus == BGMinerSoundStatusOn ? @YES : @NO);
}

- (BGMinerGameCenterStatus)gameCenterStatus
{
    BOOL showGameCenter = [_settings[@"gameCenterStatus"] boolValue];
    return (showGameCenter ? BGMinerGameCenterStatusOn : BGMinerGameCenterStatusOff);
}

- (void)setGameCenterStatus:(BGMinerGameCenterStatus)gameCenterStatus
{
    _settings[@"gameCenterStatus"] = (gameCenterStatus == BGMinerGameCenterStatusOn ? @YES : @NO);
}

#pragma mark - Private methods

- (NSUInteger)randomNumberOfBombsForRows:(NSUInteger)rows
                                    cols:(NSUInteger)cols
                                   level:(BGMinerLevel)level
{
    sranddev();

    NSUInteger minBombs = (rows < cols) ? rows : cols;
    NSUInteger maxBombs = 2 * minBombs;
    NSUInteger bombs = arc4random() % (maxBombs - minBombs + 1) + level * minBombs;

    return bombs;
}

@end
