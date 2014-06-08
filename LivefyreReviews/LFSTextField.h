//
//  LFSTextField.h
//  CommentStream
//
//  Created by Eugene Scherba on 9/17/13.
//  Copyright (c) 2013 Livefyre. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface LFSTextField : UITextField

// a subclass of UITextField that allows us to set custom
// padding/edge insets as well as more heavily rounded
// corners in iOS6
@property (nonatomic, assign) UIEdgeInsets textEdgeInsets;

@end
