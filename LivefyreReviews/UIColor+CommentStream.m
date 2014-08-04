//
//  UIColor+CommentStream.m
//  CommentStream
//
//  Created by Eugene Scherba on 5/27/14.
//  Copyright (c) 2014 Livefyre. All rights reserved.
//

#import "UIColor+CommentStream.h"

@implementation UIColor (CommentStream)

+ (UIColor*)colorForToolbarButtonNormal {
    return [UIColor colorWithRed:162.f/255.f green:165.f/255.f blue:170.f/255.f alpha:1.f];
}

+ (UIColor*)colorForToolbarButtonHighlighted {
    return [UIColor colorWithRed:86.f/255.f green:88.f/255.f blue:90.f/255.f alpha:1.f];
}

+ (UIColor*)colorForToolbarButtonStateNormal {
    return [UIColor colorWithRed:241.f/255.f green:92.f/255.f blue:56.f/255.f alpha:1.f];
}

+ (UIColor*)colorForToolbarButtonStateHighlighted {
    return [UIColor colorWithRed:128.f/255.f green:49.f/255.f blue:29.f/255.f alpha:1.f];
}

+ (UIColor*)colorForCellSelectionBackground {
    return [UIColor colorWithRed:(217.f/255.f) green:(217.f/255.f) blue:(217.f/255.f) alpha:1.f];
}

+ (UIColor*)colorForImagePlaceholder {
    return [UIColor colorWithRed:232.f / 255.f
                           green:236.f / 255.f
                            blue:239.f / 255.f
                           alpha:1.f];
}

+ (UIColor*)colorForToolbarEdge {
    return [UIColor colorWithRed:(200.f/255.f)
                           green:(199.f/255.f)
                            blue:(204.f/255.f)
                           alpha:1.f];
}

@end
