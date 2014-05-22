//
//  NAGUISwitch.m
//  Miner
//
//  Created by AndrewShmig on 4/3/14.
//  Copyright (c) 2014 Bleeding Games. All rights reserved.
//

#import "NAGUISwitch.h"
#import "NAGResourcePreloader.h"
#import "NAGLog.h"


@interface NAGUISwitch ()
- (void)updateActiveRegionUsingTouches:(NSSet *)touches;

- (void)playSwitchSound;
@end


@implementation NAGUISwitch
{
    SEL _action;
    __weak id _target;
}

#pragma mark - Init

- (instancetype)initWithPosition:(CGPoint)topLeftPoint
                         onImage:(UIImage *)onImage
                        offImage:(UIImage *)offImage
{
    self = [super init];

    if (self) {
        CGSize size = onImage.size;
        CGRect frame = CGRectMake(topLeftPoint.x, topLeftPoint.y, size
                .width, size.height);

        _onImage = onImage;
        _offImage = offImage;
        _activeRegion = BGUISwitchNoneRegion;
        self.selected = NO;
        self.frame = frame;
        self.adjustsImageWhenHighlighted = NO;
        self.adjustsImageWhenDisabled = NO;
        self.showsTouchWhenHighlighted = NO;

        [self setImage:onImage forState:UIControlStateSelected];
        [self setImage:offImage forState:UIControlStateNormal];
    }

    return self;
}

#pragma mark - Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
//    не надо обрабатывать это нажатие
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    BGLog();

    [self updateActiveRegionUsingTouches:touches];

    if ((self.isOn && self.activeRegion == BGUISwitchLeftRegion) ||
            (!self.isOn && self.activeRegion == BGUISwitchRightRegion)) {

        [super touchesMoved:touches withEvent:event];
        [self playSwitchSound];

        [_target performSelector:_action withObject:self];

        self.on = !self.on;
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    BGLog();

    [self updateActiveRegionUsingTouches:touches];

    if ((self.isOn && self.activeRegion == BGUISwitchLeftRegion) ||
            (!self.isOn && self.activeRegion == BGUISwitchRightRegion)) {

        [super touchesEnded:touches withEvent:event];
        [self playSwitchSound];
        [_target performSelector:_action withObject:self];

        self.on = !self.on;
    }
}

- (void)addTarget:(id)target
           action:(SEL)action
{
    _target = target;
    _action = action;
}

#pragma mark - Getters & settersw

- (void)setTopLeftPoint:(CGPoint)topLeftPoint
{
    CGRect newFrame = CGRectMake(topLeftPoint.x, topLeftPoint.y, self.bounds
            .size.width, self.bounds.size.height);
    self.bounds = newFrame;
}

- (CGPoint)topLeftPoint
{
    return CGPointMake(self.bounds.origin.x, self.bounds.origin.y);
}

- (void)setOn:(BOOL)on
{
    self.selected = on;
}

- (BOOL)isOn
{
    return self.isSelected;
}

#pragma mark - Private methods

- (void)updateActiveRegionUsingTouches:(NSSet *)touches
{
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self];
    CGRect leftRect = CGRectMake(0, 0, self.bounds.size.width / 2, self.bounds
            .size.height);
    CGRect rightRect = CGRectMake(self.bounds.size.width / 2, 0, self.bounds
            .size.width / 2, self.bounds.size.height);


    if (CGRectContainsPoint(leftRect, touchPoint)) {
        _activeRegion = BGUISwitchLeftRegion;
    } else if (CGRectContainsPoint(rightRect, touchPoint)) {
        _activeRegion = BGUISwitchRightRegion;
    } else {
        _activeRegion = BGUISwitchNoneRegion;
    }
}

- (void)playSwitchSound
{
    AVAudioPlayer *localPlayer;

//    переключатель со звуком всегда должен работать
    if (self.tag == kBGUISwitchSoundTag) {
        if (self.isOn) {
            localPlayer = [[NAGResourcePreloader shared]
                                                 playerForResource:@"switchOFF.mp3"];
        } else {
            localPlayer = [[NAGResourcePreloader shared]
                                                 playerForResource:@"switchON.mp3"];
        }

        [localPlayer play];

        return;
    }

//    отрабатывает переключатель рекламы
    if (self.isOn) {
        [[[NAGResourcePreloader shared]
                                playerFromGameConfigForResource:@"switchOFF.mp3"]
                                play];
    } else {
        [[[NAGResourcePreloader shared]
                                playerFromGameConfigForResource:@"switchON.mp3"]
                                play];
    }
}

@end
