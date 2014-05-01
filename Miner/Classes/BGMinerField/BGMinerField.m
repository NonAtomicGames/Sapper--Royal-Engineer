//
//  BGMinerField.m
//  Miner
//
//  Created by AndrewShmig on 3/15/14.
//  Copyright (c) 2014 Bleeding Games. All rights reserved.
//

#import "BGMinerField.h"
#import "BGLog.h"


// константа для "кодирования" координаты в одно значение
static const NSInteger kBGPrime = 1001;


@implementation BGMinerField
{
    NSMutableArray *_field;
    NSArray *_x, *_y;
}

#pragma mark - Init

- (instancetype)initWithCols:(NSUInteger)cols
                        rows:(NSUInteger)rows
                       bombs:(NSUInteger)bombs
{
    self = [super init];

    if (self) {
//        свойства
        _rows = rows;
        _cols = cols;
        _bombs = bombs;
    }

    return self;
}

- (NSInteger)valueForCol:(NSUInteger)col
                     row:(NSUInteger)row
{
    return [_field[col][row] integerValue];
}

- (void)generateFieldWithExcludedCellInCol:(NSUInteger)cellCol
                                       row:(NSUInteger)cellRow
{
    BGLog();

    //        множество клеток
    NSMutableArray *cells = [NSMutableArray new];

//        заполняем поле пустыми значениями
    _field = [NSMutableArray new];

    for (NSUInteger i = 0; i < self.cols; i++) {
        [_field addObject:[NSMutableArray new]];

        for (NSUInteger j = 0; j < self.rows; j++) {
            [_field[i] addObject:@(BGFieldEmpty)];

//                добавляем ячейку в множество, если она не "запрещена"
            if (!(i == cellCol && j == cellRow))
                [cells addObject:@(i * kBGPrime + j)];
        }
    }

//        произвольно располагаем бомбы на поле
    sranddev();

    for (NSUInteger i = 0; i < self.bombs; i++) {
        NSUInteger index = arc4random() % [cells count];

        NSUInteger randomCell = [cells[index] unsignedIntegerValue];
        NSUInteger col = randomCell / kBGPrime;
        NSUInteger row = randomCell % kBGPrime;

        _field[col][row] = @(BGFieldBomb);

//            удаляем использованную клетку
        [cells removeObjectAtIndex:index];
    }

//        расставляем цифры
    _x = @[@0, @1, @1, @1, @0, @(-1), @(-1), @(-1)];
    _y = @[@(-1), @(-1), @0, @1, @1, @1, @0, @(-1)];

    for (NSUInteger i = 0; i < self.cols; i++) {
        for (NSUInteger j = 0; j < self.rows; j++) {
            NSInteger cellValue = [_field[i][j] integerValue];
            NSInteger count = 0;

            if (cellValue == BGFieldEmpty) {
                for (NSUInteger k = 0; k < _x.count; k++) {
                    NSInteger newY = i + [_x[k] integerValue];
                    NSInteger newX = j + [_y[k] integerValue];

                    if (newX >= 0 && newY >= 0 && newX < self
                            .rows && newY < self.cols) {
                        if ([_field[(NSUInteger) newY][(NSUInteger) newX] integerValue] == BGFieldBomb) {
                            count++;
                        }
                    }
                }

                _field[i][j] = @(count);
            }
        }
    }
}

@end
