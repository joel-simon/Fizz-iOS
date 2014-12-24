//
//  FZZUserMessageCell.m
//  Fizz
//
//  Created by Andrew Sweet on 3/9/14.
//  Copyright (c) 2014 Fizz. All rights reserved.
//

#import "FZZUserMessageCell.h"
#import "FZZUser.h"
#import "FZZMessage.h"

#import "FZZUtilities.h"

static UIFont *userCellMessageFont;
static UIFont *userCellNameFont;
static float messageLabelWidth;

@implementation FZZUserMessageCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        static dispatch_once_t once;
        dispatch_once(&once, ^{
            [[self messageLabel] setFont:kFZZLabelsFont()];
//            userCellMessageFont = [[self messageLabel] font];
            userCellNameFont = [[self userLabel] font];
            messageLabelWidth = [[self messageLabel] frame].size.width;
        });
    }
    return self;
}

+ (CGSize)getTextBoxForMessage:(FZZMessage *)message withLabelWidth:(float)textWidth
{
    //CGFloat textWidth = [UIScreen mainScreen].bounds.size.width - (52 + (7 * 3) + 47);
    
    UIFont *font;
    
    if (userCellMessageFont){
        font = userCellMessageFont;
    } else {
        font = kFZZLabelsFont();//[UIFont fontWithName:@"Futura-Medium" size:15.0];
    }
    
    FZZUser *me = [FZZUser me];
    
    if ([[message user] isEqual:me]){
        font = kFZZHostBodyFont();
    }
    
    NSString *text = [message text];
    
    
//    NSInteger strLength = [myString length];
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
//    [attString addAttribute:NSParagraphStyleAttributeName
//                      value:style
//                      range:NSMakeRange(0, strLength)];
    
    
    CGFloat width = textWidth;
    NSAttributedString *attributedText =
    [[NSAttributedString alloc]
     initWithString:text
     attributes:@
     {
           NSFontAttributeName:font
     }];
    CGRect rect = [attributedText boundingRectWithSize:(CGSize){width, CGFLOAT_MAX}
                                               options:NSStringDrawingUsesLineFragmentOrigin
                                               context:nil];
    
    if (rect.size.height > 80){
        rect.size.height *= 0.5;
    }
    
    return rect.size;
}

+ (float)messageLabelWidth{
    return messageLabelWidth;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
