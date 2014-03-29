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


// -----------------------------------------------------------------------------
// --------- BGGameScene ---------
// -----------------------------------------------------------------------------

// дочерний класс для обработки цикла обновления игрового поля
@interface BGGameScene : SKScene
@end

@implementation BGGameScene

- (void)update:(NSTimeInterval)currentTime
{
//    NSLog(@"%s", __FUNCTION__);
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"%s", __FUNCTION__);
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"%s", __FUNCTION__);
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"%s", __FUNCTION__);
}

@end


// -----------------------------------------------------------------------------
// --------- BGGameViewController ---------
// -----------------------------------------------------------------------------

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

//    добавляем сцену на SKView
    BGGameScene *scene = [[BGGameScene alloc]
                                       initWithSize:self.skView.bounds.size];
    [self.skView presentScene:scene];

    self.skView.showsDrawCount = YES;
    self.skView.showsFPS = YES;
    self.skView.showsNodeCount = YES;
    self.skView.showsPhysics = YES;

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
