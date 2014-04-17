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


#pragma mark - BGGameViewController

// основная реализация
@implementation BGGameViewController
{
    BOOL _firstTapPerformed;
    NSTimer *_timer;
}

#pragma mark - Class methods

+ (instancetype)shared
{
    static dispatch_once_t once;
    static BGGameViewController *shared;

    dispatch_once(&once, ^
    {
        shared = [[self alloc] init];
    });

    return shared;
}

#pragma mark - Init

- (id)init
{
    self = [super init];

    if (self) {
        //    добавляем изображение верхней панели
        UIImage *topPanelImage = [UIImage imageNamed:@"top_game"];
        UIImageView *topPanelImageView = [[UIImageView alloc]
                                                       initWithImage:topPanelImage];
        topPanelImageView.frame = CGRectMake(0, 0, topPanelImage.size.width, topPanelImage.size.height);

        [self.view addSubview:topPanelImageView];

        //    добавляем на экран SKView
        CGRect gameViewFrame = CGRectMake(0, topPanelImage.size.height, 320, 480);
        self.skView = [[BGSKView alloc] initWithFrame:gameViewFrame];
        [self.view addSubview:self.skView];

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

//        кнопка старта новой игры
        UIImage *newGameButtonImageOn = [UIImage imageNamed:@"game_button_on"];
        UIImage *newGameButtonImageOff = [UIImage imageNamed:@"game_button_off"];
        UIButton *newGame = [UIButton buttonWithType:UIButtonTypeCustom];
        newGame.frame = CGRectMake(137, 22, newGameButtonImageOn.size.width, newGameButtonImageOn.size.height);
        [newGame setImage:newGameButtonImageOn forState:UIControlStateNormal];
        [newGame setImage:newGameButtonImageOff
                 forState:UIControlStateHighlighted];
        [newGame addTarget:self
                    action:@selector(statusImageViewTap:)
          forControlEvents:UIControlEventTouchUpInside];

        [self.view addSubview:newGame];

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
        longPressGestureRecognizer.minimumPressDuration = 0.3;

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
    BGLog();

    [super viewWillAppear:animated];

    //        было ли первое нажатие по полю, используется для того, чтобы _только_
    //        после первого нажатия генерировать игровое поле
    _firstTapPerformed = NO;

    //    обновляем надпись с кол-вом мин
    [self updateMinesCountLabel];

    //    запускаем обновление сцены
    self.skView.paused = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    BGLog();

    //    запускаем игровой таймер
    [self startGameTimer];
}

- (void)viewDidDisappear:(BOOL)animated
{
    BGLog();

    //    обновляем поле
    //  сбрасываем старые значения
    [self destroyGameTimer];
    [self resetTimerLabel];
    [self resetMinesCountLabel];

    //    обновляем поле на новое
    [self.skView startNewGame];

//    TODO: нужен ли здесь этот апдейт, если в viewWillAppear уже происходит обновление?
    [self updateMinesCountLabel];
}

#pragma mark - Game & Private

- (void)startGameTimer
{
    BGLog();

    //    запускаем таймер игры
    if (_timer == nil) {
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

- (void)statusImageViewTap:(id)sender
{
    BGLog();

    //    проигрываем нажатие на кнопку
    [[[BGAudioPreloader shared] playerFromGameConfigForResource:@"buttonTap"
                                                         ofType:@"mp3"] play];

    //  сбрасываем старые значения
    [self destroyGameTimer];
    [self resetTimerLabel];

//    TODO: зачем здесь это, если чуть дальше идет создание нового поля и установка нового значения кол-ва бомб?
    [self resetMinesCountLabel];

    //    обновляем поле на новое
    self.skView.paused = NO;
    [self.skView startNewGame];
    _firstTapPerformed = NO;

    [self updateMinesCountLabel];

    [self startGameTimer];
}

- (void)back:(id)sender
{
    BGLog();

    //    останавливаем обновление сцены
    self.skView.paused = YES;

    //    проигрываем нажатие на кнопку
    [[[BGAudioPreloader shared] playerFromGameConfigForResource:@"buttonTap"
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
    SKSpriteNode *touchedNode = (SKSpriteNode *) [self.skView.scene nodeAtPoint:touchPoint];

//    если "слой" на котором находится указанная нода заблокирован для взаимодействия - завершаем
    if (![touchedNode parent].userInteractionEnabled) {
        return;
    }

//    удаляем картинку по тапу, чтобы была возможность рассмотреть поле и расстановку бомб
    if ([touchedNode.name isEqualToString:@"smile"]) {
        [touchedNode removeFromParent];
        return;
    }

    //    если нажатие произошло на ноде с травой - обрабатываем
    if (touchedNode.userData != nil && touchedNode.children.count == 0) {

        NSUInteger col = [touchedNode.userData[@"col"] unsignedIntegerValue];
        NSUInteger row = [touchedNode.userData[@"row"] unsignedIntegerValue];
        NSInteger value = [self.skView.field valueForCol:col
                                                     row:row];

        if (!_firstTapPerformed) {
//            первое нажатие - генерируем реальное поле
            [self.skView fillEarthWithTilesExcludingBombAtCellWithCol:col
                                                                  row:row];
            _firstTapPerformed = YES;
        }

        //    проигрываем откапывание ячейки
        [[[BGAudioPreloader shared] playerFromGameConfigForResource:@"grassTap"
                                                             ofType:@"mp3"]
                            play];

        //        проверим значение, которое на поле
        switch (value) {
            case BGFieldBomb: {
                [self stopGameTimer];
                [self.skView disableFieldInteraction];
                [self.skView animateExplosionOnCellWithCol:col
                                                       row:row];
            }
                break;

            default: {
                //                открываем клетки
                [self.skView openCellsFromCellWithCol:col
                                                  row:row];

                //                проверим, если игра завершена
                BOOL userWon = [self.skView isGameFinished];

                if (userWon) {
                    [self stopGameTimer];
                    [self.skView disableFieldInteraction];
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
    SKSpriteNode *touchedNode = (SKSpriteNode *) [self.skView.scene nodeAtPoint:touchPoint];

//    если слой заблокирован для взаимодействия - завершаем выполнение
//    TODO: сделать так, чтобы после выигрыша нельзя было снимать флажки с клеток
    if (![touchedNode.name isEqualToString:@"flag"] && !touchedNode.parent.userInteractionEnabled) {
        return;
    }

    //    не обрабатываем начало длинного нажатия, нам нужно только "завершение"
    if (sender.state == UIGestureRecognizerStateBegan) {

        UILabel *minesCountLabel = (UILabel *) [self.view viewWithTag:kBGMinesCountViewTag];
        NSInteger minesRemainedToOpen = self.skView.field.bombs - self.skView.flaggedMines;

        if (touchedNode.children.count == 0 && touchedNode.userData != nil && minesRemainedToOpen != 0) {
            //    проигрываем установку флажка
            [[[BGAudioPreloader shared]
                                playerFromGameConfigForResource:@"flagTapOn"
                                                         ofType:@"mp3"] play];

            //        устанавливаем флаг
            SKSpriteNode *flagTile = [self.skView.tileSprites[@"flag"] copy];
            flagTile.anchorPoint = CGPointZero;
            flagTile.size = touchedNode.size;
            flagTile.name = @"flag";

            [touchedNode addChild:flagTile];

            //            обновляем значение кол-ва бомб
            self.skView.flaggedMines++;
        } else if ([touchedNode.name isEqualToString:@"flag"]) {
            //    проигрываем снятие флажка
            [[[BGAudioPreloader shared]
                                playerFromGameConfigForResource:@"flagTapOff"
                                                         ofType:@"mp3"] play];

            //        снимаем флаг
            [touchedNode removeFromParent];

            //            обновляем значение кол-ва бомб
            self.skView.flaggedMines--;
        }

        minesCountLabel.text = [NSString stringWithFormat:@"%04d",
                                                          self.skView.field.bombs - self.skView.flaggedMines];
    }
}

- (void)updateTimerLabel:(id)sender
{
    //    BGLog();

    UILabel *timerLabel = (UILabel *) [self.view viewWithTag:kBGTimerViewTag];
    NSInteger timerValue = [timerLabel.text integerValue];
    timerValue++;

    NSString *newValue = [NSString stringWithFormat:@"%04d", timerValue];

    timerLabel.text = newValue;
}

- (void)resetTimerLabel
{
    BGLog();

    UILabel *timerLabel = (UILabel *) [self.view viewWithTag:kBGTimerViewTag];
    timerLabel.text = [NSString stringWithFormat:@"%04d", 0];
}

- (void)updateMinesCountLabel
{
    BGLog();

    UILabel *minesCountLabel = (UILabel *) [self.view viewWithTag:kBGMinesCountViewTag];
    minesCountLabel.text = [NSString stringWithFormat:@"%04d",
                                                      self.skView.field.bombs];
}

- (void)resetMinesCountLabel
{
    BGLog();

    UILabel *minesCountLabel = (UILabel *) [self.view viewWithTag:kBGMinesCountViewTag];
    minesCountLabel.text = [NSString stringWithFormat:@"%04d", 0];
}

@end
