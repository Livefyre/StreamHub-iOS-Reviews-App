//
//  LFRAnimationDetailViewController.h
//  LivefyreReviews
//
//  Created by Kvana Inc 2 on 04/07/14.
//  Copyright (c) 2014 Kvana Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LFSBasicHTMLParser.h"
#import "LFRDetailTableViewCell.h"
#import "LFSContent.h"
#import "LFSContentCollection.h"
#import "LFSUser.h"


@protocol LFRAnimationDetailTableViewCellDelegate;

@protocol Delete <NSObject>
-(void)postDestructiveMessage:(LFSMessageAction)message forContent:(LFSContent*)content;
-(void)featureContent:(LFSContent*)content;
-(void)banAuthorOfContent:(LFSContent*)content;
-(void)flagContent:(LFSContent*)content withFlag:(LFSContentFlag)flag;
-(void)editReviewOfContent:(LFSMessageAction)message forContent:(LFSContent*)content;

@end


@interface LFRAnimationDetailViewController : UIViewController<UITableViewDataSource,UITableViewDelegate,UIActionSheetDelegate>
@property (weak, nonatomic) id <Delete> deletedContent;
@property (weak, nonatomic) IBOutlet UITableView *detailTable;
@property (nonatomic, copy) NSDictionary *collection;
@property (nonatomic, copy) NSString *collectionId;
@property (retain, nonatomic) UIActionSheet *actionSheet;
@property (retain, nonatomic) UIActionSheet *actionSheet1;
@property (retain, nonatomic) UIActionSheet *actionSheet2;
@property (nonatomic, strong) LFSContent *contentItem;
@property (nonatomic, strong) NSMutableArray *mainContent;
@property (nonatomic, weak)LFSUser *user;

- (IBAction)cancelButton:(id)sender;



@end
