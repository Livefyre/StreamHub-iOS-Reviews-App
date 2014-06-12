//
//  LFSDeletedCell.m
//  CommentStream
//
//  Created by Eugene Scherba on 10/11/13.
//  Copyright (c) 2013 Livefyre. All rights reserved.
//

#import "LFSDeletedCell.h"
#import <StreamHub-iOS-SDK/LFSConstants.h>

static const CGFloat kDeletedCellImageCornerRadius = 4.f;

static const CGSize kDeletedCellImageViewSize = { .width=25.f, .height=25.f };

//static const CGFloat kDeletedCellHeaderAdjust = 2.f;

static const UIEdgeInsets kDeletedCellPadding = {
    .top=10.f, .left=15.f, .bottom=12.f, .right=12.f
};

static const CGFloat kDeletedCellMinorHorizontalSeparator = 8.0f;
//static const CGFloat kDeletedCellMinorVerticalSeparator = 12.0f;

//static const CGFloat kDeletedCellHeaderTitleFontSize = 12.f;

@interface LFSDeletedCell ()

@property (readonly, nonatomic) UILabel *headerTitleView;

@end

@implementation LFSDeletedCell

@synthesize headerTitleView = _headerTitleView;

#pragma mark - Class methods

+ (CGFloat)cellHeightForBoundsWidth:(CGFloat)width withLeftOffset:(CGFloat)_offsetLeft
{
    return kDeletedCellPadding.bottom + kDeletedCellPadding.top + kDeletedCellImageViewSize.height;
}


#pragma mark - Properties

#pragma mark -
@synthesize leftOffset = _leftOffset;
-(void)setLeftOffset:(CGFloat)leftOffset
{
    _leftOffset = leftOffset;
    if ([self respondsToSelector:@selector(setSeparatorInset:)]) {
        // setSeparatorInset is iOS7-only feature
        [self setSeparatorInset:UIEdgeInsetsMake(0.f, kDeletedCellPadding.left + _leftOffset, 0.f, 0.f)];
    }
}

#pragma mark - Lifecycle

-(id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault
                reuseIdentifier:reuseIdentifier];
    if (self)
    {
        // initialize subview references
        _leftOffset = 0.f;
        [self setSelectionStyle:UITableViewCellSelectionStyleNone];
        [self.textLabel setNumberOfLines:0]; // wrap text automatically
        [self.imageView.layer setCornerRadius:kDeletedCellImageCornerRadius];
        [self.imageView.layer setMasksToBounds:YES];
    }
    return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - Overrides

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	if (!self.superview) {
		return;
	}
    
    CGRect imageViewFrame;
    imageViewFrame.origin = CGPointMake(kDeletedCellPadding.left + _leftOffset, kDeletedCellPadding.top);
    imageViewFrame.size = kDeletedCellImageViewSize;
    [self.imageView setFrame:imageViewFrame];
    
    CGFloat leftColumnWidth = kDeletedCellPadding.left + _leftOffset + kDeletedCellImageViewSize.width + kDeletedCellMinorHorizontalSeparator;
    
    CGRect titleFrame = self.textLabel.frame;
    titleFrame.origin.x = leftColumnWidth;
    titleFrame.size.width = self.bounds.size.width - leftColumnWidth - kDeletedCellPadding.right;
    [self.textLabel setFrame:titleFrame];
}

@end
