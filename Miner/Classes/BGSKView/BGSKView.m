//
//  BGSKView.m
//  Miner
//
//  Created by AndrewShmig on 4/12/14.
//  Copyright (c) 2014 Russian Bleeding Games. All rights reserved.
//

#import "BGSKView.h"
#import "BGLog.h"
#import "BGSettingsManager.h"
#import "BGMinerField.h"
#import "BGResourcePreloader.h"


// константа для "кодирования" координаты в одно значение
static const NSInteger kBGPrime = 1001;


// сцена для отображения игрового поля
@interface BGSKScene : SKScene
@end

@implementation BGSKScene
@end


@interface BGSKView ()
@property NSMutableArray *mineAnimationTextures;
@property NSMutableArray *grassAnimationTextures;
@property NSMutableArray *explosionAnimationTextures;
@end


@implementation BGSKView

#pragma mark - Init

- (id)initWithFrame:(CGRect)frame
{
    BGLog();

    self = [super initWithFrame:frame];

    if (self) {
        __weak typeof (self) weakSelf = self;

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
                                                               initWithSize:weakSelf.frame.size];
                            gameScene.userInteractionEnabled = YES;
                            [weakSelf presentScene:gameScene];

                            //    создаем основные узлы для хранения слоёв - травы, земли
                            [weakSelf createInitialLayers];

                            //                            создаем сильные ссылки на текстуры (земля, цифры, трава)
                            for (NSString *textureFullName in weakSelf.tileAtlas.textureNames) {
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
                                                                                 animationFrame];
                                SKTexture *texture = [weakSelf
                                        .mineAnimationAtlas textureNamed:frameName];
                                [weakSelf.mineAnimationTextures addObject:texture];
                            }

                            //                            добавляем текстуры анимации травы
                            for (NSUInteger animationFrame = 0; animationFrame < weakSelf
                                    .grassAnimationAtlas.textureNames
                                    .count; animationFrame++) {
                                NSString *frameName = [NSString stringWithFormat:@"Grass_animation%04d@2x.png",
                                                                                 animationFrame];
                                SKTexture *texture = [weakSelf
                                        .grassAnimationAtlas textureNamed:frameName];
                                [weakSelf.grassAnimationTextures addObject:texture];
                            }

                            //                            добавляем текстуры анимации взрыва
                            for (NSUInteger animationFrame = 0; animationFrame < weakSelf
                                    .explosionAnimationAtlas.textureNames
                                    .count; animationFrame++) {
                                NSString *frameName = [NSString stringWithFormat:@"explosion_%05d@2x.png",
                                                                                 animationFrame + 60];

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
    _field = [[BGMinerField alloc]
                            initWithCols:[BGSettingsManager sharedManager].cols
                                    rows:[BGSettingsManager sharedManager].rows
                                   bombs:[BGSettingsManager sharedManager]
                                           .bombs];

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
                                                                  indexCol * kBGPrime + indexRow];
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
                    NSString *earthTileName = [NSString stringWithFormat:@"earth%d",
                                                                         fieldValue];
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

    __weak typeof (self) weakSelf = self;

    NSUInteger cellIndex = col * kBGPrime + row;
    NSString *uniqueCellName = [NSString stringWithFormat:@"%d", cellIndex];

    SKNode *compoundLayer = [self.scene childNodeWithName:@"compoundLayer"];
    SKNode *earthLayer = [compoundLayer childNodeWithName:@"earthLayer"];
    SKNode *grassLayer = [compoundLayer childNodeWithName:@"grassLayer"];

    SKSpriteNode *mineNode = (SKSpriteNode *) [earthLayer childNodeWithName:uniqueCellName];
    SKSpriteNode *grassNode = (SKSpriteNode *) [grassLayer childNodeWithName:uniqueCellName];

    //    анимация раскапывания
    SKAction *digAction = [SKAction runBlock:^
    {
        SKAction *grassDigAction = [SKAction animateWithTextures:weakSelf
                .grassAnimationTextures
                                                    timePerFrame:0.05];
        [grassNode runAction:grassDigAction];
    }];

    //    анимация бомбы
    SKAction *tickAction = [SKAction animateWithTextures:_mineAnimationTextures
                                            timePerFrame:0.05];

    //   нода с анимацией взрыва
    SKSpriteNode *explosionNode = [SKSpriteNode spriteNodeWithTexture:_explosionAnimationTextures[0]];

    //    звук взрыва
    SKAction *playExplosionMusicAction = [SKAction runBlock:^
    {
        [[[BGResourcePreloader shared]
                               playerFromGameConfigForResource:@"explosion.wav"]
                               play];
    }];

    //    ресайзим взрыв относительно размеров поля
    if ([BGSettingsManager sharedManager].cols == 12)
        explosionNode.size = CGSizeMake(250, 250);
    else if ([BGSettingsManager sharedManager].cols == 15)
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
    SKAction *waitAction = [SKAction waitForDuration:0.85];
    SKAction *sequenceExplosionAction = [SKAction sequence:@[waitAction,
                                                             explosionNodeAddedToScene,
                                                             playExplosionMusicAction]];

    //    совместная анимация
    SKAction *compoundAction = [SKAction sequence:@[digAction,
                                                    tickAction,
                                                    openAllMines]];
    [mineNode runAction:compoundAction];

    //    показываем пользователю проигрышный смайл
    SKAction *showSmile = [SKAction runBlock:^
    {
        [weakSelf showFinalSmileIsAlive:NO];
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

    //    анимация "откапывания"
    SKAction *removeFromParent = [SKAction removeFromParent];
    SKAction *digAnimation = [SKAction animateWithTextures:_grassAnimationTextures
                                              timePerFrame:0.05];
    SKAction *compoundDigAnimation = [SKAction sequence:@[digAnimation,
                                                          removeFromParent]];

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
                                                        currentCol * kBGPrime + currentRow];
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
        [grassNodeToRemoveFromParent runAction:compoundDigAnimation];

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

    __weak BGSKView *weakSelf = self;
    SKNode *compoundLayer = [self.scene childNodeWithName:@"compoundLayer"];
    SKNode *grassLayer = [compoundLayer childNodeWithName:@"grassLayer"];
    SKNode *earthLayer = [compoundLayer childNodeWithName:@"earthLayer"];
    SKTexture *checkedMineTexture = [SKTexture textureWithImageNamed:@"checked_bomb"];

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
                                             SKSpriteNode *earthNode = (SKSpriteNode *) [earthLayer childNodeWithName:node.name];
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
    __weak typeof (self) weakSelf = self;

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
        [self showFinalSmileIsAlive:YES];
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
                                                                      indexCol * kBGPrime + indexRow];
                SKSpriteNode *grassTile = [self.tileSprites[@"grass"] copy];
                CGFloat x = indexRow * grassTile.size.width;
                CGFloat y = indexCol * grassTile.size.height;

                grassTile.anchorPoint = CGPointZero;
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

    //    создаем слой "камера"
    SKNode *cameraLayer = [SKNode node];
    cameraLayer.name = @"cameraLayer";
    cameraLayer.userInteractionEnabled = YES;
    cameraLayer.zPosition = 2;

    [compoundLayer addChild:cameraLayer];

    //    создаем слой для хранения смайла победы/поражения
    SKNode *smileLayer = [SKNode node];
    smileLayer.name = @"winFailLayer";
    smileLayer.userInteractionEnabled = YES;
    smileLayer.zPosition = 3;

    [compoundLayer addChild:smileLayer];

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
        case 12:
            [grassLayer setScale:[self standardScaleForCols:12]];
            [earthLayer setScale:[self standardScaleForCols:12]];
            break;

        case 15:
            [grassLayer setScale:[self standardScaleForCols:15]];
            [earthLayer setScale:[self standardScaleForCols:15]];
            break;

        default:
            [grassLayer setScale:[self standardScaleForCols:24]];
            [earthLayer setScale:[self standardScaleForCols:24]];
            break;
    }
}

- (void)showFinalSmileIsAlive:(BOOL)isAlive
{
    BGLog();

    if (![self needToShowSmileIsAlive:isAlive])
        return;

    SKNode *compoundLayer = [self.scene childNodeWithName:@"compoundLayer"];
    SKNode *winFailLayer = [compoundLayer childNodeWithName:@"winFailLayer"];

    SKSpriteNode *winningSpriteNode;

    if (isAlive)
        winningSpriteNode = [SKSpriteNode spriteNodeWithImageNamed:@"goodjob"];
    else
        winningSpriteNode = [SKSpriteNode spriteNodeWithImageNamed:@"failed"];

    winningSpriteNode.anchorPoint = CGPointZero;
    winningSpriteNode.name = @"smile";

    [winFailLayer addChild:winningSpriteNode];
}

- (BOOL)needToShowSmileIsAlive:(BOOL)isAlive
{
    BGLog();

    static NSUInteger failedAttempts = 0;

    if (isAlive) {
        failedAttempts = 0;

        return YES;
    }

    failedAttempts++;

    //    если пользователь проиграл два раза подряд, то после, смайл поражения не
    //    будет отображаться
    if (failedAttempts < 3)
        return YES;
    else
        return NO;
}

- (void)resetGameData
{
//    нет отмеченных бомб
    self.flaggedMines = 0;

//    удаляем предыдущие игровые слои
    SKNode *compoundLayer = [self.scene childNodeWithName:@"compoundLayer"];
    SKNode *grassLayer = [compoundLayer childNodeWithName:@"grassLayer"];
    SKNode *earthLayer = [compoundLayer childNodeWithName:@"earthLayer"];
    SKNode *winFailLayer = [compoundLayer childNodeWithName:@"winFailLayer"];

    [grassLayer removeAllActions];
    [grassLayer removeAllChildren];
    [earthLayer removeAllActions];
    [earthLayer removeAllChildren];
    [winFailLayer removeAllChildren];

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

@end
