//
//  BCNMapAnnotationView.m
//  Beacon
//
//  Created by Andrew Sweet on 1/4/14.
//  Copyright (c) 2014 Beacon. All rights reserved.
//

#import "BCNMapAnnotationView.h"

@implementation BCNMapAnnotationView

@synthesize image, label;


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
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
