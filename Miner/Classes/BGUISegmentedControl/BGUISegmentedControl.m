//
// Copyright (C) 4/6/14  Andrew Shmig ( andrewshmig@yandex.ru )
// Russian Bleeding Games. All rights reserved.
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License along
// with this program; if not, write to the Free Software Foundation, Inc.,
// 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//

#import "BGUISegmentedControl.h"


#define METAL_BORDER_WIDTH 4.5


@implementation BGUISegmentedControl
{
    NSMutableArray *_selectedSegments;
    SEL _action;
    __weak id _target;
}

#pragma mark - Init

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self) {
        _selectedSegments = [NSMutableArray new];
    }

    return self;
}

#pragma mark - Setters & getters

- (void)setBackgroundImage:(UIImage *)backgroundImage
{
    UIImageView *background = [[UIImageView alloc]
                                            initWithImage:backgroundImage];
    CGRect frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
    background.frame = frame;

    [self addSubview:background];
}

- (void)addNewSegmentImage:(UIImage *)segmentImage
{
    NSLog(@"%s", __FUNCTION__);

    [self BGPrivate_addNewSegmentImage:segmentImage];
}

- (void)setSelectedSegmentIndex:(NSUInteger)selectedSegmentIndex
{
    NSLog(@"%s", __FUNCTION__);

    _selectedSegmentIndex = selectedSegmentIndex;

    for (NSUInteger i = 0; i < [_selectedSegments count]; i++) {
        UIImageView *segment = _selectedSegments[i];

        if (i != selectedSegmentIndex) {
            segment.hidden = YES;
        } else {
            segment.hidden = NO;
        }
    }
}

- (void)addTarget:(id)target action:(SEL)action
{
    _target = target;
    _action = action;
}

#pragma mark - Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self updateSegmentedControlUsingTouches:touches];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self updateSegmentedControlUsingTouches:touches];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self updateSegmentedControlUsingTouches:touches];
}

#pragma mark - Private method

- (void)updateSegmentedControlUsingTouches:(NSSet *)touches
{
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self];

    for (NSUInteger i = 0; i < _selectedSegments.count; i++) {
        CGRect rect = ((UIImageView *) _selectedSegments[i]).frame;

        if (CGRectContainsPoint(rect, touchPoint)) {
            self.selectedSegmentIndex = i;
            break;
        }
    }

    [_target performSelector:_action
                  withObject:@(_selectedSegmentIndex)];
}

- (void)BGPrivate_addNewSegmentImage:(UIImage *)image
{
    NSLog(@"%s", __FUNCTION__);

    UIImageView *segment = [[UIImageView alloc] initWithImage:image];

    CGFloat x = METAL_BORDER_WIDTH + _selectedSegments.count * (image.size.width / 2);
    CGFloat y = METAL_BORDER_WIDTH;

    segment.frame = CGRectMake(x, y, image.size.width / 2, image.size.height / 2);
    segment.hidden = YES;

    [_selectedSegments addObject:segment];

    [self addSubview:segment];
}

@end