//
//  FZZBackspaceResignTextView.m
//  Fizz
//
//  Created by Andrew Sweet on 3/19/14.
//  Copyright (c) 2014 Fizz. All rights reserved.
//

#import "FZZBackspaceResignTextView.h"
#import "FZZEventsExpandedViewController.h"

@interface FZZBackspaceResignTextView ()

@property FZZEventsExpandedViewController *esvc;
@property (strong, nonatomic) UITextView *textView;
@property (strong, nonatomic) UITextView *placeholderTextView;

@property BOOL isPlaceholder;

@end

@implementation FZZBackspaceResignTextView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        CGRect bounds = CGRectMake(0, 0, frame.size.width, frame.size.height);
        
        // Initialization code
        _placeholderTextView = [[UITextView alloc] initWithFrame:bounds];
        [_placeholderTextView setUserInteractionEnabled:NO];
        [_placeholderTextView setEditable:NO];
        [_placeholderTextView setBackgroundColor:[UIColor clearColor]];
        _placeholderTextView.textColor = [UIColor lightGrayColor];
        [self setBackgroundColor:[UIColor clearColor]];
        
        [self addSubview:_placeholderTextView];
        
        [self showPlaceholder:YES];
        
        _textView = [[UITextView alloc] initWithFrame:bounds];
        [_textView setUserInteractionEnabled:YES];
        [_textView setBackgroundColor:[UIColor clearColor]];
        [_textView setTextColor:[UIColor darkTextColor]];
        
        [self addSubview:_textView];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(myTextDidChange)
                                                     name:UITextViewTextDidChangeNotification
                                                   object:_textView];
    }
    return self;
}

-(UITextView *)textView{
    return _textView;
}

-(void)setPlaceholderText:(NSString *)placeholderText{
    [_placeholderTextView setText:placeholderText];
}

-(NSTextContainer *)textContainer{
    return [_textView textContainer];
}

-(void)setFrame:(CGRect)frame{
    [super setFrame:frame];
    
    CGRect bounds = CGRectMake(0, 0, frame.size.width, frame.size.height);
    [_textView setFrame:bounds];
    [_placeholderTextView setFrame:bounds];
}

-(void)setText:(NSString *)text{
    [_textView setText:text];
    
//    [self myTextDidChange];
}

-(void)setFont:(UIFont *)font{
    [_textView setFont:font];
    [_placeholderTextView setFont:font];
}

-(void)setEnablesReturnKeyAutomatically:(BOOL)enablesReturnKeyAutomatically{
    [_textView setEnablesReturnKeyAutomatically:enablesReturnKeyAutomatically];
}

-(void)setReturnKeyType:(UIReturnKeyType)returnKeyType{
    [_textView setReturnKeyType:returnKeyType];
}

-(void)setEditable:(BOOL)editable{
    [_textView setEditable:editable];
}

-(void)setScrollEnabled:(BOOL)scrollEnabled{
    [_textView setScrollEnabled:scrollEnabled];
}

-(void)setDelegate:(id<UITextViewDelegate>)delegate{
    [_textView setDelegate:delegate];
}

- (void)deleteBackward
{
    [_textView deleteBackward];
    
    if ([_textView.text isEqualToString:@""]){
        [self showPlaceholder:YES];
        
        if (_esvc != NULL){
            [_esvc exitNewEventPrompt:self];
        }
    }
}

-(BOOL)resignFirstResponder{
    return [_textView resignFirstResponder];
}

-(void)setESVC:(FZZEventsExpandedViewController *)esvc{
    _esvc = esvc;
}

- (void)showPlaceholder:(BOOL)shouldShow{
    _isPlaceholder = shouldShow;
    [_placeholderTextView setHidden:!shouldShow];
}

// Implement the method which is called when our text changes:
- (void)myTextDidChange
{
    NSLog(@"<%@>", _textView.text);
    
    // Change the background color
    if (_isPlaceholder){ // Placeholder is already on
        if ([_textView.text length] > 0){
            [self showPlaceholder:NO];
        }
    } else { // Placeholder is off
        if ([_textView.text length] == 0){
            [self showPlaceholder:YES];
        }
    }
}

- (void)dealloc
{
    // Stop listening when deallocating
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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