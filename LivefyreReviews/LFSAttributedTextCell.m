//
//  LFAttributedTextCell.m
//  CommentStream
//
//  Created by Eugene Scherba on 8/14/13.
//  Copyright (c) 2013 Livefyre. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import <OHAttributedLabel/NSAttributedString+Attributes.h>

#import <StreamHub-iOS-SDK/LFSConstants.h>
#import <StreamHub-iOS-SDK/NSDateFormatter+RelativeTo.h>

#import "LFSBasicHTMLParser.h"
#import "LFSAttributedTextCell.h"
#import "UILabel+Trim.h"
#import "DLStarRatingControl.h"


// external constants
const CGSize kCellImageViewSize = { .width=25.f, .height=25.f };
const CGSize kAttachmentImageViewSize = { .width=75.f, .height=75.f }; // 150x150 px thumbnail

static const UIEdgeInsets kCellPadding = {
    .top=10.f, .left=15.f, .bottom=12.f, .right=12.f
};

static const CGFloat kCellContentPaddingRight = 10.f;
static const CGFloat kCellContentLineSpacing = 6.f;
static const CGFloat kCellContentTitleLineSpacing = 9.f;

static NSString* const kCellBodyFontName = @"Georgia";
static const CGFloat kCellBodyFontSize = 18.f;
static const CGFloat kCellBodyTitleFontSize = 24.f;

static const CGFloat kCellHeaderTitleFontSize = 12.f;
static const CGFloat kCellHeaderSubtitleFontSize = 11.f;

static const CGFloat kCellHeaderAdjust = 2.f;

static const CGFloat kCellHeaderAttributeAdjust = -1.f;
static const CGFloat kCellHeaderAttributeTopHeight = 10.0f;
static const CGFloat kCellHeaderAttributeTopFontSize = 12.f;

static const CGFloat kCellHeaderAccessoryRightAdjust = 1.f;
static const CGFloat kCellHeaderAccessoryRightFontSize = 11.f;
static const CGFloat kCellHeaderAccessoryRightImageAlpha = 0.618f;
static const CGSize  kCellHeaderAccessoryRightImageMaxSize = { .width = 12, .height = 10 };

static const CGFloat kCellImageCornerRadius = 4.f;

static const CGFloat kCellMinorHorizontalSeparator = 8.0f;
static const CGFloat kCellMinorVerticalSeparator = 12.0f;



@interface LFSAttributedTextCell ()
// store hash to avoid relayout of same HTML
@property (nonatomic, assign) NSUInteger contentHash;

@property (readonly, nonatomic) UILabel *headerAttributeTopView;
@property (readonly, nonatomic) UILabel *headerTitleView;
@property (readonly, nonatomic) UILabel *headerSubtitleView;
@property (readonly, nonatomic) DYRateView *headerRatingView;
@property (readonly, nonatomic) UILabel *footerLeftView;
@property (readonly, nonatomic) UILabel *footerRightView;
@property (nonatomic, strong) UIImageView *attachmentImageView;


@property (nonatomic, readonly) UILabel *headerAccessoryRightView;

@end

@implementation LFSAttributedTextCell

#pragma mark - class methods

+ (NSMutableAttributedString*)attributedStringFromHTMLString:(NSString*)html
{
    static UIFont *bodyFont = nil;
    if (bodyFont == nil) {
        bodyFont = [UIFont fontWithName:kCellBodyFontName size:kCellBodyFontSize];
    }
    static NSMutableParagraphStyle* paragraphStyle = nil;
    if (paragraphStyle == nil) {
        paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        [paragraphStyle setLineSpacing:kCellContentLineSpacing];
    }
    
    NSMutableAttributedString *attributedText =
    [LFSBasicHTMLParser attributedStringByProcessingMarkupInString:html];
    [attributedText setFont:bodyFont];
    [attributedText addAttribute:NSParagraphStyleAttributeName
                           value:paragraphStyle
                           range:NSMakeRange(0u, [attributedText length])];
    
    return attributedText;
}

+ (NSMutableAttributedString*)attributedStringFromTitle:(NSString *)html{
    static UIFont *bodyFont = nil;
    if (bodyFont == nil) {
        bodyFont = [UIFont fontWithName:kCellBodyFontName size:kCellBodyTitleFontSize];
    }
    static NSMutableParagraphStyle* paragraphStyle = nil;
    if (paragraphStyle == nil) {
        paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        [paragraphStyle setLineSpacing:kCellContentTitleLineSpacing];
    }
    
    NSMutableAttributedString *attributedText =
    [LFSBasicHTMLParser attributedStringByProcessingMarkupInString:html];
    [attributedText setFont:bodyFont];
    [attributedText addAttribute:NSParagraphStyleAttributeName
                           value:paragraphStyle
                           range:NSMakeRange(0u, [attributedText length])];
    
    return attributedText;
}


+ (CGFloat)cellHeightForAttributedString:(NSMutableAttributedString*)attributedText
                           hasAttachment:(BOOL)hasAttachment
                                   width:(CGFloat)width
{
    /*  __________________________________
     * |   ___                            |
     * |  |ava|  <- avatar image          |
     * |  |___|                           |
     * |                           _____  |
     * |  Body text               | att | | <-- attachment
     * |  (number of lines can    | ach | |
     * |  vary)                   |_____| |
     * |__________________________________|
     *
     * |< - - - - - - width - - - - - - ->|
     */
    CGFloat bodyWidth = width - kCellPadding.left - kCellContentPaddingRight - (hasAttachment ? kAttachmentImageViewSize.width : 0.f);
    CGSize bodySize = [attributedText sizeConstrainedToSize:CGSizeMake(bodyWidth, CGFLOAT_MAX)];
    
    CGFloat deadHeight =kCellPadding.top+ kCellPadding.bottom  + kCellMinorVerticalSeparator+15;
    return (hasAttachment
            ? MAX(bodySize.height+35, kAttachmentImageViewSize.height+35) + kCellMinorVerticalSeparator
            : bodySize.height + deadHeight);
}

+(CGFloat)cellHeightForAttributedTitle:(NSMutableAttributedString *)attributedText hasAttachment:(BOOL)hasAttachment width:(CGFloat)width
{
    /*  __________________________________
     * |   ___                            |
     * |  |ava|  <- avatar image          |
     * |  |___|                           |
     * |                           _____  |
     * |  Title                   | att | | <-- attachment
     * |  (number of lines can    | ach | |
     * |  vary)                   |_____| |
     * |__________________________________|
     *
     * |< - - - - - - width - - - - - - ->|
     */
    CGFloat bodyTitleWidth = width - kCellPadding.left - kCellContentPaddingRight;
    CGSize bodyTitleSize = [attributedText sizeConstrainedToSize:CGSizeMake(bodyTitleWidth, CGFLOAT_MAX)];
    
    CGFloat deadHeight = kCellPadding.top + kCellPadding.bottom + kCellImageViewSize.height + kCellMinorVerticalSeparator;
    return (hasAttachment
            ? MAX(bodyTitleSize.height, 0) + deadHeight
            : bodyTitleSize.height);
//    return bodyTitleSize.height;
    
   }


+ (NSDateFormatter*)dateFormatter {
    static NSDateFormatter *_dateFormatter = nil;
    if (_dateFormatter == nil) {
        _dateFormatter = [[NSDateFormatter alloc] init];
    }
    return _dateFormatter;
}

#pragma mark - Misc properties
@synthesize contentHash = _contentHash;

@synthesize profileLocal = _profileLocal;
@synthesize profileRemote = _profileRemote;
@synthesize contentRemote = _contentRemote;
@synthesize requiredBodyHeight = _requiredBodyHeight;

#pragma mark -
@synthesize leftOffset = _leftOffset;
-(void)setLeftOffset:(CGFloat)leftOffset
{
    _leftOffset = leftOffset;
    if ([self respondsToSelector:@selector(setSeparatorInset:)]) {
        // setSeparatorInset is iOS7-only feature
        [self setSeparatorInset:UIEdgeInsetsMake(0.f, kCellPadding.left + _leftOffset, 0.f, 0.f)];
    }
}

#pragma mark - UIAppearance properties
@synthesize cellContentViewColor = _cellContentViewColor;
-(UIColor*)backgroundCellColor
{
    return self.contentView.backgroundColor;
}
-(void)setCellContentViewColor:(UIColor *)backgroundColor {
    [self setBackgroundColor:backgroundColor];
    [self.contentView setBackgroundColor:backgroundColor];
}

#pragma mark -
@synthesize headerTitleFont = _headerTitleFont;
-(UIFont*)headerTitleFont {
    return self.headerTitleView.font;
}
-(void)setHeaderTitleFont:(UIFont *)headerTitleFont {
    [self.headerTitleView setFont:headerTitleFont];
}

#pragma mark -
@synthesize headerTitleColor = _headerTitleColor;
-(UIColor*)headerTitleColor {
    return self.headerTitleView.textColor;
}
-(void)setHeaderTitleColor:(UIColor *)headerTitlecolor {
    [self.headerTitleView setTextColor:headerTitlecolor];
}

#pragma mark -
@synthesize bodyFont = _bodyFont;
-(UIFont*)bodyFont {
    return self.bodyView.font;
}
-(void)setBodyFont:(UIFont *)contentBodyFont {
    [self.bodyView setFont:contentBodyFont];
}

#pragma mark -
@synthesize bodyColor = _bodyColor;
-(UIColor*)bodyColor {
    return self.bodyView.textColor;
}
-(void)setBodyColor:(UIColor *)contentBodyColor {
    [self.bodyView setTextColor:contentBodyColor];
}

#pragma mark -
@synthesize headerAccessoryRightFont = _headerAccessoryRightFont;
-(UIFont*)headerAccessoryRightFont {
    return self.headerAccessoryRightView.font;
}
-(void)setHeaderAccessoryRightFont:(UIFont *)headerAccessoryRightFont {
    [self.headerAccessoryRightView setFont:headerAccessoryRightFont];
}

#pragma mark -
@synthesize headerAccessoryRightColor = _headerAccessoryRightColor;
-(UIColor*)headerAccessoryRightColor {
    return self.headerAccessoryRightView.textColor;
}
-(void)setHeaderAccessoryRightColor:(UIColor *)headerAccessoryRightColor {
    [self.headerAccessoryRightView setTextColor:headerAccessoryRightColor];
}

#pragma mark - Other properties
@synthesize contentDate = _contentDate;
-(void)setContentDate:(NSDate *)contentDate
{
    if (contentDate != _contentDate) {
        NSString *dateTime = [[[self class] dateFormatter]
                              relativeStringFromDate:contentDate];
        [self.headerAccessoryRightView setText:dateTime];
        [self setNeedsLayout];
    
        _contentDate = contentDate;
    }
}
#pragma mark -
@synthesize bodyTitleView = _bodyTitleView;
-(LFSBasicHTMLLabel*)bodyTitleView
{
	if (_bodyTitleView == nil) {
        const CGFloat kHeaderHeight = kCellPadding.top + kCellMinorVerticalSeparator;
        CGRect frame = CGRectMake(kCellPadding.left + _leftOffset,
                                  kHeaderHeight,
                                  self.bounds.size.width - kCellPadding.left - _leftOffset - kCellContentPaddingRight,
                                  self.bounds.size.height - kHeaderHeight);
        
        // initialize
        _bodyTitleView = [[LFSBasicHTMLLabel alloc] initWithFrame:frame];
        
        // configure OHAttributedLabel
        
        // do not display phonen number-looking data as links
        // (we wouldn't source personal information in the first place)
        [_bodyTitleView setAutomaticallyAddLinksForType:NSTextCheckingTypeLink];
        [_bodyTitleView setFont:[UIFont fontWithName:kCellBodyFontName
                                           size:kCellBodyTitleFontSize]];
        [_bodyTitleView setTextColor:[UIColor blackColor]];
        [_bodyTitleView setBackgroundColor:[UIColor clearColor]]; // for iOS6
        [_bodyTitleView setLineSpacing:kCellContentLineSpacing];
        
        // add to superview
		[self.contentView addSubview:_bodyTitleView];
	}
	return _bodyTitleView;
}


#pragma mark -
@synthesize bodyView = _bodyView;
-(LFSBasicHTMLLabel*)bodyView
{
	if (_bodyView == nil) {
        const CGFloat kHeaderHeight = kCellPadding.top + kCellImageViewSize.height + kCellMinorVerticalSeparator;
        CGRect frame = CGRectMake(kCellPadding.left + _leftOffset,
                                  kHeaderHeight,
                                  self.bounds.size.width - kCellPadding.left - _leftOffset - kCellContentPaddingRight,
                                  self.bounds.size.height - kHeaderHeight);
        
        // initialize
        _bodyView = [[LFSBasicHTMLLabel alloc] initWithFrame:frame];
        
        // configure OHAttributedLabel
        
        // do not display phonen number-looking data as links
        // (we wouldn't source personal information in the first place)
        [_bodyView setAutomaticallyAddLinksForType:NSTextCheckingTypeLink];
        [_bodyView setFont:[UIFont fontWithName:kCellBodyFontName
                                           size:kCellBodyFontSize]];
        [_bodyView setTextColor:[UIColor blackColor]];
        [_bodyView setBackgroundColor:[UIColor clearColor]]; // for iOS6
        [_bodyView setLineSpacing:kCellContentLineSpacing];
        
        // add to superview
		[self.contentView addSubview:_bodyView];
	}
	return _bodyView;
}

#pragma mark -
@synthesize headerAttributeTopView = _headerAttributeTopView;
- (UILabel*)headerAttributeTopView
{
    if (_headerAttributeTopView == nil) {
        CGFloat leftColumnWidth = kCellPadding.left + _leftOffset + kCellImageViewSize.width + kCellMinorHorizontalSeparator;
        CGSize labelSize = CGSizeMake(self.bounds.size.width - leftColumnWidth - kCellPadding.right,
                                      kCellHeaderAttributeTopHeight);
        CGRect frame;
        frame.size = labelSize;
        frame.origin = CGPointMake(leftColumnWidth,
                                   kCellPadding.top); // size.y will be changed in layoutSubviews
        // initialize
        _headerAttributeTopView = [[UILabel alloc] initWithFrame:frame];
        
        // configure
        [_headerAttributeTopView
         setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin)];
        [_headerAttributeTopView setFont:[UIFont systemFontOfSize:kCellHeaderAttributeTopFontSize]];
        [_headerAttributeTopView setTextColor:UIColorFromRGB(0x0F98EC)];
        
        // add to superview
        [self.contentView addSubview:_headerAttributeTopView];
    }
    return _headerAttributeTopView;
}

#pragma mark -
@synthesize headerAttributeTopImageView = _headerAttributeTopImageView;
- (UIImageView*)headerAttributeTopImageView
{
    if (_headerAttributeTopImageView == nil) {
        CGFloat leftColumnWidth = kCellPadding.left + _leftOffset + kCellImageViewSize.width + kCellMinorHorizontalSeparator;
        CGSize labelSize = CGSizeMake(self.bounds.size.width - leftColumnWidth - kCellPadding.right,
                                      kCellHeaderAttributeTopHeight);
        CGRect frame;
        frame.size = labelSize;
        frame.origin = CGPointMake(leftColumnWidth,
                                   kCellPadding.top); // size.y will be changed in layoutSubviews
        // initialize
        _headerAttributeTopImageView = [[UIImageView alloc] initWithFrame:frame];
        
        // configure
        [_headerAttributeTopImageView
         setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin)];
        [_headerAttributeTopImageView setContentMode:UIViewContentModeTopLeft];
        
        // add to superview
        [self.contentView addSubview:_headerAttributeTopImageView];
    }
    return _headerAttributeTopImageView;
}

#pragma mark -
@synthesize headerTitleView = _headerTitleView;
- (UILabel *)headerTitleView
{
	if (_headerTitleView == nil) {
        CGFloat leftColumnWidth = kCellPadding.left + _leftOffset + kCellImageViewSize.width + kCellMinorHorizontalSeparator;
        CGRect frame = CGRectMake(leftColumnWidth,
                                  kCellPadding.top - kCellHeaderAdjust,
                                  self.bounds.size.width - leftColumnWidth - kCellPadding.right,
                                  kCellImageViewSize.height + kCellHeaderAdjust + kCellHeaderAdjust);

        // initialize
        _headerTitleView = [[UILabel alloc] initWithFrame:frame];
        
        // configure
        [_headerTitleView setFont:[UIFont fontWithName:@"HelveticaNeue-Bold" size:kCellHeaderTitleFontSize]];
        [_headerTitleView setTextColor:[UIColor blackColor]];
        [_headerTitleView setBackgroundColor:[UIColor clearColor]]; // for iOS6
        
        // add to superview
		[self.contentView addSubview:_headerTitleView];
	}
	return _headerTitleView;
}

// header rating
@synthesize headerRatingView = _headerRatingView;

-(UIView *)headerRatingView
{
    if (_headerRatingView == nil) {
        
        CGFloat leftColumnWidth = kCellPadding.left + _leftOffset + kCellImageViewSize.width + kCellMinorHorizontalSeparator;
        

        CGRect frame = CGRectMake(leftColumnWidth,
                                  kCellPadding.top - kCellHeaderAdjust+_headerTitleView.frame.size.height,
                                  self.bounds.size.width - leftColumnWidth - kCellPadding.right,
                                  kCellImageViewSize.height + kCellHeaderAdjust + kCellHeaderAdjust-_headerTitleView.frame.size.height);
        // initialize

        _headerRatingView = [[DYRateView alloc] initWithFrame:frame fullStar:[UIImage imageNamed:@"icon_star_small.png"] emptyStar:[UIImage imageNamed:@"icon_star_empty_small.png"]];
        _headerRatingView.padding = 3;
        _headerRatingView.alignment = RateViewAlignmentLeft;
        _headerRatingView.userInteractionEnabled = NO;
        _headerRatingView.delegate = self;
       // _headerRatingView.rate=4.5;
        // configure
        [_headerRatingView
         setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin)];
        [_headerRatingView setBackgroundColor:[UIColor clearColor]];
        
        // add to superview
        [self.contentView addSubview:_headerRatingView];
        
        
    }
    return _headerRatingView;
}
@synthesize footerLeftView = _footerLeftView;
-(UILabel*)footerLeftView
{
    if (_footerLeftView == nil) {
        
        CGSize labelSize = CGSizeMake(floorf((self.bounds.size.width - kCellPadding.left - kCellPadding.right) / 2.f), kCellPadding.bottom);
        CGRect frame;
        frame.size = labelSize;
        frame.origin = CGPointMake(kCellPadding.left,
                                   _requiredBodyHeight);  // size.y will be changed in layoutSubviews
        
        // initialize
        _footerLeftView = [[UILabel alloc] initWithFrame:frame];
        
        // configure
        [_footerLeftView setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin];
        [_footerLeftView setFont:[UIFont fontWithName:@"HelveticaNeue" size:12.f]];
        [_footerLeftView setTextColor:UIColorFromRGB(0xb2b2b2)];
        
        // add to superview
        [self addSubview:_footerLeftView];
    }
    return _footerLeftView;
}

@synthesize footerRightView = _footerRightView;
-(UILabel*)footerRightView
{
    if (_footerRightView == nil) {
        
        CGSize labelSize = CGSizeMake(floorf((self.bounds.size.width - kCellPadding.left - kCellPadding.right) / 2.f), kCellPadding.bottom);
        CGRect frame;
        frame.size = labelSize;
        frame.origin = CGPointMake(kCellPadding.left,
                                   _requiredBodyHeight);  // size.y will be changed in layoutSubviews
        
        // initialize
        _footerRightView = [[UILabel alloc] initWithFrame:frame];
        
        // configure
        [_footerRightView setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin];
        [_footerRightView setFont:[UIFont fontWithName:@"HelveticaNeue" size:12.f]];
        [_footerRightView setTextColor:UIColorFromRGB(0xb2b2b2)];
        
        // add to superview
        [self addSubview:_footerRightView];
    }
    return _footerRightView;
}
#pragma mark - DYRateViewDelegate

- (void)rateView:(DYRateView *)rateView changedToNewRate:(NSNumber *)rate {
    //self.headerRatingView.text = [NSString stringWithFormat:@"Rate: %d", rate.intValue];
}

#pragma mark -
@synthesize headerSubtitleView = _headerSubtitleView;
- (UILabel*)headerSubtitleView
{
    if (_headerSubtitleView == nil) {
        CGFloat leftColumnWidth = kCellPadding.left + _leftOffset + kCellImageViewSize.width + kCellMinorHorizontalSeparator;
        CGRect frame = CGRectMake(leftColumnWidth,
                                  kCellPadding.top - kCellHeaderAdjust,
                                  self.bounds.size.width - leftColumnWidth - kCellPadding.right,
                                  kCellImageViewSize.height + kCellHeaderAdjust + kCellHeaderAdjust);
        // initialize
        _headerSubtitleView = [[UILabel alloc] initWithFrame:frame];
        
        // configure
        [_headerSubtitleView
         setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin)];
        [_headerSubtitleView setFont:[UIFont systemFontOfSize:kCellHeaderSubtitleFontSize]];
        [_headerSubtitleView setTextColor:[UIColor grayColor]];
        
        // add to superview
        [self.contentView addSubview:_headerSubtitleView];
    }
    return _headerSubtitleView;
}

#pragma mark -
@synthesize headerAccessoryRightView = _headerAccessoryRightView;
- (UILabel *)headerAccessoryRightView
{
	if (_headerAccessoryRightView == nil) {
        CGFloat leftColumnWidth = kCellPadding.left + _leftOffset + kCellImageViewSize.width + kCellMinorHorizontalSeparator;
        CGRect frame = CGRectMake(leftColumnWidth,
                                  kCellPadding.top - kCellHeaderAccessoryRightAdjust,
                                  self.bounds.size.width - leftColumnWidth - kCellPadding.right,
                                  kCellImageViewSize.height);

        // initialize
        _headerAccessoryRightView = [[UILabel alloc] initWithFrame:frame];
        
        // configure
        [_headerAccessoryRightView setFont:[UIFont fontWithName:@"HelveticaNeue" size:kCellHeaderAccessoryRightFontSize]];
        [_headerAccessoryRightView setTextColor:[UIColor lightGrayColor]];
        //[_headerAccessoryRightView setTextAlignment:NSTextAlignmentRight];
        
        // add to superview
		[self.contentView addSubview:_headerAccessoryRightView];
	}
	return _headerAccessoryRightView;
}

#pragma mark -
@synthesize headerAccessoryRightImageView = _headerAccessoryRightImageView;
- (UIImageView *)headerAccessoryRightImageView
{
	if (_headerAccessoryRightImageView == nil) {
        // initialize
        CGRect frame;
        frame.origin = CGPointZero;
        frame.size = kCellHeaderAccessoryRightImageMaxSize;
        _headerAccessoryRightImageView = [[UIImageView alloc] initWithFrame:frame];
        
        // configure
        [_headerAccessoryRightImageView setAlpha:kCellHeaderAccessoryRightImageAlpha];
        [_headerAccessoryRightImageView setContentMode:UIViewContentModeRight];
        
        // add to superview
		[self.contentView addSubview:_headerAccessoryRightImageView];
	}
	return _headerAccessoryRightImageView;
}

#pragma mark - 
@synthesize attachmentImageView = _attachmentImageView;
-(UIImageView*)attachmentImageView
{
    if (_attachmentImageView == nil) {
        // initialize
        CGRect frame;
        frame.origin = CGPointZero;
        frame.size = kAttachmentImageViewSize;
        _attachmentImageView = [[UIImageView alloc] initWithFrame:frame];
        
        // configure
        [_attachmentImageView setContentMode:UIViewContentModeCenter];
        
        // add to superview
		[self.contentView addSubview:_attachmentImageView];
    }
    return _attachmentImageView;
}

#pragma mark -
-(void)setAttachmentImage:(UIImage *)attachmentImage
{
    [self.attachmentImageView setImage:attachmentImage];
    // toggle image view visibility:
    [self.attachmentImageView setHidden:(attachmentImage == nil)];
}

#pragma mark - Overrides

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	if (!self.superview) {
		return;
	}
    
    CGRect bounds = self.bounds;
    [self layoutHeaderWithBounds:bounds];
    [self layoutBodyWithBounds:bounds];
}

#pragma mark - Private methods

-(void)layoutHeaderWithBounds:(CGRect)rect
{
    // layout header title label
    //
    // Note: preciese layout depends on whether we have subtitle field
    // (i.e. twitter handle)
    
    // layout avatar view
    CGRect imageViewFrame;
    imageViewFrame.origin = CGPointMake(kCellPadding.left + _leftOffset, kCellPadding.top);
    imageViewFrame.size = kCellImageViewSize;
    [self.imageView setFrame:imageViewFrame];
    
    LFSResource *profileLocal = self.profileLocal;
    NSString *headerTitle = profileLocal.displayString;
    NSString *headerSubtitle = profileLocal.identifier;
    //    NSNumber *rating=profileLocal.rating;
    id headerAccessory = profileLocal.attributeObject;
    
    CGFloat leftColumnWidth = kCellPadding.left + _leftOffset + kCellImageViewSize.width + kCellMinorHorizontalSeparator;
    
    if (headerTitle) {
        CGRect titleFrame = self.headerTitleView.frame;
        titleFrame.origin.x = leftColumnWidth;
        titleFrame.size.width =rect.size.width - leftColumnWidth - kCellPadding.right;
        [self.headerTitleView setFrame:titleFrame];
    }
    if (headerSubtitle) {
        CGRect subtitleFrame = self.headerSubtitleView.frame;
        subtitleFrame.origin.x = leftColumnWidth;
        subtitleFrame.size.width = rect.size.width - leftColumnWidth - kCellPadding.right;
        [self.headerSubtitleView setFrame:subtitleFrame];
    }
    if (headerTitle && !headerSubtitle && !headerAccessory)
    {
        // display one string
        [self.headerTitleView setText:headerTitle];
        [self.headerTitleView resizeVerticalCenterRightTrim];
    }
    else if (headerTitle && headerSubtitle && !headerAccessory)
    {
        // full name + twitter handle
        [self.headerTitleView setText:headerTitle];
        [self.headerTitleView resizeVerticalTopRightTrim];
        
        [self.headerSubtitleView setText:headerSubtitle];
        [self.headerSubtitleView resizeVerticalBottomRightTrim];
    }
    else if (headerTitle && !headerSubtitle && headerAccessory)
    {
        // attribute + full name
        [self.headerTitleView setText:headerTitle];
        [self.headerTitleView resizeVerticalTopRightTrim];
        CGRect headerTitleFrame = self.headerTitleView.frame;
        
        CGRect headerAttributeTopFrame;
        headerAttributeTopFrame.origin = CGPointMake(headerTitleFrame.origin.x
                                                     + headerTitleFrame.size.width
                                                     + kCellMinorHorizontalSeparator,
                                                     headerTitleFrame.origin.y - kCellHeaderAttributeAdjust);
        headerAttributeTopFrame.size = CGSizeMake(rect.size.width
                                                  - headerTitleFrame.origin.x
                                                  - headerTitleFrame.size.width,
                                                  headerTitleFrame.size.height);
        
        if ([headerAccessory isKindOfClass:[UIImage class]]) {
            [self.headerAttributeTopImageView setFrame:headerAttributeTopFrame];
            [self.headerAttributeTopImageView setImage:headerAccessory];
            [self.headerAttributeTopView setText:nil];
        }
        else {
            [self.headerAttributeTopView setFrame:headerAttributeTopFrame];
            [self.headerAttributeTopView setText:headerAccessory];
            [self.headerAttributeTopView resizeVerticalCenterRightTrim];
            [self.headerAttributeTopImageView setImage:nil];
        }
    }
    else if (headerTitle && headerSubtitle && headerAccessory)
    {
        // attribute + full name + twitter handle
        [self.headerTitleView setText:headerTitle];
        [self.headerTitleView resizeVerticalTopRightTrim];
        
        [self.headerSubtitleView setText:headerSubtitle];
        [self.headerSubtitleView resizeVerticalBottomRightTrim];
        if ([headerAccessory isKindOfClass:[UIImage class]]) {
            
            CGRect headerAttributeTopFrame;
            
            
            CGSize textSize = [headerTitle sizeWithAttributes:@{NSFontAttributeName:[self.headerAttributeTopView font]}];
            CGRect headerTitleFrame = self.headerTitleView.frame;
            
            if (textSize.width>140) {
                headerTitleFrame.size.width=140;
            }
            self.headerTitleView.frame=headerTitleFrame;
            headerAttributeTopFrame.origin = CGPointMake(headerTitleFrame.origin.x
                                                         + headerTitleFrame.size.width
                                                         + kCellMinorHorizontalSeparator,
                                                         headerTitleFrame.origin.y - kCellHeaderAttributeAdjust);
            headerAttributeTopFrame.size = CGSizeMake(rect.size.width
                                                      - headerTitleFrame.origin.x
                                                      - headerTitleFrame.size.width,
                                                      headerTitleFrame.size.height-2);
            
            [self.headerAttributeTopImageView setFrame:headerAttributeTopFrame];
            [self.headerAttributeTopImageView setImage:headerAccessory];
            [self.headerAttributeTopView setText:nil];
            self.headerAttributeTopImageView.contentMode=UIViewContentModeBottomLeft;
        }
        else {
            CGRect headerAttributeTopFrame;
            CGSize textSize = [headerTitle sizeWithAttributes:@{NSFontAttributeName:[self.headerAttributeTopView font]}];
            CGRect headerTitleFrame = self.headerTitleView.frame;
            
            if (textSize.width>140) {
                headerTitleFrame.size.width=140;
            }
            self.headerTitleView.frame=headerTitleFrame;
            
            headerAttributeTopFrame.origin = CGPointMake(headerTitleFrame.origin.x
                                                         + headerTitleFrame.size.width
                                                         + kCellMinorHorizontalSeparator,
                                                         headerTitleFrame.origin.y - kCellHeaderAttributeAdjust);
            headerAttributeTopFrame.size = CGSizeMake(rect.size.width
                                                      - headerTitleFrame.origin.x
                                                      - headerTitleFrame.size.width,
                                                      headerTitleFrame.size.height-2);
            
            [self.headerAttributeTopView setFrame:headerAttributeTopFrame];
            [self.headerAttributeTopView setText:headerAccessory];
            [self.headerAttributeTopView resizeVerticalCenterRightTrim];
            [self.headerAttributeTopImageView setImage:nil];
        }
    }    else {
        // no header
    }
    int count=0;
    NSArray *votes=[[NSArray alloc]initWithArray:[_content.annotations objectForKey:@"vote" ]];
    for (NSDictionary *voteObject in votes) {
        if ([[voteObject valueForKey:@"value"] integerValue] ==1) {
            count++;
        }[voteObject valueForKey:@"value"];
    }
    NSString *replyString=nil;
    if(_content.nodeCount-1 ==0){
        replyString=@"No Replies";
    }else if (_content.nodeCount-1 ==1){
        replyString=@"1 Reply";
    }else{
        replyString=[NSString stringWithFormat:@"%ld Replies",_content.nodeCount-1];
    }
     
    [self.footerLeftView setText:[NSString stringWithFormat:@"%d of %ld found helpful",count,(unsigned long)[[_content.annotations objectForKey:@"vote" ] count]]];
    [self.footerLeftView resizeVerticalBottomRightTrim];
    [self.footerRightView setText:[NSString stringWithFormat:@"%@",replyString ]];
    [self.footerRightView resizeVerticalBottomRightTrim];
    // layout note view
    CGRect accessoryRightFrame = self.headerAccessoryRightView.frame;
    accessoryRightFrame.origin.x = leftColumnWidth;
    accessoryRightFrame.size.width = rect.size.width - leftColumnWidth - kCellPadding.right;
    [self.headerAccessoryRightView setFrame:accessoryRightFrame];
    [self.headerAccessoryRightView setText:
     [[[self class] dateFormatter] relativeStringFromDate:self.contentDate]];
    [self.headerAccessoryRightView resizeVerticalTopLeftTrim];
    
    if (self.headerAccessoryRightImageView.image != nil) {
        CGRect headerAccessoryRightImageFrame = self.headerAccessoryRightImageView.frame;
        headerAccessoryRightImageFrame.origin = CGPointMake(
                                                            // x
                                                            self.headerAccessoryRightView.frame.origin.x -
                                                            headerAccessoryRightImageFrame.size.width - kCellMinorHorizontalSeparator,
                                                            
                                                            // y
                                                            self.headerAccessoryRightView.center.y - (self.headerAccessoryRightImageView.frame.size.height / 2.f)
                                                            );
        [self.headerAccessoryRightImageView setFrame:headerAccessoryRightImageFrame];
    }
}

-(void)layoutBodyWithBounds:(CGRect)rect
{
    
    //Body title
//    NSMutableAttributedString *attributedTitle=[ self getAttributedTextWithFormat:_content.title :24 :@"Georgia" :14];

//     CGSize titleSize = [attributedTitle sizeConstrainedToSize:CGSizeMake(290, CGFLOAT_MAX)];
    CGRect textTitleContentFrame;
    CGFloat leftTitleColumn = kCellPadding.left ;
    CGFloat rightTitleColumn = kCellContentPaddingRight ;
    
    
    NSMutableAttributedString *attributedTitleString=[LFSAttributedTextCell attributedStringFromTitle:(_content.title ?: @"")];

    textTitleContentFrame.origin = CGPointMake(leftTitleColumn,
                                          kCellPadding.top + kCellImageViewSize.height + kCellMinorVerticalSeparator);
    textTitleContentFrame.size = CGSizeMake(rect.size.width - leftTitleColumn - rightTitleColumn,
                                       [LFSAttributedTextCell cellHeightForAttributedTitle:attributedTitleString hasAttachment:NO width:(rect.size.width - leftTitleColumn - rightTitleColumn)]);
    [self.bodyTitleView setFrame:textTitleContentFrame];
    
    CGRect boundsTitle = self.bodyTitleView.bounds;
    boundsTitle.origin = CGPointZero;
    [self.bodyTitleView setBounds:boundsTitle];
    
    
    // layoutSubviews is always called after requiredRowHeightWithFrameWidth:
    // so we take advantage of that by reusing _requiredBodyHeight
    BOOL hasAttachment = (self.attachmentImageView.hidden == NO);
    
    
        CGRect textContentFrame;
    CGFloat leftColumn = kCellPadding.left + _leftOffset;
    CGFloat rightColumn = kCellContentPaddingRight + (hasAttachment ? kAttachmentImageViewSize.width : 0.f);
    NSMutableAttributedString *attributedbodyString=[LFSAttributedTextCell attributedStringFromHTMLString:(_content.bodyHtml ?: @"")];
    
    CGFloat bodysize=[LFSAttributedTextCell cellHeightForAttributedString:attributedbodyString hasAttachment:(hasAttachment ? kCellMinorHorizontalSeparator : 0.f) width:320];
    
    textContentFrame.origin = CGPointMake(leftTitleColumn,
                                                kCellImageViewSize.height + kCellMinorVerticalSeparator+textTitleContentFrame.size.height+15);
    textContentFrame.size = CGSizeMake(rect.size.width - leftColumn - rightColumn-(hasAttachment ? kCellMinorHorizontalSeparator : 0.f),
                                            bodysize);
    

    
//    NSMutableAttributedString *attributedbody=[ self getAttributedTextWithFormat:_content.bodyHtml :24 :@"Georgia" :14];
    
//    CGSize bodySize = [[self.bodyView text] sizeWithAttributes:@{NSFontAttributeName:[self.bodyView font]}];

    
//    textContentFrame.origin = CGPointMake(leftColumn,
//                                          kCellPadding.top +30+ kCellImageViewSize.height + kCellMinorVerticalSeparator);
//    textContentFrame.size = CGSizeMake(rect.size.width - leftColumn - rightColumn - (hasAttachment ? kCellMinorHorizontalSeparator : 0.f),
//                                       bodySize.height);
    [self.bodyView setFrame:textContentFrame];
    
    if (hasAttachment) {
        CGRect attachmentFrame;
        attachmentFrame.origin = CGPointMake(rect.size.width - rightColumn, textContentFrame.origin.y);
        attachmentFrame.size = kAttachmentImageViewSize;
        [self.attachmentImageView setFrame:attachmentFrame];
    }
    
    // fix an annoying bug (in OHAttributedLabel?) where y-value of bounds
    // would go in the negative direction if frame origin y-value exceeded
    // 44 pts (due to 44-pt toolbar being present?)
    CGRect bounds = self.bodyView.bounds;
    bounds.origin = CGPointZero;
    [self.bodyView setBounds:bounds];
    
    
    CGRect helpContentFrame;
    helpContentFrame.origin = CGPointMake(leftColumn,self.requiredBodyHeight);
    helpContentFrame.size = CGSizeMake(150,40);
    [self.footerLeftView setFrame:helpContentFrame];
    
    CGSize textSize = [[self.footerLeftView text] sizeWithAttributes:@{NSFontAttributeName:[self.footerLeftView font]}];
    CGFloat strikeWidth = textSize.width;
    CGRect repliesContentFrame;
    repliesContentFrame.origin=CGPointMake(leftColumn+strikeWidth +20, self.requiredBodyHeight);
    repliesContentFrame.size = CGSizeMake(100,40);
    [self.footerRightView setFrame:repliesContentFrame];
    
    //rating
    
    LFSResource *profileLocal = self.profileLocal;
    NSNumber *rating=profileLocal.rating;
    if (rating) {
    [self.headerRatingView setBackgroundColor:[UIColor clearColor]];
    [self.headerRatingView setRate:[rating floatValue]/20];
    }
}

-(NSMutableAttributedString*)getAttributedTextWithFormat:(NSString*)text :(float) fontSize :(NSString*)fontName :(float)lineSpace{
    NSMutableAttributedString *attributedText=[LFSBasicHTMLParser attributedStringByProcessingMarkupInString:text];
    UIFont *textFont;
    textFont = [UIFont fontWithName:fontName size:fontSize];
    NSMutableParagraphStyle* paragraphStyle;
    paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineSpacing:lineSpace];
    [attributedText setFont:textFont];
    [attributedText addAttribute:NSParagraphStyleAttributeName
                           value:paragraphStyle
                           range:NSMakeRange(0u, [attributedText length])];
    
    return attributedText;
}
#pragma mark - Public methods

- (void)setAttributedString:(NSMutableAttributedString *)attributedString
{
	// store hash isntead of attributed string itself
	NSUInteger newHash = attributedString ? [attributedString hash] : 0u;
    
	if (newHash == _contentHash) {
		return;
	}
    
	_contentHash = newHash;

    [self.bodyView setAttributedText:attributedString];
	[self setNeedsLayout];
}
- (void)setAttributedTitleString:(NSMutableAttributedString *)attributedString
{
	// store hash isntead of attributed string itself
	NSUInteger newHash = attributedString ? [attributedString hash] : 0u;
    
	if (newHash == _contentHash) {
		return;
	}
    
	_contentHash = newHash;
    
    [self.bodyTitleView setAttributedText:attributedString];
	[self setNeedsLayout];
}
#pragma mark - Lifecycle
-(id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault
                reuseIdentifier:reuseIdentifier];
    if (self)
    {
        // initialize subview references
        _contentHash = 0u;
        _bodyView = nil;
        _bodyTitleView=nil;
        _headerAccessoryRightView = nil;
        _headerAccessoryRightImageView = nil;
        _headerTitleView = nil;
        _contentDate = nil;

        _leftOffset = 0.f;
        
        [self setAccessoryType:UITableViewCellAccessoryNone];
        
        if (LFS_SYSTEM_VERSION_LESS_THAN(LFSSystemVersion70))
        {
            // iOS7-like selected background color
            [self setSelectionStyle:UITableViewCellSelectionStyleGray];
            UIView *selectionColor = [[UIView alloc] init];
            [selectionColor setBackgroundColor:[UIColor colorWithRed:(217.f/255.f)
                                                               green:(217.f/255.f)
                                                                blue:(217.f/255.f)
                                                               alpha:1.f]];
            [self setSelectedBackgroundView:selectionColor];
        }
        
        [self.imageView setContentMode:UIViewContentModeScaleToFill];
        [self.imageView.layer setCornerRadius:kCellImageCornerRadius];
        [self.imageView.layer setMasksToBounds:YES];
    }
    return self;
}
-(void)dealloc
{
    _bodyView = nil;
    _bodyTitleView=nil;
    _headerTitleView = nil;
    _headerAccessoryRightView = nil;
    _headerAccessoryRightImageView = nil;
    
    _contentDate = nil;
}

@end
