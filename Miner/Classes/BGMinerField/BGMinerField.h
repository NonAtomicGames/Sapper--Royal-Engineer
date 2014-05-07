//
//  BGMinerField.h
//  Miner
//
//  Created by AndrewShmig on 3/15/14.
//  Copyright (c) 2014 Bleeding Games. All rights reserved.
//

typedef NS_ENUM(NSInteger, BGMinerFieldValue){
    BGFieldBomb = -1,
    BGFieldEmpty = 0
};


@interface BGMinerField : NSObject

@property (nonatomic, readonly) NSUInteger rows;
@property (nonatomic, readonly) NSUInteger cols;
@property (nonatomic, readonly) NSUInteger bombs;

/** Создаем поле размером rows на cols и заполняем его бомбами в кол-ве bombs штук.
Само поле не заполняется, а создаётся каркас.
Заполнение будет отложеным, потому что пользователь не должен наткнуться на мину
с первого же нажатия.
*/
- (instancetype)initWithCols:(NSUInteger)cols
                        rows:(NSUInteger)rows
                       bombs:(NSUInteger)bombs;

// генерирует "содержимое поля" исключая из возможных клеток для мин, клетку
// с координатами col и row.
- (void)generateFieldWithExcludedCellInCol:(NSUInteger)col
                                       row:(NSUInteger)row;

/** получаем значение, которое находится в ячейке row,col
*/
- (NSInteger)valueForCol:(NSUInteger)col
                     row:(NSUInteger)row;

@end
