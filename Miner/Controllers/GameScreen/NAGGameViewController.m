//
//  NAGGameViewController.m
//  Miner
//
//  Created by AndrewShmig on 3/15/14.
//  Copyright (c) 2014 Bleeding Games. All rights reserved.
//

#import "NAGGameViewController.h"
#import "NAGSKView.h"


// полезные константы тегов для вьюх
static const NSInteger kBGTimerViewTag = 1;
static const NSInteger kBGMinesCountViewTag = 2;


// основная реализация
@implementation NAGGameViewController

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

@end
