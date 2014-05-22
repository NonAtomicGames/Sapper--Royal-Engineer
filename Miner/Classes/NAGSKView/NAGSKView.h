//
//  NAGSKView.h
//  Miner
//
//  Created by AndrewShmig on 4/12/14.
//  Copyright (c) 2014 Russian Bleeding Games. All rights reserved.
//

@import SpriteKit;


@class NAGMinerField;


@interface NAGSKView : SKView

// атлас с текстурами для поля
@property (nonatomic, strong, readonly) SKTextureAtlas *tileAtlas;
@property (nonatomic, strong, readonly) SKTextureAtlas *grassAnimationAtlas;
@property (nonatomic, strong, readonly) SKTextureAtlas *mineAnimationAtlas;
@property (nonatomic, strong, readonly) SKTextureAtlas *explosionAnimationAtlas;

// словарь с сильными ссылками на все экземпляры спрайтов
@property (nonatomic, strong, readonly) NSMutableDictionary *tileSprites;
// игровое поле
@property (nonatomic, strong, readonly) NAGMinerField *field;
// кол-во отмеченых мин
@property (nonatomic, assign, readwrite) NSInteger flaggedMines;

// метод осуществляет подготовку поля к началу игры - генерирование поля,
// очистка от предыдущей игры, изменение масштабов спрайтов
- (void)startNewGame;

// непосредственное заполнение поля с минами и цифрами
// исключает из возможных расположений мин клетку в cellCol и cellRow
- (void)fillEarthWithTilesExcludingBombAtCellWithCol:(NSUInteger)cellCol
                                                 row:(NSUInteger)cellRow;

// блокирует возможноть пользователю работать с игровым полем (конкретнее -
// слоем с землей и травой)
- (void)disableFieldInteraction;

// включает возможность пользователю работать с игровым полем (конкретнее -
// слоем с землей и травой)
- (void)enableFieldInteraction;

// анимирует взрыв бомбы в ячейке col:row
- (void)animateExplosionOnCellWithCol:(NSUInteger)col
                                  row:(NSUInteger)row;

// открывает все ячейки с бомбами
- (void)openCellsWithBombs;

// "волновой алгоритм" для открытия связаных ячеек
- (void)openCellsFromCellWithCol:(NSUInteger)col
                             row:(NSUInteger)row;

// проверка статуса игры - выиграл ли пользователь или проиграл
- (BOOL)isGameFinished;

// возвращает стандартный (минимальный) скейл для игрового поля при кол-ве строк cols
- (CGFloat)standardScaleForCols:(NSUInteger)cols;

@end
