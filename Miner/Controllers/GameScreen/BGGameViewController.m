//
//  BGGameViewController.m
//  Miner
//
//  Created by AndrewShmig on 3/15/14.
//  Copyright (c) 2014 Bleeding Games. All rights reserved.
//

#import <GameKit/GameKit.h>
#import "BGGameViewController.h"
#import "NAGMinerField.h"
#import "NAGLog.h"
#import "NAGSKView.h"
#import "NAGResourcePreloader.h"
#import "Flurry.h"
#import "NAGSettingsManager.h"
#import "BGAppDelegate.h"


#define TIMER_MAX_VALUE 9999
#define BOMBS_MIN_VALUE 8


// полезные константы тегов для вьюх
static const NSInteger kBGTimerViewTag = 1;
static const NSInteger kBGMinesCountViewTag = 2;


#pragma mark - BGGameViewController

// основная реализация
@implementation BGGameViewController
{
    BOOL _firstTapPerformed;
    NSTimer *_timer;

    CGPoint _scrollPointPrev;
}

#pragma mark - Class methods

+ (instancetype)shared
{
    static dispatch_once_t once;
    static BGGameViewController *sharedInstance;

    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });

    return sharedInstance;
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
        topPanelImageView.frame = CGRectMake(0, 0, topPanelImage.size
                .width, topPanelImage.size.height);

        [self.view addSubview:topPanelImageView];

//        //    добавляем на экран SKView
        CGFloat gameFieldHeight = [UIScreen mainScreen].bounds.size
                .height - topPanelImageView.bounds.size.height;
        CGRect gameViewFrame = CGRectMake(0, topPanelImage.size
                .height, 320, gameFieldHeight);
        self.skView = [[NAGSKView alloc] initWithFrame:gameViewFrame];

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
        newGame.frame = CGRectMake(137, 22, newGameButtonImageOn.size
                .width, newGameButtonImageOn.size.height);
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
                                    initWithFrame:CGRectMake(14, 22, backNormal
                                            .size.width, backNormal.size
                                            .height)];
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
        longPressGestureRecognizer.minimumPressDuration = 0.2;

        [self.skView addGestureRecognizer:longPressGestureRecognizer];

//        добавляем определитель жестов - зум
        UIPinchGestureRecognizer *pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc]
                                                                                      initWithTarget:self
                                                                                              action:@selector(pinchPress:)];
        [self.skView addGestureRecognizer:pinchGestureRecognizer];

//        добавляем определитель жестов - скролл
        UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc]
                                                                                initWithTarget:self
                                                                                        action:@selector(scroll:)];

        [self.skView addGestureRecognizer:panGestureRecognizer];

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

//    засекаем сколько пользователь играет по времени
    [Flurry logEvent:@"UserIsPlaying"
      withParameters:@{
              @"cols"  : @(self.skView.field.cols),
              @"bombs" : @(self.skView.field.bombs)
      }
               timed:YES];

    //    запускаем игровой таймер
    [self startGameTimer];
}

- (void)viewDidDisappear:(BOOL)animated
{
    BGLog();

//    фиксируем время проведенное пользователем на игровом экране
    [Flurry endTimedEvent:@"UserIsPlaying"
           withParameters:nil];

    //    обновляем поле
    //  сбрасываем старые значения
    [self destroyGameTimer];
    [self resetTimerLabel];
    [self resetMinesCountLabel];

    //    обновляем поле на новое
    [self.skView startNewGame];
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
    [[[NAGResourcePreloader shared]
                            playerFromGameConfigForResource:@"buttonTap.mp3"]
                            play];

    //  сбрасываем старые значения
    [self destroyGameTimer];
    [self resetTimerLabel];

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
    [[[NAGResourcePreloader shared]
                            playerFromGameConfigForResource:@"buttonTap.mp3"]
                            play];

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
    SKSpriteNode *touchedNode = (SKSpriteNode *) [self.skView
            .scene nodeAtPoint:touchPoint];

    //    если "слой" на котором находится указанная нода заблокирован для взаимодействия - завершаем
    if (![touchedNode parent].userInteractionEnabled) {
        return;
    }

    //    удаляем картинку по тапу, чтобы была возможность рассмотреть поле и расстановку бомб
    if ([touchedNode.name isEqualToString:@"scoreTable"] || [touchedNode.parent
            .name isEqualToString:@"scoreTable"]) {
        [[[[self.skView.scene childNodeWithName:@"compoundLayer"]
                              childNodeWithName:@"scoreLayer"]
                              childNodeWithName:@"scoreTable"]
                              removeFromParent];
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
        [[[NAGResourcePreloader shared]
                                playerFromGameConfigForResource:@"grassTap.mp3"]
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
                    [self sendUserScoreToGameCenter];
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
    SKSpriteNode *touchedNode = (SKSpriteNode *) [self.skView
            .scene nodeAtPoint:touchPoint];

    //    если слой заблокирован для взаимодействия - завершаем выполнение
    if (![touchedNode.name isEqualToString:@"flag"] && !touchedNode.parent
            .userInteractionEnabled) {
        return;
    }

    //    не обрабатываем начало длинного нажатия, нам нужно только "завершение"
    if (sender.state == UIGestureRecognizerStateBegan) {

        UILabel *minesCountLabel = (UILabel *) [self
                .view viewWithTag:kBGMinesCountViewTag];
        NSInteger minesRemainedToOpen = self.skView.field.bombs - self.skView
                .flaggedMines;

        if (touchedNode.children.count == 0 && touchedNode
                .userData != nil && minesRemainedToOpen != 0) {
            //    проигрываем установку флажка
            [[[NAGResourcePreloader shared]
                                    playerFromGameConfigForResource:@"flagTapOn.mp3"]
                                    play];

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
            [[[NAGResourcePreloader shared]
                                    playerFromGameConfigForResource:@"flagTapOff.mp3"]
                                    play];

            //        снимаем флаг
            [touchedNode removeFromParent];

            //            обновляем значение кол-ва бомб
            self.skView.flaggedMines--;
        }

        minesCountLabel.text = [NSString stringWithFormat:@"%04d",
                                                          self.skView.field
                                                                  .bombs - self
                                                                  .skView
                                                                  .flaggedMines];
    }
}

- (void)scroll:(UIPanGestureRecognizer *)sender
{
    BGLog();

    SKNode *compoundLayer = [self.skView
            .scene childNodeWithName:@"compoundLayer"];
    SKNode *grassLayer = [compoundLayer childNodeWithName:@"grassLayer"];
    SKNode *earthLayer = [compoundLayer childNodeWithName:@"earthLayer"];

    CGPoint panPoint = [sender translationInView:sender.view];
    panPoint = [self.skView.scene convertPointFromView:panPoint];

    switch (sender.state) {
        case UIGestureRecognizerStateBegan: {
            _scrollPointPrev = panPoint;
        }
            break;

        case UIGestureRecognizerStateChanged: {

//            вектор перемещения игрового поля
            CGVector delta = CGVectorMake(-(_scrollPointPrev.x - panPoint.x),
                    -(_scrollPointPrev.y - panPoint.y));

            CGFloat newXGrassLayerPosition = grassLayer.position.x + delta.dx;
            CGFloat newYGrassLayerPosition = grassLayer.position.y + delta.dy;
            CGFloat maxAllowedX = self.skView.scene.size.width - grassLayer
                    .calculateAccumulatedFrame.size.width;
            CGFloat maxAllowedY = self.skView.scene.size.height - grassLayer
                    .calculateAccumulatedFrame.size.height;

//            корректируем положение левого угла игрового поля
            if (newXGrassLayerPosition > 0)
                delta.dx = 0.0 - grassLayer.position.x;
            if (newYGrassLayerPosition > 0)
                delta.dy = 0.0 - grassLayer.position.y;

//            если перемещение игрового поля возможно - передвигаем
            if (grassLayer.position.x + delta.dx <= 0.0 && grassLayer.position
                    .y + delta.dy <= 0.0 &&
                    grassLayer.position.x + delta
                            .dx >= maxAllowedX && grassLayer.position.y + delta
                    .dy >= maxAllowedY) {

                grassLayer.position = CGPointMake(grassLayer.position.x + delta
                        .dx, grassLayer.position.y + delta.dy);
                earthLayer.position = CGPointMake(earthLayer.position.x + delta
                        .dx, earthLayer.position.y + delta.dy);
            }

//            обновляем предыдущую "опорную" точку
            _scrollPointPrev = panPoint;
        }

        default:
            break;
    }
}

- (void)pinchPress:(UIPinchGestureRecognizer *)sender
{
    BGLog();

    SKNode *compoundNode = [self.skView
            .scene childNodeWithName:@"compoundLayer"];
    SKNode *grassLayer = [compoundNode childNodeWithName:@"grassLayer"];
    SKNode *earthLayer = [compoundNode childNodeWithName:@"earthLayer"];

//    минимальный и максимальный масштабы игрового поля
    CGFloat minAllowedScale = [self.skView standardScaleForCols:self.skView
            .field.cols];
    CGFloat maxAllowedScale = 2.0;

//    точка зум-ина или зум-аута
    CGPoint pinchPoint = [sender locationInView:sender.view];
    CGPoint scenePinchPoint = [self.skView
            .scene convertPointFromView:pinchPoint];

    CGPoint anchorPoint = CGPointMake(scenePinchPoint.x - grassLayer.position.x,
            scenePinchPoint.y - grassLayer.position.y);
    CGVector delta = CGVectorMake(anchorPoint.x - sender.scale * anchorPoint.x,
            anchorPoint.y - sender.scale * anchorPoint.y);

    if (sender.scale > 1.0 && grassLayer.xScale < maxAllowedScale) { // zoom-in

        [grassLayer runAction:[SKAction group:@[
                [SKAction scaleBy:sender.scale duration:0.0],
                [SKAction moveBy:delta duration:0.0]
        ]]];
        [earthLayer runAction:[SKAction group:@[
                [SKAction scaleBy:sender.scale duration:0.0],
                [SKAction moveBy:delta duration:0.0]
        ]]];
    } else if (sender.scale < 1.0 && grassLayer
            .xScale > minAllowedScale) { // zoom-out

        [grassLayer runAction:[SKAction group:@[
                [SKAction scaleTo:minAllowedScale duration:0.2],
                [SKAction moveTo:CGPointZero duration:0.2]
        ]]];

        [earthLayer runAction:[SKAction group:@[
                [SKAction scaleTo:minAllowedScale duration:0.2],
                [SKAction moveTo:CGPointZero duration:0.2]
        ]]];
    }

    sender.scale = 1.0;
}

- (void)updateTimerLabel:(id)sender
{
    //    BGLog();

    UILabel *timerLabel = (UILabel *) [self.view viewWithTag:kBGTimerViewTag];
    NSInteger timerValue = [timerLabel.text integerValue];
    timerValue++;

    //    9999 - конец игры, останавливаем таймер
    if (timerValue == 9999) {
        [self stopGameTimer];
    }

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

    UILabel *minesCountLabel = (UILabel *) [self
            .view viewWithTag:kBGMinesCountViewTag];
    minesCountLabel.text = [NSString stringWithFormat:@"%04d",
                                                      self.skView.field.bombs];
}

- (void)resetMinesCountLabel
{
    BGLog();

    UILabel *minesCountLabel = (UILabel *) [self
            .view viewWithTag:kBGMinesCountViewTag];
    minesCountLabel.text = [NSString stringWithFormat:@"%04d", 0];
}

- (void)sendUserScoreToGameCenter
{
    BGLog();

//    если пользователь не авторизован, то нет смысла обрабатывать его счет
    if (![GKLocalPlayer localPlayer].isAuthenticated ||
            ![[NAGSettingsManager shared]
                                  boolValueForSettingsPath:@"game.settings.gameCenterOn"])
        return;

//    определяем таблицу лидеров в которую необходимо отправить счет
    NSMutableString *leaderboardID = [NSMutableString string];

    switch ([[NAGSettingsManager shared]
                                 integerValueForSettingsPath:@"game.settings.level"]) {
        case 1:
            [leaderboardID appendString:@"easy"];
            break;

        case 2:
            [leaderboardID appendString:@"norm"];
            break;

        case 3:
            [leaderboardID appendString:@"hard"];
            break;

        default:
            break;
    }

    NSInteger smallFieldCols = [[NAGSettingsManager shared]
                                                    integerValueForSettingsPath:@"game.field.small.cols"];
    NSInteger mediumFieldCols = [[NAGSettingsManager shared]
                                                     integerValueForSettingsPath:@"game.field.medium.cols"];
    NSInteger bigFieldCols = [[NAGSettingsManager shared]
                                                  integerValueForSettingsPath:@"game.field.big.cols"];
    NSInteger currentCols = [[NAGSettingsManager shared]
                                                 integerValueForSettingsPath:@"game.settings.cols"];

    if (currentCols == smallFieldCols)
        [leaderboardID appendString:@"12x8"];
    else if (currentCols == mediumFieldCols)
        [leaderboardID appendString:@"15x10"];
    else if (currentCols == bigFieldCols)
        [leaderboardID appendString:@"24x16"];

//    создаем объект со счетом
    GKScore *score = [[GKScore alloc]
                               initWithLeaderboardIdentifier:leaderboardID];
    score.value = [self gameScore];

    [GKScore reportScores:@[score]
    withCompletionHandler:^(NSError *error)
            {
                NSLog(@"Score: %@", @(score.value));

//        отправим сообщение о том, что пользователь отправил свой счет в ГЦ
//        соберем статистику о тех, у кого ГЦ активен
                [Flurry logEvent:@"UserSubmittedGameScore"];
            }];
}

#pragma mark - Game Center

- (void)authorizeLocalPlayer
{
    BGLog();

    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    __block BGAppDelegate *delegate = (BGAppDelegate *) [UIApplication sharedApplication]
            .delegate;

    localPlayer.authenticateHandler = ^(UIViewController *authController,
                                        NSError *error) {
        if (nil != authController) {
            [delegate.window
                    .rootViewController presentViewController:authController
                                                     animated:YES
                                                   completion:nil];
        }
    };
}

- (NSUInteger)gameScore
{
    UILabel *timerLabel = (UILabel *) [self.view viewWithTag:kBGTimerViewTag];
    NSInteger timerValue = [timerLabel.text integerValue];

    return (NSUInteger) (TIMER_MAX_VALUE * ([BGGameViewController shared].skView
            .field.bombs - BOMBS_MIN_VALUE + 1) - timerValue);
}

@end