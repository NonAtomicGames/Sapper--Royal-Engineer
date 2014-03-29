//
//  BGLeaderboardViewController.m
//  Miner
//
//  Created by AndrewShmig on 3/15/14.
//  Copyright (c) 2014 Bleeding Games. All rights reserved.
//

#import "BGLeaderboardViewController.h"
#import "BGLeaderboardManager.h"


#define BG_NUMBER_OF_SECTIONS 1


@interface BGLeaderboardViewController ()
@end


@implementation BGLeaderboardViewController

#pragma mark - View

- (void)viewDidLoad
{
    NSLog(@"%s", __FUNCTION__);

    [[BGLeaderboardManager sharedManager] removeAll];

    for (NSUInteger i=0; i<10; i++) {
        [[BGLeaderboardManager sharedManager]
                addNewRecordForRows:i
                               cols:i
                              level:i*2
                               time:i*3];
    }
}

#pragma mark - UITableViewDelegate

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"%s", __FUNCTION__);

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RecordCellIdentifier"];

    if(cell == nil) {
        cell = [[UITableViewCell alloc]
                initWithStyle:UITableViewCellStyleValue1
              reuseIdentifier:@"RecordCellIdentifier"];
    }

    cell.textLabel.text = [NSString stringWithFormat:@"%@", [BGLeaderboardManager sharedManager].records[(NSUInteger)indexPath.row][@"level"]];

    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    NSLog(@"%s", __FUNCTION__);

    return [BGLeaderboardManager sharedManager].records.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSLog(@"%s", __FUNCTION__);

    return BG_NUMBER_OF_SECTIONS;
}

#pragma mark - IBActions

- (IBAction)back:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
