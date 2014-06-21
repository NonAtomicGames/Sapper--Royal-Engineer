//
//  NAGResourcePreloader.m
//  Miner
//
//  Created by AndrewShmig on 4/5/14.
//  Copyright (c) 2014 Bleeding Games. All rights reserved.
//

#import "NAGResourcePreloader.h"
#import "NAGSettingsManager.h"


@implementation NAGResourcePreloader
{
    NSMutableDictionary *_data;
}

#pragma mark - Class methods

static NAGResourcePreloader *shared;

+ (instancetype)shared
{
    static dispatch_once_t once;

    dispatch_once(&once, ^{
        shared = [[self alloc] init];
        shared->_data = [[NSMutableDictionary alloc] init];
    });

    return shared;
}

#pragma mark - Instance methods

- (void)preloadAudioResource:(NSString *)name
{
    __weak NAGResourcePreloader *weakSelf = self;
    NAGResourcePreloader *strongWeakSelf = weakSelf;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSString *soundPath = [[NSBundle mainBundle]
                                         pathForResource:name
                                                  ofType:nil];
        NSURL *soundURL = [NSURL fileURLWithPath:soundPath];
        AVAudioPlayer *player = [[AVAudioPlayer alloc]
                                                initWithContentsOfURL:soundURL
                                                                error:nil];
        [player prepareToPlay];

        strongWeakSelf->_data[name] = player;
    });
}

- (AVAudioPlayer *)playerFromGameConfigForResource:(NSString *)name
{
    //    звуки отключены
    if (![[NAGSettingsManager shared]
                              boolValueForSettingsPath:@"game.settings.soundsOn"])
        return nil;

    return [self BGPrivate_playerForResource:name];
}

- (AVAudioPlayer *)playerForResource:(NSString *)name
{
    return [self BGPrivate_playerForResource:name];
}

#pragma mark - AVAudioDelegate

- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)player
{
    [player stop];
    player.currentTime = 0.0;
}

#pragma mark - Private method

- (AVAudioPlayer *)BGPrivate_playerForResource:(NSString *)name
{
    return (AVAudioPlayer *) _data[name];
}

@end
