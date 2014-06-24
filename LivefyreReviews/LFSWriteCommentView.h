//
//  LFSWriteCommentView.h
//  CommentStream
//
//  Created by Eugene Scherba on 10/16/13.
//  Copyright (c) 2013 Livefyre. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LFSResource.h"
#import "DLStarRatingControl.h"

@interface LFSWriteCommentView : UIView <UITextViewDelegate,DLStarRatingDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate>

@property (nonatomic, strong) LFSResource* profileLocal;
@property (nonatomic, strong) UITextView *textView;
@property (readonly, nonatomic) UITextField *titleTextField;
@property (readonly, nonatomic) UITextField *prosTextField;
@property (readonly, nonatomic) UITextField *consTextField;
@end
