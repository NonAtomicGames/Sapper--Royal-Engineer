//
//  NAGSKView.m
//  Miner
//
//  Created by AndrewShmig on 4/12/14.
//  Copyright (c) 2014 Russian Bleeding Games. All rights reserved.
//

#import "NAGSKView.h"
#import "NAGLog.h"
#import "NAGSettingsManager.h"
#import "NAGMinerField.h"
#import "NAGResourcePreloader.h"
#import "BGGameViewController.h"


// константа для "кодирования" координаты в одно значение
static const NSInteger kBGPrime = 1001;


// сцена для отображения игрового поля
@interface BGSKScene : SKScene
@end

@implementation BGSKScene
@end


@interface NAGSKView ()
@property NSMutableArray *mineAnimationTextures;
@property NSMutableArray *grassAnimationTextures;
@property NSMutableArray *explosionAnimationTextures;
@end


@implementation NAGSKView

#pragma mark - Init

- (id)initWithFrame:(CGRect)frame
{
    BGLog();

    self = [super initWithFrame:frame];

    if (self) {
        __weak NAGSKView *weakSelf = self;

        //        работаем с текстурами и атласами
        _tileAtlas = [SKTextureAtlas atlasNamed:@"Tiles"];
        _grassAnimationAtlas = [SKTextureAtlas atlasNamed:@"GrassAnimation"];
        _mineAnimationAtlas = [SKTextureAtlas atlasNamed:@"MineAnimation"];
        _explosionAnimationAtlas = [SKTextureAtlas atlasNamed:@"Explosion"];

        _tileSprites = [NSMutableDictionary new];
        _mineAnimationTextures = [NSMutableArray new];
        _grassAnimationTextures = [NSMutableArray new];
        _explosionAnimationTextures = [NSMutableArray new];

        //        отключаем обновления сцены, чтобы в неактивном режиме сцена не обновлялась
        self.paused = YES;

        [SKTextureAtlas preloadTextureAtlases:@[_tileAtlas,
                                                _grassAnimationAtlas,
                                                _mineAnimationAtlas,
                                                _explosionAnimationAtlas]
                        withCompletionHandler:^
                {
                    //                            добавляем сцену на текущий SKView
                    BGSKScene *gameScene = [[BGSKScene alloc]
                                                       initWithSize:weakSelf
                                                               .frame.size];
                    gameScene.userInteractionEnabled = YES;
                    [weakSelf presentScene:gameScene];

                    //    создаем основные узлы для хранения слоёв - травы, земли
                    [weakSelf createInitialLayers];

                    //                            создаем сильные ссылки на текстуры (земля, цифры, трава)
                    for (NSString *textureFullName in weakSelf.tileAtlas
                            .textureNames) {
                        NSString *textureName = [textureFullName componentsSeparatedByString:@"@"][0];
                        SKTexture *texture = [weakSelf
                                .tileAtlas textureNamed:textureFullName];

                        weakSelf.tileSprites[textureName] = [SKSpriteNode spriteNodeWithTexture:texture];
                    }

                    //                            добавляем текстуры анимации пикания бомбы
                    for (NSUInteger animationFrame = 0; animationFrame < weakSelf
                            .mineAnimationAtlas.textureNames
                            .count; animationFrame++) {
                        NSString *frameName = [NSString stringWithFormat:@"mine_found%04d@2x.png",
                                                                         (NSInteger) animationFrame];
                        SKTexture *texture = [weakSelf
                                .mineAnimationAtlas textureNamed:frameName];
                        [weakSelf.mineAnimationTextures addObject:texture];
                    }

                    //                            добавляем текстуры анимации травы
                    for (NSUInteger animationFrame = 0; animationFrame < weakSelf
                            .grassAnimationAtlas.textureNames
                            .count; animationFrame++) {
                        NSString *frameName = [NSString stringWithFormat:@"Grass_animation%04d@2x.png",
                                                                         (NSInteger) animationFrame];
                        SKTexture *texture = [weakSelf
                                .grassAnimationAtlas textureNamed:frameName];
                        [weakSelf.grassAnimationTextures addObject:texture];
                    }

                    //                            добавляем текстуры анимации взрыва
                    for (NSUInteger animationFrame = 0; animationFrame < weakSelf
                            .explosionAnimationAtlas.textureNames
                            .count; animationFrame++) {
                        NSString *frameName = [NSString stringWithFormat:@"explosion_%05d@2x.png",
                                                                         (NSInteger) (animationFrame + 60)];

                        SKTexture *texture = [weakSelf
                                .explosionAnimationAtlas textureNamed:frameName];
                        [weakSelf.explosionAnimationTextures addObject:texture];
                    }

                    //                            начнем игру, таймер не запускаем
                    [weakSelf startNewGame];
                }];
    }

    return self;
}

#pragma mark - Game

- (void)startNewGame
{
    BGLog();

    //    генерируем каркас игрового поля
    NSUInteger cols = [[NAGSettingsManager shared]
                                           unsignedIntegerValueForSettingsPath:@"game.settings.cols"];
    NSUInteger rows = [[NAGSettingsManager shared]
                                           unsignedIntegerValueForSettingsPath:@"game.settings.rows"];
    NSUInteger level = [[NAGSettingsManager shared]
                                            unsignedIntegerValueForSettingsPath:@"game.settings.level"];

    _field = [[NAGMinerField alloc]
                             initWithCols:cols
                                     rows:rows
                                    bombs:[self randomNumberOfBombsForRows:rows
                                                                      cols:cols
                                                                     level:level]];

    //    сбрасываем игровые параметры на начальные состояния
    [self resetGameData];

    //    заполняем поле травой
    [self fillFieldWithGrassTiles];

    //    изменяем параметры скейла поля в зависимости от размера поля
    [self adjustCompoundLayerScale];

    //    разрешаем пользователю взаимодействовать с полем
    [self enableFieldInteraction];
}

- (void)fillEarthWithTilesExcludingBombAtCellWithCol:(NSUInteger)cellCol
                                                 row:(NSUInteger)cellRow
{
    BGLog();

    //    генерируем реальное поле
    [self.field generateFieldWithExcludedCellInCol:cellCol
                                               row:cellRow];

    //    получаем ноду с "землей"
    SKNode *earthLayer = [[self.scene childNodeWithName:@"compoundLayer"]
                                      childNodeWithName:@"earthLayer"];

    //    размеры поля берем из настроек
    NSUInteger colsFromSettings = self.field.cols;
    NSUInteger rowsFromSettings = self.field.rows;

    //    заполняем узел с именем grassLayer тайлами с травой
    for (NSUInteger indexCol = 0; indexCol < colsFromSettings; indexCol++) {
        for (NSUInteger indexRow = 0; indexRow < rowsFromSettings; indexRow++) {
            NSString *uniqueCellName = [NSString stringWithFormat:@"%d",
                                                                  (NSInteger) (indexCol * kBGPrime + indexRow)];
            NSInteger fieldValue = [self.field valueForCol:indexCol
                                                       row:indexRow];
            SKSpriteNode *earthTile;

            //            выбираем нужный тайл
            switch (fieldValue) {
                case BGFieldBomb:
                    earthTile = [self.tileSprites[@"mine"] copy];
                    break;

                case BGFieldEmpty:
                    earthTile = [self.tileSprites[@"earth"] copy];
                    break;

                default: {
                    NSString *earthTileName = [NSString stringWithFormat:@"earth%ld",
                                                                         (long) fieldValue];
                    earthTile = [self.tileSprites[earthTileName] copy];
                }
                    break;
            }

            CGFloat x = indexRow * earthTile.size.width;
            CGFloat y = indexCol * earthTile.size.height;

            earthTile.anchorPoint = CGPointZero;
            earthTile.position = CGPointMake(x, y);
            earthTile.name = uniqueCellName;

            [earthLayer addChild:earthTile];
        }
    }
}

- (void)animateExplosionOnCellWithCol:(NSUInteger)col
                                  row:(NSUInteger)row
{
    BGLog();

    __weak typeof(self) weakSelf = self;

    NSUInteger cellIndex = col * kBGPrime + row;
    NSString *uniqueCellName = [NSString stringWithFormat:@"%lu",
                                                          (unsigned long) cellIndex];

    SKNode *compoundLayer = [self.scene childNodeWithName:@"compoundLayer"];
    SKNode *earthLayer = [compoundLayer childNodeWithName:@"earthLayer"];
    SKNode *grassLayer = [compoundLayer childNodeWithName:@"grassLayer"];

    SKSpriteNode *mineNode = (SKSpriteNode *) [earthLayer childNodeWithName:uniqueCellName];
    SKSpriteNode *grassNode = (SKSpriteNode *) [grassLayer childNodeWithName:uniqueCellName];

//    убираем тайл с травой с экрана
    SKAction *removeGrassNodeAction = [SKAction runBlock:^{
        [grassNode removeFromParent];
    }];

    //    анимация бомбы
    SKAction *tickAction = [SKAction animateWithTextures:_mineAnimationTextures
                                            timePerFrame:0.05];

    //   нода с анимацией взрыва
    SKSpriteNode *explosionNode = [SKSpriteNode spriteNodeWithTexture:_explosionAnimationTextures[0]];

    //    звук взрыва
    SKAction *playExplosionMusicAction = [SKAction runBlock:^
            {
                [[[NAGResourcePreloader shared]
                                        playerFromGameConfigForResource:@"explosion.wav"]
                                        play];
            }];

    //    ресайзим взрыв относительно размеров поля
    if ([[NAGSettingsManager shared]
                             integerValueForSettingsPath:@"game.settings.cols"] == 12)
        explosionNode.size = CGSizeMake(250, 250);
    else if ([[NAGSettingsManager shared]
                                  integerValueForSettingsPath:@"game.settings.cols"] == 15)
        explosionNode.size = CGSizeMake(200, 200);
    else
        explosionNode.size = CGSizeMake(150, 150);

    //     позиционируем взрыв
    CGPoint point = mineNode.position;
    explosionNode.position = CGPointMake(point.x + 13, point.y + 20);
    explosionNode.zPosition = 2;

    SKAction *explosionAction = [SKAction animateWithTextures:_explosionAnimationTextures
                                                 timePerFrame:0.025];
    [explosionNode runAction:[SKAction sequence:@[explosionAction,
                                                  [SKAction removeFromParent]]]];

    //    действие по добавлению ноды на сцену
    SKAction *explosionNodeAddedToScene = [SKAction runBlock:^
            {
                [earthLayer addChild:explosionNode];
            }];

    //    анимация открытия остальных бомб
    SKAction *openAllMines = [SKAction runBlock:^
            {
                [weakSelf openCellsWithBombs];
            }];

    //    скомпоновая анимация взрыва и исчезания мины
    SKAction *waitAction = [SKAction waitForDuration:0.70];
    SKAction *sequenceExplosionAction = [SKAction sequence:@[waitAction,
                                                             explosionNodeAddedToScene,
                                                             playExplosionMusicAction]];

    //    совместная анимация
    SKAction *compoundAction = [SKAction sequence:@[removeGrassNodeAction,
                                                    tickAction,
                                                    openAllMines]];
    [mineNode runAction:compoundAction];

    //    показываем пользователю проигрышный смайл
    SKAction *showSmile = [SKAction runBlock:^
            {
                [weakSelf showScoreIsAlive:NO];
            }];

    //    время ожидания до конца проигрывания анимации взрыва
    SKAction *waitForExplosionToEndAction = [SKAction waitForDuration:1.0];

    //    запускаем действия
    [earthLayer runAction:[SKAction sequence:@[sequenceExplosionAction,
                                               waitForExplosionToEndAction,
                                               showSmile]]];
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
    [usedCells addObject:@(col * kBGPrime + row)];

    while (queue.count > 0) {
        NSUInteger currentCol = [queue[0] unsignedIntegerValue];
        NSUInteger currentRow = [queue[1] unsignedIntegerValue];

        [queue removeObjectAtIndex:0];
        [queue removeObjectAtIndex:0];

        //        удаляем с верхнего слоя тайл с травой
        NSString *nodeName = [NSString stringWithFormat:@"%d",
                                                        (NSInteger) (currentCol * kBGPrime + currentRow)];
        SKNode *grassNodeToRemoveFromParent = [[[self
                .scene childNodeWithName:@"compoundLayer"]
                       childNodeWithName:@"grassLayer"]
                       childNodeWithName:nodeName];

        //        проверим, если на ячейке стоит флажок - не удаляем ячейку
        if ([grassNodeToRemoveFromParent childNodeWithName:@"flag"]) {
            continue;
        }

        //        удаляем из родительской ноды
        grassNodeToRemoveFromParent.userData = nil;
        [grassNodeToRemoveFromParent runAction:[SKAction removeFromParent]];

        //        нет смысла продолжать открывать клетки, если текущий тайл с цифрой
        NSInteger value = [self.field valueForCol:currentCol
                                              row:currentRow];

        if (value != BGFieldBomb && value != BGFieldEmpty) {
            continue;
        }

        for (NSUInteger k = 0; k < x.count; k++) {
            NSInteger newCol = currentCol + [y[k] integerValue];
            NSInteger newRow = currentRow + [x[k] integerValue];

            if (newCol >= 0 && newRow >= 0 && newCol < self.field
                    .cols && newRow < self.field.rows) {
                NSNumber *cellName = @(newCol * kBGPrime + newRow);

                //                добавляем еще неиспользованную клетку, если она пустая
                if ([self.field valueForCol:(NSUInteger) newCol
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
    BGLog();

    __weak NAGSKView *weakSelf = self;
    SKNode *compoundLayer = [self.scene childNodeWithName:@"compoundLayer"];
    SKNode *grassLayer = [compoundLayer childNodeWithName:@"grassLayer"];
    SKNode *earthLayer = [compoundLayer childNodeWithName:@"earthLayer"];
    SKTexture *checkedMineTexture = [SKTexture textureWithImageNamed:@"mine_defused"];

    [grassLayer enumerateChildNodesWithName:@"*"
                                 usingBlock:^(SKNode *node, BOOL *stop)
            {
                NSUInteger col = [node.userData[@"col"] unsignedIntegerValue];
                NSUInteger row = [node.userData[@"row"] unsignedIntegerValue];

                NSInteger value = [weakSelf.field valueForCol:col
                                                          row:row];

                if (BGFieldBomb == value) {
                    if (node.children.count != 0) {
//                                             мина отмечена флагом, заменим спрайт под травой
                        SKSpriteNode *earthNode = (SKSpriteNode *) [earthLayer childNodeWithName:node
                                .name];
                        earthNode.texture = checkedMineTexture;
                    }

                    [node removeFromParent];
                }
            }];
}

- (BOOL)isGameFinished
{
    BGLog();

    SKNode *grassTilesNode = [[self.scene childNodeWithName:@"compoundLayer"]
                                          childNodeWithName:@"grassLayer"];
    __block BOOL isGameFinished = YES;
    __weak typeof(self) weakSelf = self;

    [grassTilesNode enumerateChildNodesWithName:@"*"
                                     usingBlock:^(SKNode *node, BOOL *stop)
            {
                NSUInteger col = [node.userData[@"col"] unsignedIntegerValue];
                NSUInteger row = [node.userData[@"row"] unsignedIntegerValue];

                NSInteger value = [weakSelf.field valueForCol:col
                                                          row:row];

                // содержит под собой мину или нет
                if (node.userData == nil || value == BGFieldBomb) {
                } else {
                    *stop = YES;
                    isGameFinished = NO;
                }
            }];

    //    пользователь выиграл, показываем ему картину выигрышную
    if (isGameFinished) {
        [self showScoreIsAlive:YES];
    }

    return isGameFinished;
}

- (void)enableFieldInteraction
{
    SKNode *compoundLayer = [self.scene childNodeWithName:@"compoundLayer"];
    SKNode *grassLayer = [compoundLayer childNodeWithName:@"grassLayer"];

    grassLayer.userInteractionEnabled = YES;
}

- (void)disableFieldInteraction
{
    SKNode *compoundLayer = [self.scene childNodeWithName:@"compoundLayer"];
    SKNode *grassLayer = [compoundLayer childNodeWithName:@"grassLayer"];

    grassLayer.userInteractionEnabled = NO;
}

- (NSInteger)flaggedMines
{
    return _flaggedMines;
}

#pragma mark - Private

- (void)fillFieldWithGrassTiles
{
    BGLog();

    //    узел хранящий слой с травой
    SKNode *grassLayer = [[self.scene childNodeWithName:@"compoundLayer"]
                                      childNodeWithName:@"grassLayer"];

    //    нет смысла заполнять поле травой, если все тайлы на месте - игрок не начинал играть
    if (grassLayer.children.count == self.field.cols * self.field.rows) {
        return;
    }

    //    размеры поля берем из настроек
    NSUInteger colsFromSettings = self.field.cols;
    NSUInteger rowsFromSettings = self.field.rows;

    //    заполняем узел с именем grassLayer тайлами с травой
    @autoreleasepool {
        for (NSUInteger indexCol = 0; indexCol < colsFromSettings; indexCol++) {
            for (NSUInteger indexRow = 0; indexRow < rowsFromSettings; indexRow++) {
                NSString *uniqueCellName = [NSString stringWithFormat:@"%d",
                                                                      (NSInteger) (indexCol * kBGPrime + indexRow)];

                sranddev();
                NSInteger rndIndex = arc4random() % 2 + 1;
                NSString *tileName = [NSString stringWithFormat:@"grass%d",
                                                                rndIndex];

                SKSpriteNode *grassTile = [self.tileSprites[tileName] copy];
                CGFloat x = indexRow * (grassTile.size.width - 15);
                CGFloat y = indexCol * (grassTile.size.width - 15);

                NSArray *colors = @[
                        [SKColor colorWithHue:0.15
                                   saturation:1.0
                                   brightness:1.0
                                        alpha:1.0],
                        [SKColor colorWithRed:0.66
                                        green:0.87
                                         blue:0.12
                                        alpha:1.0]
                ];

                grassTile.color = colors[arc4random() % colors.count];
                grassTile.colorBlendFactor = arc4random() % 2;
                grassTile.anchorPoint = CGPointMake(0.1, 0.1);
                grassTile.position = CGPointMake(x, y);
                grassTile.name = uniqueCellName;
                grassTile.userData = [@{
                        @"col" : @(indexCol),
                        @"row" : @(indexRow)
                } mutableCopy];

                [grassLayer addChild:grassTile];
            }
        }
    }
}

- (void)createInitialLayers
{
    BGLog();

    //    создаем узел для хранения слоёв - травы и бомб/земли/смайлов
    SKNode *compoundLayer = [SKNode node];
    compoundLayer.name = @"compoundLayer";
    compoundLayer.userInteractionEnabled = YES;

    //    создаем слой для хранения тайлов с землей/бомбамы/цифрами
    SKNode *earthLayer = [SKNode node];
    earthLayer.name = @"earthLayer";
    earthLayer.userInteractionEnabled = NO;
    earthLayer.zPosition = 0;

    [compoundLayer addChild:earthLayer];

    //    создаем слой для хранения тайлов с травой
    SKNode *grassLayer = [SKNode node];
    grassLayer.name = @"grassLayer";
    grassLayer.userInteractionEnabled = YES;
    grassLayer.zPosition = 1;

    [compoundLayer addChild:grassLayer];

    //    создаем слой для хранения смайла победы/поражения
    SKNode *scoreLayer = [SKNode node];
    scoreLayer.name = @"scoreLayer";
    scoreLayer.userInteractionEnabled = YES;
    scoreLayer.zPosition = 2;

    [compoundLayer addChild:scoreLayer];

    //    добавляем дерево на сцену
    [self.scene addChild:compoundLayer];
}

- (void)adjustCompoundLayerScale
{
    BGLog();

    SKNode *compoundLayer = [self.scene childNodeWithName:@"compoundLayer"];
    SKNode *grassLayer = [compoundLayer childNodeWithName:@"grassLayer"];
    SKNode *earthLayer = [compoundLayer childNodeWithName:@"earthLayer"];

    //    регулируем скейл основного узла в зависимости от размера поля
    switch (self.field.cols) {
        case 12: {
            CGFloat scale = [self standardScaleForCols:12];
            [grassLayer setScale:scale];
            [earthLayer setScale:scale];
        }
            break;

        case 15: {
            CGFloat scale = [self standardScaleForCols:15];
            [grassLayer setScale:scale];
            [earthLayer setScale:scale];
        }
            break;

        default: {
            CGFloat scale = [self standardScaleForCols:24];
            [grassLayer setScale:scale];
            [earthLayer setScale:scale];
        }
            break;
    }
}

- (void)showScoreIsAlive:(BOOL)isAlive
{
    BGLog();

    SKNode *compoundLayer = [self.scene childNodeWithName:@"compoundLayer"];
    SKNode *scoreLayer = [compoundLayer childNodeWithName:@"scoreLayer"];

//    установим фоновую картинку
    SKSpriteNode *scoreTable = [SKSpriteNode spriteNodeWithImageNamed:@"score_table"];
    scoreTable
            .userInteractionEnabled = YES; // возможность по тапу удалить/убрать плашку - BGGameViewController/tap
    scoreTable.anchorPoint = CGPointZero;
    scoreTable.name = @"scoreTable";

    if ([UIScreen mainScreen].bounds.size.height == 480) // iPhone 4
        scoreTable.position = CGPointMake(0, -60);

//    добавим нужный смайл
    NSString *imageNamed = (isAlive ? @"goodjob" : @"failed");
    SKSpriteNode *smile = [SKSpriteNode spriteNodeWithImageNamed:imageNamed];
    smile.anchorPoint = CGPointZero;
    smile.position = CGPointMake(112.5, 270);

    [scoreTable addChild:smile];

//    добавим надпись "Очки"
    SKSpriteNode *scoreLabel = [SKSpriteNode spriteNodeWithImageNamed:@"score"];
    scoreLabel.anchorPoint = CGPointZero;
    scoreLabel.position = CGPointMake(122.5, 253);

    [scoreTable addChild:scoreLabel];

//    добавим сам счет
    UIColor *winColor = [UIColor colorWithRed:255
                                        green:198
                                         blue:0
                                        alpha:1];
    UIColor *loseColor = [UIColor redColor];

    NSInteger score = (isAlive ? [[BGGameViewController shared]
                                                        gameScore] : 0);

    SKLabelNode *scoreValueLabel = [SKLabelNode labelNodeWithFontNamed:@"Digital-7 Mono"];
    scoreValueLabel.fontSize = 27;
    scoreValueLabel.fontColor = (score ? winColor : loseColor);
    scoreValueLabel.text = [NSString stringWithFormat:@"%d", score];
    scoreValueLabel
            .horizontalAlignmentMode = SKLabelHorizontalAlignmentModeCenter;
    scoreValueLabel.position = CGPointMake(160, 222);

    [scoreTable addChild:scoreValueLabel];

//    добавим табло с очками на главный экран
    [scoreLayer addChild:scoreTable];
}

- (void)resetGameData
{
//    нет отмеченных бомб
    self.flaggedMines = 0;

//    удаляем предыдущие игровые слои
    SKNode *compoundLayer = [self.scene childNodeWithName:@"compoundLayer"];
    SKNode *grassLayer = [compoundLayer childNodeWithName:@"grassLayer"];
    SKNode *earthLayer = [compoundLayer childNodeWithName:@"earthLayer"];
    SKNode *scoreLayer = [compoundLayer childNodeWithName:@"scoreLayer"];

    [grassLayer removeAllActions];
    [grassLayer removeAllChildren];
    [earthLayer removeAllActions];
    [earthLayer removeAllChildren];
    [scoreLayer removeAllChildren];

//    сбрасываем масштабирование и положение
    CGFloat defaultScale = [self standardScaleForCols:self.field.cols];

    [grassLayer setScale:defaultScale];
    grassLayer.position = CGPointMake(0, 0);

    [earthLayer setScale:defaultScale];
    earthLayer.position = CGPointMake(0, 0);
}

- (CGFloat)standardScaleForCols:(NSUInteger)cols
{
    CGFloat scale;

    //    регулируем скейл основного узла в зависимости от размера поля
    switch (cols) {
        case 12:
            scale = 1.0;
            break;

        case 15:
            scale = 0.8;
            break;

        default:
            scale = 0.5;
            break;
    }

    return scale;
}

- (NSUInteger)randomNumberOfBombsForRows:(NSUInteger)rows
                                    cols:(NSUInteger)cols
                                   level:(NSUInteger)level
{
    sranddev();

    NSUInteger minBombs = (rows < cols) ? rows : cols;
    NSUInteger maxBombs = 2ul * minBombs;
    NSUInteger bombs = arc4random() % (maxBombs - minBombs + 1) + level * minBombs;

    return bombs;
}

@end
