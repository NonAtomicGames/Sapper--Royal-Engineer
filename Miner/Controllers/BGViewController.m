//
//  BGViewController.m
//  Miner
//
//  Created by AndrewShmig on 3/15/14.
//  Copyright (c) 2014 Bleeding Games. All rights reserved.
//

#import "BGViewController.h"


@interface BGViewController ()
@end


@implementation BGViewController

#pragma mark - iAd Delegate

- (void)bannerViewWillLoadAd:(ADBannerView *)banner
{
    NSLog(@"%s", __FUNCTION__);
//    TODO    
}

- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    NSLog(@"%s", __FUNCTION__);
    self.adBannerView.hidden = NO;
}

- (void)bannerViewActionDidFinish:(ADBannerView *)banner
{
    NSLog(@"%s", __FUNCTION__);
//    TODO
}

- (void)bannerView:(ADBannerView *)banner
didFailToReceiveAdWithError:(NSError *)error
{
    NSLog(@"%s", __FUNCTION__);
    NSLog(@"Error: %@", error);
    
    self.adBannerView.hidden = YES;
}

- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner
               willLeaveApplication:(BOOL)willLeave
{
    NSLog(@"%s", __FUNCTION__);
    
    return YES;
}

@end
