//
//  FZZGuestListTableViewCell.h
//  Fizz
//
//  Created by Andrew Sweet on 8/14/14.
//  Copyright (c) 2014 Fizz. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FZZGuestListTableViewCell : UITableViewCell

@property (strong, nonatomic) UILabel *label;

- (void)setIsGoing:(BOOL)isGoing;

@end
