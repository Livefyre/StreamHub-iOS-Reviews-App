//
//  LFSWriteCommentView.m
//  CommentStream
//
//  Created by Eugene Scherba on 10/16/13.
//  Copyright (c) 2013 Livefyre. All rights reserved.
//

#import <math.h>
#import <QuartzCore/QuartzCore.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import "LFSReplyWriteCommentView.h"
#import "UILabel+Trim.h"


static const UIEdgeInsets kPostContentInset = {
    .top=15.f, .left=7.f, .bottom=20.f, .right=5.f
};
static const CGFloat kPostKeyboardMarginTop = 10.0f;
static NSString* const kPostContentFontName = @"Georgia";
static const CGFloat kPostContentFontSize = 18.0f;

@interface LFSReplyWriteCommentView ()

@end

@implementation LFSReplyWriteCommentView {
    CGFloat _previousViewHeight;
}

#pragma mark - Properties

@synthesize profileLocal = _profileLocal;
#pragma mark -
 #pragma mark - Private overrides
-(void)layoutSubviews{
    
}

- (CGFloat)layoutManager:(NSLayoutManager *)layoutManager lineSpacingAfterGlyphAtIndex:(NSUInteger)glyphIndex withProposedLineFragmentRect:(CGRect)rect
{
    return 28; // For really wide spacing; pick your own value
}

#pragma mark -
@synthesize textView = _textView;
-(UITextView*)textView
{
    if (_textView == nil) {
        CGRect frame = self.bounds;
        frame.origin.y+=0;
        frame.size.height-=0;
        NSLog(@"%f %f",self.bounds.origin.x, self.bounds.origin.y);
        _textView = [[UITextView alloc] initWithFrame:frame];
        
        [_textView setBackgroundColor:[UIColor whiteColor]];
        
        if ([_textView respondsToSelector:@selector(setTextContainerInset:)]) {
            // iOS7
            [_textView setTextContainerInset:kPostContentInset];
        } else {
            // iOS6
            [_textView setContentInset:UIEdgeInsetsMake(kPostContentInset.top, 0.f, kPostContentInset.bottom, 0.f)];
        }
        [_textView setFont:[UIFont fontWithName:kPostContentFontName size:kPostContentFontSize]];
        [_textView setUserInteractionEnabled:YES];
        [_textView setScrollEnabled:YES];
        [_textView setDelegate:self];
        
        [_textView
         setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin)];
        
        [self addSubview:_textView];
    }
    return _textView;
}


#pragma mark - UITextViewDelegate
-(void)textViewDidChange:(UITextView *)textView
{
    CGRect caret_rect = [textView caretRectForPosition:textView.selectedTextRange.end];
    UIEdgeInsets insets = textView.contentInset;
    CGRect visible_rect = textView.bounds;
    visible_rect.size.height -= (insets.top + insets.bottom);
    visible_rect.origin.y = textView.contentOffset.y;
    
    if (!CGRectContainsRect(visible_rect, caret_rect)) {
        CGFloat new_offset = MAX((caret_rect.origin.y + caret_rect.size.height) - visible_rect.size.height - textView.contentInset.top,  -textView.contentInset.top);
        [textView setContentOffset:CGPointMake(0, new_offset) animated:NO];
    }
}

#pragma mark - Lifecycle

+(CGRect)screenBounds
{
    UIScreen *screen = [UIScreen mainScreen];
    CGRect screenRect = screen.bounds;
    
    if (UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation])) {
        CGRect temp;
        temp.size.width = screenRect.size.height;
        temp.size.height = screenRect.size.width;
        screenRect = temp;
    }
    return screenRect;
}

- (void)moveTextViewForKeyboard:(NSNotification*)aNotification up:(BOOL)up
{
    NSDictionary* userInfo = [aNotification userInfo];
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect keyboardEndFrame;
    
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardEndFrame];
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:animationDuration];
    [UIView setAnimationCurve:animationCurve];
    
    CGRect viewFrame = self.frame;
    
    // convert to window base coordinates
    CGRect keyboardFrame = [self convertRect:keyboardEndFrame toView:nil];
    
    // calculate overlap height
    CGRect screenBounds = [[self class] screenBounds];
    
    // view frame bottom minus keyboard top
    CGFloat overlapHeight = viewFrame.origin.y + viewFrame.size.height - (screenBounds.size.height - keyboardFrame.size.height);
    if (overlapHeight > 0.f && overlapHeight < viewFrame.size.height)
    {
        // need to take action (there is an overlap and it does not cover the whole view)
        if (up) {
            // shrink the view
            _previousViewHeight = viewFrame.size.height;
            viewFrame.size.height = _previousViewHeight - overlapHeight -kPostKeyboardMarginTop;
         } else {
            // restore the previous view height
            viewFrame.size.height = _previousViewHeight;
        }
        [self setFrame:viewFrame];
    }
    
    [UIView commitAnimations];
}

- (void)keyboardWillShow:(NSNotification*)aNotification
{
    [self moveTextViewForKeyboard:aNotification up:YES];
}

- (void)keyboardWillHide:(NSNotification*)aNotification
{
    [self moveTextViewForKeyboard:aNotification up:NO];
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Initialization code
        [self resetFields];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self resetFields];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
        _previousViewHeight = frame.size.height;
    }
    return self;
}

- (void)dealloc
{
    [_textView setDelegate:nil];
    [self resetFields];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}

-(void)resetFields
{
    
    _profileLocal = nil;
}


@end
