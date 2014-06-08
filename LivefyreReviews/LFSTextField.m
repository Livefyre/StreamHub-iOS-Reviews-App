//
//  LFSTextField.m
//  CommentStream
//
//  Created by Eugene Scherba on 9/17/13.
//  Copyright (c) 2013 Livefyre. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <StreamHub-iOS-SDK/LFSConstants.h>
#import "LFSTextField.h"

@interface LFSTextField ()
@property (nonatomic, strong) CAShapeLayer *shadowLayer;
@property (nonatomic, strong) CAShapeLayer *maskLayer;
@end

@implementation LFSTextField

#pragma mark - Properties
@synthesize shadowLayer = _shadowLayer;
@synthesize textEdgeInsets = _textEdgeInsets;
@synthesize maskLayer = _maskLayer;

#pragma mark - Lifecycle
-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setFont:[UIFont systemFontOfSize:13.f]];
        [self setAutoresizingMask:
         (UIViewAutoresizingFlexibleHeight |
          UIViewAutoresizingFlexibleWidth)];
        
        if (LFS_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(LFSSystemVersion70))
        {
            // iOS7
            [self setTextEdgeInsets:UIEdgeInsetsMake(0.f, 5.f, 0.f, 0.f)];
            
            [self.layer setMasksToBounds:YES];
            [self.layer setCornerRadius:6.f];
            [self.layer setBorderColor:[[UIColor lightGrayColor] CGColor]];
            [self.layer setBorderWidth:0.5f];
        } else {
            // call drawRect when orientation changes
            [self setContentMode:UIViewContentModeRedraw];
            
            _shadowLayer = [CAShapeLayer layer];
            _maskLayer = [CAShapeLayer layer];
            
            [_shadowLayer setShadowColor:[[UIColor blackColor] CGColor]];
            [_shadowLayer setShadowOffset:CGSizeMake(0.5f, 0.5f)];
            [_shadowLayer setShadowOpacity:0.95f];
            [_shadowLayer setShadowRadius:2.f];
            [_shadowLayer setFillRule:kCAFillRuleEvenOdd];
            [_shadowLayer setMask:_maskLayer];
            [_shadowLayer setMasksToBounds:YES];
            [self.layer addSublayer:_shadowLayer];
        }
        [self.layer setBackgroundColor:
         [[UIColor whiteColor] CGColor]];
    }
    return self;
}

-(void)dealloc
{
    _shadowLayer = nil;
    _maskLayer = nil;
}

#pragma mark - Drawing
- (void)drawRect:(CGRect)rect {
    if (LFS_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(LFSSystemVersion70)) {
        [super drawRect:rect];
    } else {
        [self drawRoundedWithRect:rect];
    }
}

-(void)drawRoundedWithRect:(CGRect)rect
{
    // For iOS6 or earlier only
    CGFloat radius = rect.size.height / 2.f;
    self.layer.cornerRadius = radius;
    [_shadowLayer setFrame:rect];
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, CGRectInset(rect, -42.f, -42.f));
    CGPathRef innerPath =
    [[UIBezierPath bezierPathWithRoundedRect:rect
                                cornerRadius:radius] CGPath];
    CGPathAddPath(path, NULL, innerPath);
    CGPathCloseSubpath(path);
    [_shadowLayer setPath:path];
    CGPathRelease(path);
    [_maskLayer setPath:innerPath];
    
    [self setTextEdgeInsets:UIEdgeInsetsMake(radius - 9.f, 8.f, 0.f, 0.f)];
    
}

#pragma mark - Other
- (CGRect)textRectForBounds:(CGRect)bounds {
	return UIEdgeInsetsInsetRect([super textRectForBounds:bounds], _textEdgeInsets);
}

@end
