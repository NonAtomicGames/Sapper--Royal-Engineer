//
//  NAGUISwitch.h
//  Miner
//
//  Created by AndrewShmig on 4/3/14.
//  Copyright (c) 2014 Bleeding Games. All rights reserved.
//

@import AVFoundation;


// полезные теги для вьюх NAGUISwitch
static const NSInteger kBGUISwitchSoundTag = 1;
static const NSInteger kBGUISwitchGameCenterTag = 2;


typedef NS_ENUM(NSUInteger, BGUISwitchActiveRegion)
{
    BGUISwitchNoneRegion,
    BGUISwitchLeftRegion,
    BGUISwitchRightRegion
};


@interface NAGUISwitch : UIButton <AVAudioPlayerDelegate>

// верхняя левая координата элемента
@property (nonatomic, assign, readwrite) CGPoint topLeftPoint;
// состояние переключателя
@property (nonatomic, assign, readwrite, getter=isOn) BOOL on;
// изображение для включенного состояния
@property (nonatomic, strong, readwrite) UIImage *onImage;
// изображение для выключенного состояния
@property (nonatomic, strong, readwrite) UIImage *offImage;
// часть элемента, которая была нажата - левая или правая
@property (nonatomic, readonly) BGUISwitchActiveRegion activeRegion;


// метод инициализации: верхняя левая точка положения элемента
// и два изображения для двух состояний переключателя. Размер переключателя
// равен размеру изображений (они должны быть одинакового размера)
- (instancetype)initWithPosition:(CGPoint)topLeftPoint
                         onImage:(UIImage *)onImage
                        offImage:(UIImage *)offImage;

// метод будет вызываться каждый раз, когда изменится состояние переключателя
- (void)addTarget:(id)target
           action:(SEL)action;

@end
