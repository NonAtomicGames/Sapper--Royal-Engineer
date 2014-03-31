//
//  BGViewController.h
//  Miner
//
//  Created by AndrewShmig on 3/15/14.
//  Copyright (c) 2014 Bleeding Games. All rights reserved.
//

@import UIKit;
@import SpriteKit;
@import iAd;

@interface BGViewController : UIViewController <ADBannerViewDelegate>

@property (nonatomic, weak) IBOutlet ADBannerView *adBannerView;

@end
