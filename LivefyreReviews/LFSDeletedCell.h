//
//  LFSDeletedCell.h
//  CommentStream
//
//  Created by Eugene Scherba on 10/11/13.
//  Copyright (c) 2013 Livefyre. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LFSDeletedCell : UITableViewCell

-(id)initWithReuseIdentifier:(NSString *)reuseIdentifier;

@property (nonatomic, assign) CGFloat leftOffset;

+ (CGFloat)cellHeightForBoundsWidth:(CGFloat)width withLeftOffset:(CGFloat)_offsetLeft;

@end
