//
//  FZZExpandedVerticalTableViewController.h
//  Fizz
//
//  Created by Andrew Sweet on 5/25/14.
//  Copyright (c) 2014 Fizz. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FZZEvent;

@interface FZZExpandedVerticalTableViewController : UITableViewController

@property (strong, nonatomic) FZZEvent *event;

- (UIView *)topCell;
- (UIView *)middleCell;
- (UIView *)bottomCell;

- (void)updateTopView:(UIView *)view;
- (void)updateMiddleView:(UIView *)view;
- (void)updateBottomView:(UIView *)view;

@end