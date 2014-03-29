//
//  BGGameViewController.m
//  Miner
//
//  Created by AndrewShmig on 3/15/14.
//  Copyright (c) 2014 Bleeding Games. All rights reserved.
//

#import "BGGameViewController.h"
#import "BGMinerField.h"
#import "BGSettingsManager.h"


// приватные методы
@interface BGGameViewController (Private)

- (void)fillGameSceneField;
- (void)coverGameSceneField;
- (void)startGameTimer;

@end


// основная реализация
@implementation BGGameViewController
{
    BGMinerField *_field;
}

#pragma mark - Views delegate methods

- (void)viewDidLoad
{
    NSLog(@"%s", __FUNCTION__);

    NSUInteger rows = [BGSettingsManager sharedManager].rows;
    NSUInteger cols = [BGSettingsManager sharedManager].cols;
    NSUInteger bombs = [BGSettingsManager sharedManager].bombs;

    _field = [[BGMinerField alloc] initWithRows:rows
                                           cols:cols
                                          bombs:bombs];

//    заполняем SKView спрайтами с бомбами, цифрами и пустые
    [self fillGameSceneField];

//    накрываем поле спрайтами "заглушками"
    [self coverGameSceneField];
}

- (void)viewDidAppear:(BOOL)animated
{
    NSLog(@"%s", __FUNCTION__);

//    запускаем таймер игры
    [self startGameTimer];
}

#pragma mark - IBActions

- (IBAction)finishGame:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)startNewGame:(id)sender
{
//    TODO
}

#pragma mark - Private methods

- (void)fillGameSceneField
{
//    TODO
}

- (void)coverGameSceneField
{
//    TODO
}

- (void)startGameTimer
{
//    TODO
}

@end
