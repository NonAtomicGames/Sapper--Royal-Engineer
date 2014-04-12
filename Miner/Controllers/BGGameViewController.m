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
#import "BGLog.h"
#import "BGSKView.h"


// полезные константы тегов для вьюх
static const NSInteger kBGTimerViewTag = 1;
static const NSInteger kBGMinesCountViewTag = 2;
static const NSInteger kBGStatusImageDefaultViewTag = 3;
static const NSInteger kBGStatusImageFailedViewTag = 4;
static const NSInteger kBGStatusImageWonViewTag = 5;

//    переменная-хак для удаления "общей" (содержащей слой с травой и землей) ноды,
//    которая при создании новой игры будет находится под только что сгенерированным полем
static NSInteger compoundNodeZPosition = 0;

// игровое поле
BGMinerField *_field;
// кол-во отмеченых бомб
NSUInteger flaggedMines;


#pragma mark - BGGameViewController

// основная реализация
@implementation BGGameViewController

#pragma mark - View

- (void)viewDidLoad
{
    BGLog(@"%s", __FUNCTION__);

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

//    добавляем сцену на SKView
    SKScene *scene = [[SKScene alloc] initWithSize:self.skView.frame.size];
    scene.userInteractionEnabled = NO;
    [self.skView presentScene:scene];

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

- (void)viewDidAppear:(BOOL)animated
{
    BGLog();

//    запускаем игру
    [self startNewGame];
    [self startGameTimer];
}

- (void)viewDidDisappear:(BOOL)animated
{
    BGLog();

    [self destroyGameTimer];
    [self resetMinesCountLabel];
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

- (void)startNewGame
{
//    нет отмеченных бомб
    flaggedMines = 0;

//    генерируем поле
    NSUInteger rows = [BGSettingsManager sharedManager].rows;
    NSUInteger cols = [BGSettingsManager sharedManager].cols;
    NSUInteger bombs = [BGSettingsManager sharedManager].bombs;

    _field = [[BGMinerField alloc] initWithCols:cols
                                           rows:rows
                                          bombs:bombs];
//    сбрасываем старый таймер
    [self destroyGameTimer];

//    сбрасываем значение надписи таймера
    [self resetTimerLabel];

//    обновим надпись с кол-вом бомб
    [self updateMinesCountLabel];

//    заполняем SKView спрайтами с бомбами, цифрами и пустыми полями
//    потом накладываем на них траву
    [self fillGameSceneField];

//    разрешаем пользователю взаимодействовать с полем
    [self enableFieldInteraction];

//    удалим старый игровой слой
    [self.skView.scene enumerateChildNodesWithName:@"compoundNode"
                                        usingBlock:^(SKNode *node, BOOL *stop)
                                        {
                                            if (node.zPosition != compoundNodeZPosition) {
                                                [node removeFromParent];
                                            }
                                        }];

//    запускаем таймер
    [self startGameTimer];
}

- (void)fillGameSceneField
{
//    нода для хранения слоёв - заднего и переднего
    SKNode *compoundNode = [SKNode node];
    compoundNode.name = @"compoundNode";
    compoundNode.zPosition = (compoundNodeZPosition == 0 ? (compoundNodeZPosition = 1) : (compoundNodeZPosition = 0));

//    нода для хранения первого слоя
    SKNode *layer1 = [SKNode node];
    layer1.userInteractionEnabled = NO;
    layer1.zPosition = 0;

//    нода для хранения второго слоя
    SKNode *layer2 = [SKNode node];
    layer2.name = @"grassTiles";
    layer2.zPosition = 1;

//    заполняем первый слой - цифры, земля и сами бомбы
    for (NSUInteger indexCol = 0; indexCol < _field.cols; indexCol++) {
        for (NSUInteger indexRow = 0; indexRow < _field.rows; indexRow++) {
            NSInteger fieldValue = [_field valueForCol:indexCol
                                                   row:indexRow];
            SKSpriteNode *tile;

            switch (fieldValue) {
                case BGFieldBomb: // бомба
                    tile = [((BGSKView *) self.skView).tileSprites[@"mine"] copy];
                    break;

                case BGFieldEmpty: // земля
                    tile = [((BGSKView *) self.skView).tileSprites[@"earth"] copy];
                    break;

                default: {
                    NSString *spriteName = [NSString stringWithFormat:@"earth%d",
                                                                      fieldValue];
                    tile = [((BGSKView *) self.skView).tileSprites[spriteName] copy];

                    break;
                }
            }

//            устанавливаем размеры спрайта
            if ([BGSettingsManager sharedManager].cols == 12)
                tile.size = CGSizeMake(40, 40);
            else if ([BGSettingsManager sharedManager].cols == 15)
                tile.size = CGSizeMake(32, 32);
            else
                tile.size = CGSizeMake(20, 20);

//            позиционируем
            tile.anchorPoint = CGPointZero;
            CGFloat x = indexRow * tile.size.width;
            CGFloat y = indexCol * tile.size.height;
            tile.position = CGPointMake(x, y);
            tile.zPosition = 0;

//            добавляем на слой
            [layer1 addChild:tile];

//            накладываем слой с травой
            SKSpriteNode *grassTile = [((BGSKView *) self.skView).tileSprites[@"grass"] copy];

            grassTile.position = tile.position;
            grassTile.size = tile.size;
            grassTile.anchorPoint = CGPointZero;
            grassTile.userData = [@{
                    @"col" : @(indexCol),
                    @"row" : @(indexRow)
            } mutableCopy];
            grassTile.zPosition = 0;
            grassTile.name = [NSString stringWithFormat:@"%d.%d",
                                                        indexCol,
                                                        indexRow];

            [layer2 addChild:grassTile];
        }
    }

//    добавляем на поле первый слой
    [compoundNode addChild:layer1];

//    накладываем второй слой
    [compoundNode addChild:layer2];

//    добавляем всё на сцену
    [self.skView.scene addChild:compoundNode];
}

- (void)animateExplosionOnCellWithCol:(NSUInteger)col
                                  row:(NSUInteger)row
{
    BGLog();

//    TODO
}

- (void)openCellsFromCellWithCol:(NSUInteger)col
                             row:(NSUInteger)row
{
    BGLog();

//    определяем все ячейки, которые необходимо открыть
    NSMutableSet *usedCells = [NSMutableSet new];
    NSMutableArray *queue = [NSMutableArray new];
    NSArray *x = @[@0, @1, @0, @(-1), @1, @1, @(-1), @(-1)];
    NSArray *y = @[@(-1), @0, @1, @0, @(-1), @1, @1, @(-1)];

    [queue addObject:@(col)];
    [queue addObject:@(row)];
    [usedCells addObject:[NSString stringWithFormat:@"%d.%d", col, row]];

    while (queue.count > 0) {
        NSUInteger currentCol = [queue[0] unsignedIntegerValue];
        NSUInteger currentRow = [queue[1] unsignedIntegerValue];

        [queue removeObjectAtIndex:0];
        [queue removeObjectAtIndex:0];

//        удаляем с верхнего слоя тайл с травой
        NSString *nodeName = [NSString stringWithFormat:@"%d.%d",
                                                        currentCol,
                                                        currentRow];
        SKNode *grassNodeToRemoveFromParent = [[[self.skView.scene childNodeWithName:@"compoundNode"]
                                                                   childNodeWithName:@"grassTiles"]
                                                                   childNodeWithName:nodeName];

//        проверим, если на ячейке стоит флажок
//        стоит - не удаляем ячейку
        if ([grassNodeToRemoveFromParent childNodeWithName:@"flag"]) {
            continue;
        }

        [grassNodeToRemoveFromParent removeFromParent];

//        нет смысла продолжать открывать клетки, если текущий тайл с цифрой
        NSInteger value = [_field valueForCol:currentCol
                                          row:currentRow];

        if (value != BGFieldBomb && value != BGFieldEmpty) {
            continue;
        }

        for (NSUInteger k = 0; k < x.count; k++) {
            NSInteger newCol = currentCol + [y[k] integerValue];
            NSInteger newRow = currentRow + [x[k] integerValue];

            if (newCol >= 0 && newRow >= 0 && newCol < _field.cols && newRow < _field.rows) {
                NSString *cellName = [NSString stringWithFormat:@"%d.%d",
                                                                newCol,
                                                                newRow];

//                добавляем еще неиспользованную клетку, если она пустая
                if ([_field valueForCol:(NSUInteger) newCol
                                    row:(NSUInteger) newRow] != BGFieldBomb && ![usedCells containsObject:cellName]) {
                    [queue addObject:@(newCol)];
                    [queue addObject:@(newRow)];

                    [usedCells addObject:cellName];
                }
            }
        }
    }
}

- (void)openCellsWithBombs
{
    BGLog(@"%s", __FUNCTION__);

//    TODO
}

- (BOOL)isGameFinished
{
    BGLog();

    SKNode *grassTilesNode = [[self.skView.scene childNodeWithName:@"compoundNode"]
                                                 childNodeWithName:@"grassTiles"];
    NSInteger remainedGrassTiles = [grassTilesNode.children count];
    __block BOOL isGameFinished;

    if (remainedGrassTiles == _field.bombs) {
        isGameFinished = YES;

        [grassTilesNode enumerateChildNodesWithName:@"*"
                                         usingBlock:^(SKNode *node, BOOL *stop)
                                         {
                                             NSUInteger col = [node.userData[@"col"] unsignedIntegerValue];
                                             NSUInteger row = [node.userData[@"row"] unsignedIntegerValue];

                                             NSInteger value = [_field valueForCol:col
                                                                               row:row];

                                             if (value == BGFieldBomb) {}
                                             else {
                                                 *stop = YES;
                                                 isGameFinished = NO;
                                             }
                                         }];
    } else {
        isGameFinished = NO;
    }

    return isGameFinished;
}

#pragma mark - Actions

- (void)statusImageViewTap:(UIGestureRecognizer *)gestureRecognizer
{
    BGLog();

//    обновляем кнопку со статусом
    [self updateStatusImageViewWithStatus:kBGStatusImageDefaultViewTag];

//    начинаем игру заново
    [self startNewGame];
}

- (void)back:(id)sender
{
    BGLog();

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
    if (touchedNode.userData != nil) {
        [touchedNode removeFromParent];

//        проверим значение, которое на поле
        NSUInteger col = [touchedNode.userData[@"col"] unsignedIntegerValue];
        NSUInteger row = [touchedNode.userData[@"row"] unsignedIntegerValue];
        NSInteger value = [_field valueForCol:col
                                          row:row];

        switch (value) {
            case BGFieldBomb: {
                [self stopGameTimer];
                [self updateStatusImageViewWithStatus:kBGStatusImageFailedViewTag];
                [self disableFieldInteraction];
                [self animateExplosionOnCellWithCol:col
                                                row:row];
                [self openCellsWithBombs];
            }

                break;

            case BGFieldEmpty: {
                [self openCellsFromCellWithCol:col
                                           row:row];
            }

            default: {
//                проверим, если игра завершена
                BOOL userWon = [self isGameFinished];

                if (userWon) {
                    [self stopGameTimer];
                    [self disableFieldInteraction];
                    [self updateStatusImageViewWithStatus:kBGStatusImageWonViewTag];
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
        NSInteger minesRemainedToOpen = _field.bombs - flaggedMines;

        if (touchedNode.userData != nil && minesRemainedToOpen != 0) {
//        устанавливаем
            SKSpriteNode *flagTile = [((BGSKView *) self.skView).tileSprites[@"flag"] copy];
            flagTile.name = @"flag";
            flagTile.anchorPoint = CGPointZero;
            flagTile.size = ((SKSpriteNode *) touchedNode).size;

            [touchedNode addChild:flagTile];

//            обновляем значение кол-ва бомб
            flaggedMines++;
        } else if ([touchedNode.name isEqualToString:@"flag"]) {
//        снимаем
            [touchedNode removeFromParent];

//            обновляем значение кол-ва бомб
            flaggedMines--;
        }

        minesCountLabel.text = [NSString stringWithFormat:@"%04d",
                                                          _field.bombs - flaggedMines];
    }
}

- (void)updateTimerLabel:(id)sender
{
    BGLog();

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
    minesCountLabel.text = [NSString stringWithFormat:@"%04d", _field.bombs];
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

- (void)disableFieldInteraction
{
    self.skView.userInteractionEnabled = NO;
}

- (void)enableFieldInteraction
{
    self.skView.userInteractionEnabled = YES;
}

@end
