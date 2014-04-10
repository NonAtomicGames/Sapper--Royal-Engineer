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


BGMinerField *_field;


#pragma mark - BGGameScene

// дочерний класс для обработки цикла обновления игрового поля
@interface BGGameScene : SKScene
@end

@implementation BGGameScene

- (void)update:(NSTimeInterval)currentTime
{
//    BGLog(@"%s", __FUNCTION__);
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    BGLog(@"%s", __FUNCTION__);

//    получаем координаты нажатия
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInNode:self];

//    получаем ноду, которая находится в точке нажатия
    SKNode *touchedNode = [self nodeAtPoint:touchPoint];

//    смотрим, что находится под нодой
    if (touchedNode.userData != nil) {
        [touchedNode removeFromParent];

//        проверим значение, которое на поле
        NSUInteger col = [touchedNode.userData[@"col"] unsignedIntegerValue];
        NSUInteger row = [touchedNode.userData[@"row"] unsignedIntegerValue];
        NSInteger value = [_field valueForCol:col
                                          row:row];

        switch (value) {
            case BGFieldBomb:
                [self animateExplosionOnCellWithCol:col
                                                row:row];
                [self openCellsWithBombs];

                break;

            case BGFieldEmpty:
                [self openCellsFromCellWithCol:col
                                           row:row];

                break;

            default:
//                ничего не делаем
                break;
        }
    }
}

- (void)animateExplosionOnCellWithCol:(NSUInteger)col
                                  row:(NSUInteger)row
{
    BGLog(@"%s", __FUNCTION__);

//    TODO
}

- (void)openCellsFromCellWithCol:(NSUInteger)col
                             row:(NSUInteger)row
{
    BGLog(@"%s", __FUNCTION__);

//    определяем все ячейки, которые необходимо открыть
    NSMutableSet *usedCells = [NSMutableSet new];
    NSMutableArray *queue = [NSMutableArray new];
    NSArray *x = @[@0, @1, @0, @(-1)];
    NSArray *y = @[@(-1), @0, @1, @0];

    [queue addObject:@(col)];
    [queue addObject:@(row)];
    [usedCells addObject:[NSString stringWithFormat:@"%@.%@", @(col), @(row)]];

    while (queue.count > 0) {
        NSUInteger currentCol = [queue[0] unsignedIntegerValue];
        NSUInteger currentRow = [queue[1] unsignedIntegerValue];

        [queue removeObjectAtIndex:0];
        [queue removeObjectAtIndex:0];

//        удаляем с верхнего слоя тайл с травой
        NSString *nodeName = [NSString stringWithFormat:@"%@.%@",
                                                        @(currentCol),
                                                        @(currentRow)];
        SKNode *grassNodeToRemoveFromParent = [[self childNodeWithName:@"grassTiles"]
                                                     childNodeWithName:nodeName];
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
                NSString *cellName = [NSString stringWithFormat:@"%@.%@",
                                                                @(newCol),
                                                                @(newRow)];

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

@end


#pragma mark - BGGameViewController

// приватные методы
@interface BGGameViewController (Private)
- (void)fillGameSceneField;

- (void)startGameTimer;
@end


// основная реализация
@implementation BGGameViewController

#pragma mark - Views delegate methods

- (void)viewDidLoad
{
    BGLog(@"%s", __FUNCTION__);

//    добавляем изображение верхней панели
    UIImage *topPanelImage = [UIImage imageNamed:@"top_game"];
    UIImageView *topPanelImageView = [[UIImageView alloc]
                                                   initWithImage:topPanelImage];
    topPanelImageView.frame = CGRectMake(0, 0, topPanelImage.size.width, topPanelImage.size.height);

    [self.view addSubview:topPanelImageView];

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

    NSUInteger rows = [BGSettingsManager sharedManager].rows;
    NSUInteger cols = [BGSettingsManager sharedManager].cols;
    NSUInteger bombs = [BGSettingsManager sharedManager].bombs;

    _field = [[BGMinerField alloc] initWithCols:cols
                                           rows:rows
                                          bombs:bombs];

//    добавляем сцену на SKView
    BGGameScene *scene = [[BGGameScene alloc]
                                       initWithSize:self.skView.bounds.size];
    [self.skView presentScene:scene];

#ifdef DEBUG
    self.skView.showsDrawCount = YES;
    self.skView.showsFPS = YES;
    self.skView.showsNodeCount = YES;
    self.skView.showsPhysics = YES;
#endif

//    заполняем SKView спрайтами с бомбами, цифрами и пустыми полями
//    потом накладываем на них траву
    [self fillGameSceneField];
}

- (void)viewDidAppear:(BOOL)animated
{
    BGLog(@"%s", __FUNCTION__);

//    запускаем таймер игры
    [self startGameTimer];
}

#pragma mark - IBActions

- (IBAction)back:(id)sender
{
    BGLog(@"%s", __FUNCTION__);

    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Private methods

- (void)fillGameSceneField
{
//    нода для хранения первого слоя
    SKNode *layer1 = [SKNode node];
    layer1.zPosition = 0;
    layer1.userInteractionEnabled = NO;

//    нода для хранения второго слоя
    SKNode *layer2 = [SKNode node];
    layer2.zPosition = 1;
    layer2.name = @"grassTiles";

//    заполняем первый слой - цифры, земля и сами бомбы
    for (NSUInteger indexCol = 0; indexCol < _field.cols; indexCol++) {
        for (NSUInteger indexRow = 0; indexRow < _field.rows; indexRow++) {
            NSInteger fieldValue = [_field valueForCol:indexCol
                                                   row:indexRow];
            SKSpriteNode *tile;

            switch (fieldValue) {
                case BGFieldBomb: // бомба
                    tile = [SKSpriteNode spriteNodeWithImageNamed:@"mine"];
                    break;

                case BGFieldEmpty: // земля
                    tile = [SKSpriteNode spriteNodeWithImageNamed:@"earth"];
                    break;

                default:
                    tile = [SKSpriteNode spriteNodeWithImageNamed:[NSString stringWithFormat:@"earth%d",
                                                                                             fieldValue]];
                    break;
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

//            добавляем на слой
            [layer1 addChild:tile];

//            накладываем слой с травой
            SKSpriteNode *grassTile = [SKSpriteNode spriteNodeWithImageNamed:@"grass"];
            grassTile.position = tile.position;
            grassTile.size = tile.size;
            grassTile.anchorPoint = CGPointZero;
            grassTile.userData = [@{
                    @"col" : @(indexCol),
                    @"row" : @(indexRow)
            } mutableCopy];
            grassTile.name = [NSString stringWithFormat:@"%@.%@",
                                                        @(indexCol),
                                                        @(indexRow)];

            [layer2 addChild:grassTile];
        }
    }

//    добавляем на поле первый слой
    [self.skView.scene addChild:layer1];

//    накладываем второй слой
    [self.skView.scene addChild:layer2];
}

- (void)startGameTimer
{
//    TODO
}

@end
