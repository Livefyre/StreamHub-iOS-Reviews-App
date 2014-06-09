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

#import "LFSWriteCommentView.h"
#import "UILabel+Trim.h"

static const UIEdgeInsets kDetailPadding = {
    .top=15.0f, .left=15.0f, .bottom=15.0f, .right=15.0f
};

static const UIEdgeInsets kPostContentInset = {
    .top=75.f, .left=7.f, .bottom=20.f, .right=5.f
};

// header font settings
static const CGFloat kDetailHeaderAttributeTopFontSize = 11.f;
static const CGFloat kDetailHeaderTitleFontSize = 15.f;
static const CGFloat kDetailHeaderSubtitleFontSize = 12.f;

// content font settings
static NSString* const kPostContentFontName = @"Georgia";
static const CGFloat kPostContentFontSize = 16.0f;

// header label heights
static const CGFloat kDetailHeaderAttributeTopHeight = 10.0f;
static const CGFloat kDetailHeaderAttributeTopImageHeight = 18.0f;
static const CGFloat kDetailHeaderTitleHeight = 18.0f;
static const CGFloat kHeaderSubtitleHeight = 10.0f;

static const CGFloat kPostKeyboardMarginTop = 0.0f;

// TODO: calculate avatar size based on pixel image size
static const CGSize  kDetailImageViewSize = { .width=38.0f, .height=38.0f };
static const CGFloat kDetailImageCornerRadius = 4.f;
static const CGFloat kDetailImageMarginRight = 8.0f;

static const CGFloat kDetailRemoteButtonWidth = 20.0f;
//static const CGFloat kDetailRemoteButtonHeight = 20.0f;


@interface LFSWriteCommentView ()

// UIView-specific
@property (readonly, nonatomic) UIImageView *headerImageView;
@property (readonly, nonatomic) UILabel *headerAttributeTopView;
@property (readonly, nonatomic) UIImageView *headerAttributeTopImageView;
@property (readonly, nonatomic) UILabel *headerTitleView;
@property (readonly, nonatomic) UILabel *headerSubtitleView;

@end

@implementation LFSWriteCommentView {
    CGFloat _previousViewHeight;
}

#pragma mark - Properties

@synthesize profileLocal = _profileLocal;

#pragma mark -
@synthesize headerImageView = _headerImageView;
-(UIImageView*)headerImageView
{
    if (_headerImageView == nil) {
        
        CGSize avatarViewSize;
        if ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)]
            && ([UIScreen mainScreen].scale == 2.f))
        {
            // Retina display, okay to use half-points
            avatarViewSize = CGSizeMake(37.5f, 37.5f);
        }
        else
        {
            // non-Retina display, do not use half-points
            avatarViewSize = CGSizeMake(37.f, 37.f);
        }
        CGRect frame;
        frame.size = avatarViewSize;
        frame.origin = CGPointMake(kDetailPadding.left, kDetailPadding.top);
        
        if (![_textView respondsToSelector:@selector(setTextContainerInset:)]) {
            // iOS6
            frame.origin.y -= kPostContentInset.top;
            frame.origin.x -= kPostContentInset.left;
        }
        
        // initialize
        _headerImageView = [[UIImageView alloc] initWithFrame:frame];
        
        // configure
        [_headerImageView
         setAutoresizingMask:(UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin)];
        
        _headerImageView.layer.cornerRadius = kDetailImageCornerRadius;
        _headerImageView.layer.masksToBounds = YES;
        
        // add to superview
        [self.textView addSubview:_headerImageView];
    }
    return _headerImageView;
}

#pragma mark -
@synthesize headerAttributeTopView = _headerAttributeTopView;
- (UILabel*)headerAttributeTopView
{
    if (_headerAttributeTopView == nil) {
        CGFloat leftColumnWidth = kDetailPadding.left + kDetailImageViewSize.width + kDetailImageMarginRight;
        CGFloat rightColumnWidth = kDetailRemoteButtonWidth + kDetailPadding.right;
        CGSize labelSize = CGSizeMake(self.bounds.size.width - leftColumnWidth - rightColumnWidth,
                                      kDetailHeaderAttributeTopHeight);
        CGRect frame;
        frame.size = labelSize;
        frame.origin = CGPointMake(leftColumnWidth,
                                   kDetailPadding.top); // size.y will be changed in layoutSubviews
        if (![_textView respondsToSelector:@selector(setTextContainerInset:)]) {
            // iOS6
            frame.origin.y -= kPostContentInset.top;
            frame.origin.x -= kPostContentInset.left;
        }
        
        // initialize
        _headerAttributeTopView = [[UILabel alloc] initWithFrame:frame];
        
        // configure
        [_headerAttributeTopView
         setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin)];
        [_headerAttributeTopView setFont:[UIFont systemFontOfSize:kDetailHeaderAttributeTopFontSize]];
        [_headerAttributeTopView setTextColor:[UIColor blueColor]];
        
        // add to superview
        [self.textView addSubview:_headerAttributeTopView];
    }
    return _headerAttributeTopView;
}

#pragma mark -
@synthesize headerAttributeTopImageView = _headerAttributeTopImageView;
- (UIImageView*)headerAttributeTopImageView
{
    if (_headerAttributeTopImageView == nil) {
        CGFloat leftColumnWidth = kDetailPadding.left + kDetailImageViewSize.width + kDetailImageMarginRight;
        CGFloat rightColumnWidth = kDetailRemoteButtonWidth + kDetailPadding.right;
        CGSize labelSize = CGSizeMake(self.bounds.size.width - leftColumnWidth - rightColumnWidth,
                                      kDetailHeaderAttributeTopImageHeight);
        CGRect frame;
        frame.size = labelSize;
        frame.origin = CGPointMake(leftColumnWidth,
                                   kDetailPadding.top); // size.y will be changed in layoutSubviews
        if (![_textView respondsToSelector:@selector(setTextContainerInset:)]) {
            // iOS6
            frame.origin.y -= kPostContentInset.top;
            frame.origin.x -= kPostContentInset.left;
        }
        
        // initialize
        _headerAttributeTopImageView = [[UIImageView alloc] initWithFrame:frame];
        
        // configure
        [_headerAttributeTopImageView
         setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin)];
        [_headerAttributeTopImageView setContentMode:UIViewContentModeTopLeft];
        
        // add to superview
        [self.textView addSubview:_headerAttributeTopImageView];
    }
    return _headerAttributeTopImageView;
}

#pragma mark -
@synthesize headerTitleView = _headerTitleView;
- (UILabel*)headerTitleView
{
    if (_headerTitleView == nil) {
        CGFloat leftColumnWidth = kDetailPadding.left + kDetailImageViewSize.width + kDetailImageMarginRight;
        CGFloat rightColumnWidth = kDetailRemoteButtonWidth + kDetailPadding.right;
        CGSize labelSize = CGSizeMake(self.bounds.size.width - leftColumnWidth - rightColumnWidth, kDetailHeaderTitleHeight);
        CGRect frame;
        frame.size = labelSize;
        frame.origin = CGPointMake(leftColumnWidth,
                                   kDetailPadding.top); // size.y will be changed in layoutSubviews
        if (![_textView respondsToSelector:@selector(setTextContainerInset:)]) {
            // iOS6
            frame.origin.y -= kPostContentInset.top;
            frame.origin.x -= kPostContentInset.left;
        }
        
        // initialize
        _headerTitleView = [[UILabel alloc] initWithFrame:frame];
        
        // configure
        [_headerTitleView
         setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin)];
        [_headerTitleView setFont:[UIFont boldSystemFontOfSize:kDetailHeaderTitleFontSize]];
        
        // add to superview
        [self.textView addSubview:_headerTitleView];
    }
    return _headerTitleView;
}

#pragma mark -
@synthesize headerSubtitleView = _headerSubtitleView;
- (UILabel*)headerSubtitleView
{
    if (_headerSubtitleView == nil) {
        CGFloat leftColumnWidth = kDetailPadding.left + kDetailImageViewSize.width + kDetailImageMarginRight;
        CGFloat rightColumnWidth = kDetailRemoteButtonWidth + kDetailPadding.right;
        CGSize labelSize = CGSizeMake(self.bounds.size.width - leftColumnWidth - rightColumnWidth, kHeaderSubtitleHeight);
        CGRect frame;
        frame.size = labelSize;
        frame.origin = CGPointMake(leftColumnWidth,
                                   kDetailPadding.top); // size.y will be changed in layoutSubviews
        if (![_textView respondsToSelector:@selector(setTextContainerInset:)]) {
            // iOS6
            frame.origin.y -= kPostContentInset.top;
            frame.origin.x -= kPostContentInset.left;
        }
        
        // initialize
        _headerSubtitleView = [[UILabel alloc] initWithFrame:frame];
        
        // configure
        [_headerSubtitleView
         setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin)];
        [_headerSubtitleView setFont:[UIFont systemFontOfSize:kDetailHeaderSubtitleFontSize]];
        [_headerSubtitleView setTextColor:[UIColor grayColor]];
        
        // add to superview
        [self.textView addSubview:_headerSubtitleView];
    }
    return _headerSubtitleView;
}

#pragma mark - Private overrides
-(void)layoutSubviews
{
    // layout header title label
    //
    // Note: preciese layout depends on whether we have subtitle field
    // (i.e. twitter handle)
    
    LFSResource *profileLocal = self.profileLocal;
    NSString *headerTitle = profileLocal.displayString;
    NSString *headerSubtitle = profileLocal.identifier;
    id headerAccessory = profileLocal.attributeObject;
    
    if (headerTitle && !headerSubtitle && !headerAccessory)
    {
        // display one string
        [self.headerTitleView setText:headerTitle];
        [self.headerTitleView resizeVerticalCenterRightTrim];
    }
    else if (headerTitle && headerSubtitle && !headerAccessory)
    {
        // full name + twitter handle
        
        CGRect headerTitleFrame = self.headerTitleView.frame;
        CGRect headerSubtitleFrame = self.headerSubtitleView.frame;
        
        CGFloat separator = floorf((kDetailImageViewSize.height
                                    - headerTitleFrame.size.height
                                    - headerSubtitleFrame.size.height) / 3.f);
        
        headerTitleFrame.origin.y = kDetailPadding.top + separator;
        headerSubtitleFrame.origin.y = (kDetailPadding.top
                                        + separator
                                        + headerTitleFrame.size.height
                                        + separator);
        
        [self.headerTitleView setFrame:headerTitleFrame];
        [self.headerTitleView setText:headerTitle];
        [self.headerTitleView resizeVerticalCenterRightTrim];
        
        [self.headerSubtitleView setFrame:headerSubtitleFrame];
        [self.headerSubtitleView setText:headerSubtitle];
        [self.headerSubtitleView resizeVerticalCenterRightTrim];
    }
    else if (headerTitle && !headerSubtitle && headerAccessory)
    {
        // attribute + full name
        CGRect headerTitleFrame = self.headerTitleView.frame;
        CGRect headerAttributeTopFrame = ([headerAccessory isKindOfClass:[UIImage class]]
                                          ? self.headerAttributeTopImageView.frame
                                          : self.headerAttributeTopView.frame);
        
        CGFloat separator = floorf((kDetailImageViewSize.height
                                    - headerTitleFrame.size.height
                                    - headerAttributeTopFrame.size.height) / 3.f);
        
        
        headerAttributeTopFrame.origin.y = (kDetailPadding.top + separator);
        headerTitleFrame.origin.y = (kDetailPadding.top
                                     + separator
                                     + headerAttributeTopFrame.size.height
                                     + separator);
        
        if ([headerAccessory isKindOfClass:[UIImage class]]) {
            [self.headerAttributeTopImageView setFrame:headerAttributeTopFrame];
            [self.headerAttributeTopImageView setImage:headerAccessory];
        }
        else {
            [self.headerAttributeTopView setFrame:headerAttributeTopFrame];
            [self.headerAttributeTopView setText:headerAccessory];
            [self.headerAttributeTopView resizeVerticalCenterRightTrim];
        }
        
        [self.headerTitleView setFrame:headerTitleFrame];
        [self.headerTitleView setText:headerTitle];
        [self.headerTitleView resizeVerticalCenterRightTrim];
    }
    else if (headerTitle && headerSubtitle && headerAccessory)
    {
        // attribute + full name + twitter handle
        CGRect headerTitleFrame = self.headerTitleView.frame;
        CGRect headerAttributeTopFrame = ([headerAccessory isKindOfClass:[UIImage class]]
                                          ? self.headerAttributeTopImageView.frame
                                          : self.headerAttributeTopView.frame);

        CGRect headerSubtitleFrame = self.headerSubtitleView.frame;
        
        CGFloat separator = floorf((kDetailImageViewSize.height
                                    - headerTitleFrame.size.height
                                    - headerAttributeTopFrame.size.height
                                    - headerSubtitleFrame.size.height) / 4.f);
        
        
        headerAttributeTopFrame.origin.y = (kDetailPadding.top + separator);
        headerTitleFrame.origin.y = (kDetailPadding.top
                                     + separator
                                     + headerAttributeTopFrame.size.height
                                     + separator);
        
        headerSubtitleFrame.origin.y = (kDetailPadding.top
                                        + separator
                                        + headerAttributeTopFrame.size.height
                                        + separator
                                        + headerTitleFrame.size.height
                                        + separator);
        
        if ([headerAccessory isKindOfClass:[UIImage class]]) {
            [self.headerAttributeTopImageView setFrame:headerAttributeTopFrame];
            [self.headerAttributeTopImageView setImage:headerAccessory];
        }
        else {
            [self.headerAttributeTopView setFrame:headerAttributeTopFrame];
            [self.headerAttributeTopView setText:headerAccessory];
            [self.headerAttributeTopView resizeVerticalCenterRightTrim];
        }
        
        [self.headerTitleView setFrame:headerTitleFrame];
        [self.headerTitleView setText:headerTitle];
        [self.headerTitleView resizeVerticalCenterRightTrim];
        
        [self.headerSubtitleView setFrame:headerSubtitleFrame];
        [self.headerSubtitleView setText:headerSubtitle];
        [self.headerSubtitleView resizeVerticalCenterRightTrim];
    }
    else {
        // no header
    }
    
    // layout avatar view
    [self.headerImageView setImageWithURL:[NSURL URLWithString:profileLocal.iconURLString]
                         placeholderImage:profileLocal.icon];
}

#pragma mark -
@synthesize textView = _textView;
-(UITextView*)textView
{
    if (_textView == nil) {
        CGRect frame = self.bounds;
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
            viewFrame.size.height = _previousViewHeight - overlapHeight - kPostKeyboardMarginTop;
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
    _headerImageView = nil;
    _headerTitleView = nil;
    
    _profileLocal = nil;
}


@end
