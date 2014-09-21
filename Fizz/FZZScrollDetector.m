//
//  FZZScrollDetector.m
//  Fizz
//
//  Created by Andrew Sweet on 9/14/14.
//  Copyright (c) 2014 Fizz. All rights reserved.
//

#import "FZZScrollDetector.h"
#import "FZZExpandedVerticalTableViewController.h"
#import "FZZPage.h"
#import "FZZUtilities.h"
#import "FZZEvent.h"

static CGFloat kFZZInputScrollBuffer;

@interface FZZScrollDetector ()

@property BOOL touch;
@property BOOL touchStart;
@property BOOL scrollSubView;
@property UIScrollView *currentScrollView;
@property UIScrollView *movingScrollView;

@property UIScrollView *inputScrollView;

@property NSDictionary *pageOffsets;

@property CGPoint lastInputOffset;
@property CGPoint lastTVCOffset;

@end

@implementation FZZScrollDetector

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        _inputScrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
        _inputScrollView.delegate = self;
        
        CGSize size = CGSizeMake(frame.size.width, frame.size.height * 10);
        
        [_inputScrollView setContentSize:size];
        
        kFZZInputScrollBuffer = frame.size.height;
        
        [self addSubview:_inputScrollView];
        [self updateCurrentScrollView];
    }
    return self;
}

//- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
//    _touchStart = YES;
//    _touch = YES;
//    
//    NSLog(@"TOUCHBEGIN");
//    
//    UITouch *touch = [[event allTouches] anyObject];
//    _prevTouchLocation = [touch locationInView:[_vtvc tableView]];
//    _hasPrevTouchLocation = YES;
//    _lastOffset = [_vtvc tableView].contentOffset;
//}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    if (scrollView == _inputScrollView){
        _touchStart = YES;
        _touch = YES;
        _scrollSubView = NO;
        _movingScrollView = nil;
        
        [self updateCurrentScrollView];
        _lastTVCOffset = [[_vtvc tableView] contentOffset];
    }
    
//    else if (scrollView == [_vtvc tableView]) {
//        _touchStart = YES;
//        _touch = YES;
//        
//        _lastTVCOffset = [_vtvc tableView].contentOffset;
//    }
}

- (void)updateVTVCToPage:(FZZPage *)page{
    FZZEvent *event = [_vtvc getFZZEvent];
    
    _lastTVCOffset = [_vtvc tableView].contentOffset;
    
    if (page == nil){
        page = [self getCurrentPage];
    }
    
    NSLog(@"Page number: %d", page.pageNumber);
    NSIndexPath *pageIndex = [NSIndexPath indexPathForRow:page.pageNumber inSection:0];
    [event setScrollPosition:pageIndex];
}

- (void)updateVTVCPage{
    [self updateVTVCToPage:nil];
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    if (scrollView == _inputScrollView){
        [self updateVTVCPage];
        _scrollSubView = NO;
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if (scrollView == _inputScrollView) {
        
        [self handleSubScrollView];
        
        _lastInputOffset = _inputScrollView.contentOffset;
    }
}

-(BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    UITableViewCell *cell = [_vtvc getCurrentCell];
    
    for (UIView *view in cell.contentView.subviews) {
        if (!view.hidden && view.alpha > 0 && view.userInteractionEnabled && [view pointInside:[self convertPoint:point toView:view] withEvent:event]){
            return NO;
        }
    }
    
    return [super pointInside:point withEvent:event];
}

- (void)unmoveVtvc{
    [[_vtvc tableView] setContentOffset:_lastTVCOffset];
}

- (void)setVtvc:(FZZExpandedVerticalTableViewController *)vtvc{
    _vtvc = vtvc;
    
    [self setupPageOffsets];
}

- (void)updateCurrentScrollViewToMainView{
    [self updateInputScrollView];
    
    [_inputScrollView setBounces:[_vtvc.tableView bounces]];
    [_inputScrollView setDecelerationRate:[_vtvc.tableView decelerationRate]];
    [_inputScrollView setContentInset:[_vtvc.tableView contentInset]];
}

- (void)updateCurrentScrollView{
    _currentScrollView = [_vtvc getCurrentScrollView];
    
    [_inputScrollView setBounces:[_currentScrollView bounces]];
    [_inputScrollView setDecelerationRate:[_currentScrollView decelerationRate]];
    
    CGSize size;
    CGPoint offset;
    
    if (_currentScrollView){
        size = [_currentScrollView contentSize];
    
        size.height = size.height += [_inputScrollView bounds].size.height - [_currentScrollView bounds].size.height + 2;
        
        size.height = MAX([self bounds].size.height + (2 * kFZZInputScrollBuffer), size.height);
        
        offset = [_currentScrollView contentOffset];
        
        [_inputScrollView setDelegate:nil];
        [_inputScrollView setContentSize:size];
        [_inputScrollView setContentOffset:offset];
        [_inputScrollView setDelegate:self];
        [_inputScrollView setContentInset:[_currentScrollView contentInset]];
    } else {
        size = CGSizeMake([self bounds].size.width,
                          [self bounds].size.height + (2 * kFZZInputScrollBuffer));
        
        offset = CGPointMake(0, kFZZInputScrollBuffer);
        
        [_inputScrollView setDelegate:nil];
        [_inputScrollView setContentSize:size];
        [_inputScrollView setContentOffset:offset];
        [_inputScrollView setDelegate:self];
        [_inputScrollView setContentInset:UIEdgeInsetsZero];
    }
    
    _lastInputOffset = _inputScrollView.contentOffset;
}

- (void)handleSubScrollView{
    if (_touchStart){
        CGPoint delta = CGPointMake(0, _lastInputOffset.y - _inputScrollView.contentOffset.y);
        
        NSLog(@"DELTA %f", delta.y);
        
        if (delta.y > 0){
            _touchStart = NO;
            NSLog(@"SCROLL UP %f <= 0", _currentScrollView.contentOffset.y);
            if (_currentScrollView.contentOffset.y <= 0){
                
                // Scroll the main view
                [self updateCurrentScrollViewToMainView];
                
                CGPoint updatedOffset = CGPointMake(0, _inputScrollView.contentOffset.y);
                
                [[_vtvc tableView] setContentOffset:updatedOffset];
                
            } else {
                // Scroll the currentScrollView
//                [self updateCurrentScrollView];
                
                NSLog(@"SHOULD SCROLL SUBVIEW UP");
                
                _scrollSubView = YES;
                
                CGPoint updatedOffset = CGPointMake(_currentScrollView.contentOffset.x - delta.x,
                                                    _currentScrollView.contentOffset.y - delta.y);
                
                [_currentScrollView setContentOffset:updatedOffset];
            }
        } else if (delta.y < 0){
            _touchStart = NO;
            
            CGFloat maxContentOffset =_currentScrollView.contentSize.height - _currentScrollView.bounds.size.height;
            
            NSLog(@"SCROLL DOWN %f >= %f", _currentScrollView.contentOffset.y, maxContentOffset);
            
            if (_currentScrollView.contentOffset.y >= maxContentOffset){
                
                // Scroll the main view
                [self updateCurrentScrollViewToMainView];
                
                CGPoint updatedOffset = CGPointMake(0, _inputScrollView.contentOffset.y);
                
                [[_vtvc tableView] setContentOffset:updatedOffset];
                
            } else {
                NSLog(@"SHOULD SCROLL SUBVIEW DOWN");
                // Scroll the currentScrollView
//                [self updateCurrentScrollView];
                
                _scrollSubView = YES;
                
                CGPoint updatedOffset = CGPointMake(_currentScrollView.contentOffset.x - delta.x,
                                                    _currentScrollView.contentOffset.y - delta.y);
                
                [_currentScrollView setContentOffset:updatedOffset];
            }
        }
        return;
    }
    
    CGPoint delta = CGPointMake(_lastInputOffset.x - _inputScrollView.contentOffset.x,
                                _lastInputOffset.y - _inputScrollView.contentOffset.y);
    
    if (_movingScrollView){
        CGPoint updatedOffset = CGPointMake(0, _movingScrollView.contentOffset.y - delta.y);
        
        [_movingScrollView setContentOffset:updatedOffset];
        
    } else if (_scrollSubView){
        CGPoint updatedOffset = CGPointMake(0, _currentScrollView.contentOffset.y - delta.y);
        
        [_currentScrollView setContentOffset:updatedOffset];
        
    } else {
        // Main View Scroll
        CGPoint updatedOffset = CGPointMake(0, _inputScrollView.contentOffset.y);
        
        [[_vtvc tableView] setContentOffset:updatedOffset];
    }
}

- (FZZPage *)getCurrentPage{
    NSInteger numberOfRows = [[_vtvc tableView] numberOfRowsInSection:0];
    
    CGPoint offset = _lastTVCOffset;
    
    int pageNum = -1;
    
    CGFloat minDY = CGFLOAT_MAX;
    
    for (int i = 0; i < numberOfRows; ++i){
        NSNumber *pageOffset = [self getPageOffsetForPageNum:i];
        
        float dy = ABS(offset.y - [pageOffset floatValue]);
        
        if (dy < minDY){
            pageNum = i;
            minDY = dy;
        }
    }
    
    NSNumber *pageOffset = [self getPageOffsetForPageNum:pageNum];
    
    FZZPage *page = [[FZZPage alloc] init];
    [page setPageOffset:CGPointMake(0, [pageOffset floatValue])];
    [page setPageNumber:MIN(pageNum, numberOfRows-1)];
    
    return page;
}

- (void)setupPageOffsets{
    NSInteger numberOfRows = [[_vtvc tableView] numberOfRowsInSection:0];
    
    CGFloat y = 0;
    
    NSMutableDictionary *pageOffsets = [[NSMutableDictionary alloc] initWithCapacity:numberOfRows];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    
    CGFloat height = [_vtvc tableView:[_vtvc tableView] heightForRowAtIndexPath:indexPath];
    
    int pageNum = -1;
    
    for (int i = 0; i < numberOfRows; ++i){
        indexPath = [NSIndexPath indexPathForRow:i inSection:0];
        
        height = [_vtvc tableView:[_vtvc tableView] heightForRowAtIndexPath:indexPath];
        
        CGFloat pageVerticalOffset = [_vtvc tableView:[_vtvc tableView] offsetForRowAtIndexPath:indexPath];
        
        CGFloat pageOffset = y - pageVerticalOffset;
        
        pageNum = i;
        
        if (pageNum != numberOfRows - 1){
            [pageOffsets setObject:[NSNumber numberWithFloat:pageOffset]
                            forKey:[NSNumber numberWithInteger:pageNum]];
        }
        
        y += height;
    }
    
//    [pageOffsets setObject:nil
//                    forKey:[NSNumber numberWithInteger:numberOfRows - 1]];
    
    [pageOffsets setObject:[NSNumber numberWithFloat:y]
                    forKey:[NSNumber numberWithInteger:numberOfRows]];
    
    NSLog(@"PAGE OFFSETS %@", pageOffsets);
    
    _pageOffsets = pageOffsets;
}

- (NSNumber *)lastY{
    NSInteger numberOfRows = [[_vtvc tableView] numberOfRowsInSection:0];
    
    NSNumber *result = [NSNumber numberWithFloat:[_vtvc tableView].contentSize.height
                        - ([[_vtvc tableView] bounds].size.height + 2)];
    
    [(NSMutableDictionary *)_pageOffsets setObject:result
                                            forKey:[NSNumber numberWithInteger:numberOfRows - 1]];
    
    return result;
}

- (NSNumber *)getPageOffsetForPageNum:(NSInteger)pageNum{
    NSNumber *pageOffset = [_pageOffsets objectForKey:[NSNumber numberWithInteger:pageNum]];
    
    if (pageOffset == nil){
        pageOffset = [self lastY];
    }
    
    return pageOffset;
}

- (FZZPage *)getNextPage:(FZZPage *)page{
    NSInteger numberOfRows = [[_vtvc tableView] numberOfRowsInSection:0];
    
    if (page.pageNumber >= numberOfRows - 1) return page;
    
    NSInteger nextPageNumber = page.pageNumber + 1;
    
    NSNumber *pageOffset = [self getPageOffsetForPageNum:nextPageNumber];
    
    page = [[FZZPage alloc] init];
    [page setPageOffset:CGPointMake(0, [pageOffset floatValue])];
    [page setPageNumber:nextPageNumber];
    
    return page;
}

- (FZZPage *)getPreviousPage:(FZZPage *)page{
    
    if (page.pageNumber <= 0) return page;
    
    NSInteger prevPageNumber = page.pageNumber - 1;
    
    NSNumber *pageOffset = [self getPageOffsetForPageNum:prevPageNumber];
    
    page = [[FZZPage alloc] init];
    [page setPageOffset:CGPointMake(0, [pageOffset floatValue])];
    [page setPageNumber:prevPageNumber];
    
    return page;
}

- (BOOL)shouldScrollToNextPageWithVelocity:(CGPoint)velocity andOffset:(CGPoint)currentOffset{
    // Velocity is sufficient
    if (ABS(velocity.y) > kFZZMinPageScrollVelocity){
        NSLog(@"Is Fast Enough!");
        return YES;
    }
    
    // Offset is sufficient
    if ([self isOffsetSufficient:currentOffset]){
        NSLog(@"Is Offset Enough!");
        return YES;
    }
    
    NSLog(@"Isn't Fast Nor Offset Enough!");
    
    return NO;
}

- (BOOL)isOffsetSufficient:(CGPoint)currentOffset{
    FZZPage *page = [self getCurrentPage];
    
    CGPoint pageOffset = [page pageOffset];
    
    NSLog(@"CURRENT PAGE: %d (%f)", page.pageNumber, page.pageOffset.y);
    
    if (currentOffset.y < _lastTVCOffset.y){
        FZZPage *prevPage = [self getPreviousPage:page];
        
        CGPoint nextPoint = [prevPage pageOffset];
        
        NSLog(@"UP OFFSET: ABS(%f - %f) >= ABS(%f - %f)", pageOffset.y, currentOffset.y, nextPoint.y, currentOffset.y);
        
        if (ABS(pageOffset.y - currentOffset.y) >= ABS(nextPoint.y - currentOffset.y)){
            return YES;
        }
        
        return NO;
        
    } else {
        FZZPage *nextPage = [self getNextPage:page];
        
        CGPoint nextPoint = [nextPage pageOffset];
        
        NSLog(@"DOWN OFFSET: ABS(%f - %f) >= ABS(%f - %f)", pageOffset.y, currentOffset.y, nextPoint.y, currentOffset.y);
        
        if (ABS(pageOffset.y - currentOffset.y) >= ABS(nextPoint.y - currentOffset.y)){
            return YES;
        }
        
        return NO;
    }
}

- (void)updateInputScrollView{
    CGSize size = [[_vtvc tableView] contentSize];

    CGPoint offset = [[_vtvc tableView] contentOffset];

    [_inputScrollView setDelegate:nil];
    [_inputScrollView setContentSize:size];
    [_inputScrollView setContentOffset:offset];
    [_inputScrollView setDelegate:self];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    
    if (_scrollSubView){
        _touchStart = NO;
        _touch = NO;
        _movingScrollView = _currentScrollView;
        _currentScrollView = nil;
        
    } else {
        _touchStart = NO;
        _touch = NO;
        _currentScrollView = nil;
        
//        [self updateInputScrollView];
        
        CGPoint currentOffset = _inputScrollView.contentOffset;
        
        FZZPage *proposedPage;
        FZZPage *currentPage = [self getCurrentPage];
        
        // Velocity is sufficient or offset is enough
        if ([self shouldScrollToNextPageWithVelocity:velocity andOffset:currentOffset]){
            NSLog(@"%f - [%d]%f", currentOffset.y, currentPage.pageNumber, currentPage.pageOffset.y);
            
            if ((currentOffset.y - currentPage.pageOffset.y) > 0) {
                // bottom to top
                proposedPage = [self getNextPage:currentPage];
            }
            else if ((currentOffset.y - currentPage.pageOffset.y) < 0){
                // top to bottom
                proposedPage = [self getPreviousPage:currentPage];
            } else {
                proposedPage = currentPage;
            }
        } else {
            proposedPage = currentPage;
        }
        
        NSInteger numberOfPages = [[_vtvc tableView] numberOfRowsInSection:0];
        
        [self updateVTVCToPage:proposedPage];
        
        // what follows is a fix for a weird case where the scroll 'jumps' into place with no animation
        // from http://stackoverflow.com/questions/15233845/uicollectionview-does-not-always-animate-deceleration-when-overriding-scrollview
        if ([currentPage pageNumber] == [proposedPage pageNumber]) {
            if((currentPage.pageNumber == 0 && velocity.y > 0) ||
               (currentPage.pageNumber == (numberOfPages - 1) && velocity.y < 0) ||
               (currentPage.pageNumber > 0 && currentPage.pageNumber < (numberOfPages - 1) && fabs(velocity.y) > 0)
               ) {
                NSLog(@"SMOOTHED!");
                // this forces the scrolling animation to stop in its current place
                [_inputScrollView setContentOffset:_inputScrollView.contentOffset animated:NO];
                [UIView animateWithDuration:0.3
                                      delay:0.0
                                    options:UIViewAnimationOptionCurveEaseOut
                                 animations:^{
                                     [_inputScrollView setContentOffset:currentPage.pageOffset];
                                 }
                                 completion:nil];
            }
        }
        
        NSLog(@"current page: %d ||prop page: %d {%f}", [currentPage pageNumber], [proposedPage pageNumber], [proposedPage pageOffset].y);
        
        targetContentOffset->y = proposedPage.pageOffset.y;
    }
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
