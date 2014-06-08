//
//  UILabel+Trim.m
//  CommentStream
//
//  Created by Eugene Scherba on 9/27/13.
//  Copyright (c) 2013 Livefyre. All rights reserved.
//

#import <math.h>
#import "UILabel+Trim.h"

@implementation UILabel (Trim)

- (void)resizeVerticalCenterRightTrim
{
    CGSize textSize = [self sizeThatFits:self.bounds.size];
    CGRect textRect;
    textRect.origin = CGPointMake(self.frame.origin.x,
                                  self.frame.origin.y + floorf((self.bounds.size.height - textSize.height) / 2.f)
                                  );
    textRect.size = textSize;
    [self setFrame:textRect];
}

- (void)resizeVerticalTopRightTrim
{
    CGSize textSize = [self sizeThatFits:self.bounds.size];
    CGRect textRect;
    textRect.origin = self.frame.origin;
    textRect.size = textSize;
    [self setFrame:textRect];
}

- (void)resizeVerticalTopLeftTrim
{
    CGSize textSize = [self sizeThatFits:self.bounds.size];
    CGRect textRect;
    textRect.origin = CGPointMake(self.frame.origin.x + self.bounds.size.width - textSize.width,
                                  self.frame.origin.y
                                  );
    textRect.size = textSize;
    [self setFrame:textRect];
}

- (void)resizeVerticalBottomRightTrim
{
    CGSize textSize = [self sizeThatFits:self.bounds.size];
    CGRect textRect;
    textRect.origin = CGPointMake(self.frame.origin.x,
                                  self.frame.origin.y + self.bounds.size.height - textSize.height
                                  );
    textRect.size = textSize;
    [self setFrame:textRect];
}

@end
