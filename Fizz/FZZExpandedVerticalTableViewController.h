//
//  FZZExpandedVerticalTableViewController.h
//  Fizz
//
//  Created by Andrew Sweet on 5/25/14.
//  Copyright (c) 2014 Fizz. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FZZScrollDetector;
@class FZZEvent;

@interface FZZExpandedVerticalTableViewController : UITableViewController <UIActionSheetDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) FZZEvent *event;
@property (strong, nonatomic) FZZScrollDetector *scrollDetector;

+ (void)setScrollEnabled:(BOOL)canScroll;

- (void)tableViewWillAppear;
- (void)updateVisuals;

- (void)updateMessages;
- (void)setEventIndexPath:(NSIndexPath *)indexPath;

- (float)getBackgroundAlpha;

- (FZZEvent *)getFZZEvent;

- (CGFloat)descriptionCellOffset;
- (CGFloat)descriptionCellHeight;

+ (NSIndexPath *)descriptionCellIndexPath;

- (UITableViewCell *)getCurrentCell;
- (UIScrollView *)getCurrentScrollView;

- (CGFloat)tableView:(UITableView *)tableView offsetForRowAtIndexPath:(NSIndexPath *)indexPath;

- (void)reloadChat;

+ (CGFloat)descriptionScreenScrollPosition;

+ (CGFloat)offsetForRowAtIndexPath:(NSIndexPath *)indexPath;

@end
