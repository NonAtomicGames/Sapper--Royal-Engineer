//
//  BGGameViewController.m
//  Miner
//
//  Created by AndrewShmig on 3/15/14.
//  Copyright (c) 2014 Bleeding Games. All rights reserved.
//

#import "BGGameViewController.h"
#import "BGMinerField.h"
#import "BGLog.h"
#import "BGSKView.h"
#import "BGAudioPreloader.h"


// полезные константы тегов для вьюх
static const NSInteger kBGTimerViewTag = 1;
static const NSInteger kBGMinesCountViewTag = 2;
static const NSInteger kBGStatusImageDefaultViewTag = 3;
static const NSInteger kBGStatusImageFailedViewTag = 4;
static const NSInteger kBGStatusImageWonViewTag = 5;


#pragma mark - BGGameViewController

// основная реализация
@implementation BGGameViewController

#pragma mark - Init

- (id)init
{
    self = [super init];

    if (self) {
        //    добавляем на экран SKView
        self.skView = [BGSKView shared];
        [self.view addSubview:self.skView];

        //    добавляем изображение верхней панели
        UIImage *topPanelImage = [UIImage imageNamed:@"top_game"];
        UIImageView *topPanelImageView = [[UIImageView alloc]
                                                       initWithImage:topPanelImage];
        topPanelImageView.frame = CGRectMake(0, 0, topPanelImage.size.width, topPanelImage.size.height);

        [self.view addSubview:topPanelImageView];

        //    на панель изображения накладываем надпись с кол-вом прошедшего времени
        UILabel *gameTimerLabel = [[UILabel alloc] init];
        gameTimerLabel.font = [UIFont fontWithName:@"Digital-7 Mono"
                                              size:27];
        gameTimerLabel.textColor = [UIColor colorWithRed:255
                                                   green:198
                                                    blue:0
                                                   alpha:1];
        gameTimerLabel.text = [NSString stringWithFormat:@"%04d", 0];
        gameTimerLabel.frame = CGRectMake(238, 6, 100, 50);
        gameTimerLabel.tag = kBGTimerViewTag;

        [self.view addSubview:gameTimerLabel];

        //    на панель изображения накладываем надпись с кол-вом мин
        UILabel *minesCountLabel = [[UILabel alloc] init];
        minesCountLabel.font = [UIFont fontWithName:@"Digital-7 Mono"
                                               size:27];
        minesCountLabel.textColor = [UIColor colorWithRed:255
                                                    green:198
                                                     blue:0
                                                    alpha:1];
        minesCountLabel.text = [NSString stringWithFormat:@"%04d", 0];
        minesCountLabel.frame = CGRectMake(237, 36, 100, 50);
        minesCountLabel.tag = kBGMinesCountViewTag;

        [self.view addSubview:minesCountLabel];

        //  вьюха статуса игры
        //  для отслеживания нажатия, проще без кнопки обойтись
        UIImage *defaultImage = [UIImage imageNamed:@"game_button_default"];

        UIImageView *statusImageView = [[UIImageView alloc]
                                                     initWithImage:defaultImage];
        statusImageView.frame = CGRectMake(137, 22, defaultImage.size.width, defaultImage.size.height);
        statusImageView.userInteractionEnabled = YES;
        statusImageView.tag = kBGStatusImageDefaultViewTag;

        UITapGestureRecognizer *statusImageViewGestureRecognizer = [[UITapGestureRecognizer alloc]
                                                                                            initWithTarget:self
                                                                                                    action:@selector(statusImageViewTap:)];
        statusImageViewGestureRecognizer.numberOfTouchesRequired = 1;
        statusImageViewGestureRecognizer.numberOfTapsRequired = 1;
        [statusImageView addGestureRecognizer:statusImageViewGestureRecognizer];

        [self.view addSubview:statusImageView];

        //    добавляем кнопку "Назад"
        UIImage *backNormal = [UIImage imageNamed:@"back"];
        UIImage *backHighlighted = [UIImage imageNamed:@"back_down"];
        UIButton *back = [[UIButton alloc]
                                    initWithFrame:CGRectMake(14, 22, backNormal.size.width, backNormal.size.height)];
        [back setImage:backNormal forState:UIControlStateNormal];
        [back setImage:backHighlighted forState:UIControlStateHighlighted];
        [back addTarget:self
                 action:@selector(back:)
       forControlEvents:UIControlEventTouchUpInside];

        [self.view addSubview:back];

        //    добавляем определитель жестов - нажатие
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc]
                                                                                initWithTarget:self
                                                                                        action:@selector(tap:)];
        tapGestureRecognizer.numberOfTapsRequired = 1;
        tapGestureRecognizer.numberOfTouchesRequired = 1;

        [self.skView addGestureRecognizer:tapGestureRecognizer];

        //    добавляем определитель жестов - удержание (для установление флажка)
        UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc]
                                                                                                  initWithTarget:self
                                                                                                          action:@selector(longPress:)];
        longPressGestureRecognizer.numberOfTouchesRequired = 1;

        [self.skView addGestureRecognizer:longPressGestureRecognizer];

#ifdef DEBUG
        self.skView.showsDrawCount = YES;
        self.skView.showsFPS = YES;
        self.skView.showsNodeCount = YES;
        self.skView.showsPhysics = YES;
#endif
    }

    return self;
}

#pragma mark - View

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

//    обновляем надпись с кол-вом мин
    [self updateMinesCountLabel];

//    запускаем обновление сцены
    [BGSKView shared].paused = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    BGLog();

//    обновляем кнопку со статусом
    [self updateStatusImageViewWithStatus:kBGStatusImageDefaultViewTag];

//    запускаем игровой таймер
    [self startGameTimer];
}

- (void)viewDidDisappear:(BOOL)animated
{
    BGLog();

    //    обновляем кнопку со статусом
    [self updateStatusImageViewWithStatus:kBGStatusImageDefaultViewTag];

//    обновляем поле
//  сбрасываем старые значения
    [self destroyGameTimer];
    [self resetTimerLabel];
    [self resetMinesCountLabel];

//    обновляем поле на новое
    [BGSKView shared].paused = NO;
    [[BGSKView shared] startNewGame];
    [self updateMinesCountLabel];
}

#pragma mark - Game & Private

- (void)startGameTimer
{
    BGLog();

    //    запускаем таймер игры
    if (self.timer == nil) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                  target:self
                                                selector:@selector(updateTimerLabel:)
                                                userInfo:nil
                                                 repeats:YES];
    }
}

- (void)destroyGameTimer
{
    //    убираем таймер
    [_timer invalidate];
    _timer = nil;
}

- (void)stopGameTimer
{
    [_timer invalidate];
}

#pragma mark - Actions

- (void)statusImageViewTap:(UIGestureRecognizer *)gestureRecognizer
{
    BGLog();

//    проигрываем нажатие на кнопку
    [[[BGAudioPreloader shared] playerForResource:@"button_tap"
                                           ofType:@"mp3"] play];

    //    обновляем кнопку со статусом
    [self updateStatusImageViewWithStatus:kBGStatusImageDefaultViewTag];

    //  сбрасываем старые значения
    [self destroyGameTimer];
    [self resetTimerLabel];
    [self resetMinesCountLabel];

    //    обновляем поле на новое
    [BGSKView shared].paused = NO;
    [[BGSKView shared] startNewGame];
    [self updateMinesCountLabel];

    [self startGameTimer];
}

- (void)back:(id)sender
{
    BGLog();

    //    останавливаем обновление сцены
    [BGSKView shared].paused = YES;

//    проигрываем нажатие на кнопку
    [[[BGAudioPreloader shared] playerForResource:@"button_tap"
                                           ofType:@"mp3"] play];

    //    возвращаемся на главный экран
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)tap:(UIGestureRecognizer *)sender
{
    BGLog();

    //    получаем координаты нажатия
    CGPoint touchPointGlobal = [sender locationInView:self.skView];
    CGPoint touchPoint = [self.skView convertPoint:touchPointGlobal
                                           toScene:self.skView.scene];

    //    получаем ноду, которая находится в точке нажатия
    SKNode *touchedNode = [self.skView.scene nodeAtPoint:touchPoint];

    //    смотрим, что находится под нодой
    if (touchedNode.userData != nil && touchedNode.children.count == 0) {

//    проигрываем откапывание ячейки
        [[[BGAudioPreloader shared] playerForResource:@"grass_tap"
                                               ofType:@"mp3"] play];

        //        проверим значение, которое на поле
        NSUInteger col = [touchedNode.userData[@"col"] unsignedIntegerValue];
        NSUInteger row = [touchedNode.userData[@"row"] unsignedIntegerValue];
        NSInteger value = [[BGSKView shared].field valueForCol:col
                                                           row:row];

        switch (value) {
            case BGFieldBomb: {
                [self stopGameTimer];
                [self updateStatusImageViewWithStatus:kBGStatusImageFailedViewTag];
                [[BGSKView shared] disableFieldInteraction];
                [[BGSKView shared] animateExplosionOnCellWithCol:col
                                                             row:row];
            }
                break;

            default: {
//                открываем клетки
                [[BGSKView shared] openCellsFromCellWithCol:col
                                                        row:row];

                //                проверим, если игра завершена
                BOOL userWon = [[BGSKView shared] isGameFinished];

                if (userWon) {
                    [self stopGameTimer];
                    [self updateStatusImageViewWithStatus:kBGStatusImageWonViewTag];
                    [[BGSKView shared] disableFieldInteraction];
                }
            }
                break;
        }
    }

}

- (void)longPress:(UIGestureRecognizer *)sender
{
    BGLog();

    //    получаем ноду, которая была нажата
    CGPoint touchPointGlobal = [sender locationInView:self.skView];
    CGPoint touchPoint = [self.skView convertPoint:touchPointGlobal
                                           toScene:self.skView.scene];
    SKNode *touchedNode = [self.skView.scene nodeAtPoint:touchPoint];

    //    не обрабатываем начало длинного нажатия, нам нужно только "завершение"
    if (sender.state == UIGestureRecognizerStateBegan) {
        UILabel *minesCountLabel = (UILabel *) [self.view viewWithTag:kBGMinesCountViewTag];
        NSInteger minesRemainedToOpen = [BGSKView shared].field.bombs - [BGSKView shared].flaggedMines;

        if (touchedNode.userData != nil && minesRemainedToOpen != 0) {
            //    проигрываем установку флажка
            [[[BGAudioPreloader shared] playerForResource:@"flag_tap"
                                                   ofType:@"mp3"] play];

            //        устанавливаем
            SKSpriteNode *flagTile = [((BGSKView *) self.skView).tileSprites[@"flag"] copy];
            flagTile.name = @"flag";
            flagTile.anchorPoint = CGPointZero;
            flagTile.size = ((SKSpriteNode *) touchedNode).size;

            [touchedNode addChild:flagTile];

            //            обновляем значение кол-ва бомб
            [BGSKView shared].flaggedMines++;
        } else if ([touchedNode.name isEqualToString:@"flag"]) {
            //        снимаем
            [touchedNode removeFromParent];

            //            обновляем значение кол-ва бомб
            [BGSKView shared].flaggedMines--;
        }

        minesCountLabel.text = [NSString stringWithFormat:@"%04d",
                                                          [BGSKView shared].field.bombs - [BGSKView shared].flaggedMines];
    }
}

- (void)updateTimerLabel:(id)sender
{
    UILabel *timerLabel = (UILabel *) [self.view viewWithTag:kBGTimerViewTag];
    NSInteger timerValue = [timerLabel.text integerValue];

    timerValue++;

    timerLabel.text = [NSString stringWithFormat:@"%04d", timerValue];
}

- (void)resetTimerLabel
{
    BGLog();

    UILabel *timerLabel = (UILabel *) [self.view viewWithTag:kBGTimerViewTag];
    timerLabel.text = [NSString stringWithFormat:@"%04d", 0];
}

- (void)updateMinesCountLabel
{
    UILabel *minesCountLabel = (UILabel *) [self.view viewWithTag:kBGMinesCountViewTag];
    minesCountLabel.text = [NSString stringWithFormat:@"%04d",
                                                      [BGSKView shared].field.bombs];
}

- (void)resetMinesCountLabel
{
    UILabel *minesCountLabel = (UILabel *) [self.view viewWithTag:kBGMinesCountViewTag];
    minesCountLabel.text = [NSString stringWithFormat:@"%04d", 0];
}

- (void)updateStatusImageViewWithStatus:(NSInteger)statusTag
{
    UIImageView *imageView = (UIImageView *) [self.view viewWithTag:kBGStatusImageDefaultViewTag];

    switch (statusTag) {
        case kBGStatusImageFailedViewTag:
            imageView.image = [UIImage imageNamed:@"game_button_failed"];
            break;

        case kBGStatusImageWonViewTag:
            imageView.image = [UIImage imageNamed:@"game_button_win"];
            break;

        default:
            imageView.image = [UIImage imageNamed:@"game_button_default"];
            break;
    }
}

@end
