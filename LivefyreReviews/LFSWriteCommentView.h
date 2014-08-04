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
@protocol LFSWriteCommentViewDelegate;

@interface LFSWriteCommentView : UIView <UITextViewDelegate,DLStarRatingDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate>
@property (nonatomic, assign) id<LFSWriteCommentViewDelegate>delegate;
@property (nonatomic, assign) UIImage *attachmentImage;

@property (nonatomic, strong) LFSResource* profileLocal;
@property (nonatomic, strong) UITextView *textView;
@property (readonly, nonatomic) UITextField *titleTextField;
@property (readonly, nonatomic) UITextField *prosTextField;
@property (readonly, nonatomic) UITextField *consTextField;
@property (readonly, nonatomic) NSString *ratingPost;
@property (readonly, nonatomic) DLStarRatingControl *starView;
@property (readonly, nonatomic) UIButton *button1;
-(void)setAttachmentImageWithURL:(NSURL*)url;
-(void)setAttachmentImage:(UIImage *)attachmentImage;
@end

@protocol LFSWriteCommentViewDelegate <NSObject>

-(void)didClickAddPhotoButton;

@end
