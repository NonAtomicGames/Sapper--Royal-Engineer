//
//  BGOptionsViewController.h
//  Miner
//
//  Created by AndrewShmig on 3/15/14.
//  Copyright (c) 2014 Bleeding Games. All rights reserved.
//

@import UIKit;


@interface BGOptionsViewController : UIViewController

@property (nonatomic, weak) IBOutlet UIButton *backButton;
@property (nonatomic, weak) IBOutlet UISwitch *soundSwitch;
@property (nonatomic, weak) IBOutlet UISwitch *adsSwitch;
@property (nonatomic, weak) IBOutlet UISegmentedControl *levelSegmentedControl;
@property (nonatomic, weak) IBOutlet UISegmentedControl *fieldSizeSegmentedControl;

- (IBAction)back:(id)sender; // go to main screen
- (IBAction)adsStatusChanged;
- (IBAction)soundStatusChanged;
- (IBAction)levelChanged;
- (IBAction)fieldSizeChanged;

@end