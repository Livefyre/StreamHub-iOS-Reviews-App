//
//  LFRDetailViewController.h
//  LiveFyreReviewsIOS2
//
//  Created by kvana inc on 28/06/14.
//  Copyright (c) 2014 kvana inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LFSBasicHTMLParser.h"
#import "LFRDetailTableViewCell.h"
#import "LFSContent.h"
#import "LFSContentCollection.h"
#import "LFSUser.h"

@protocol LFRDetailTableViewCellDelegate;

@protocol Delete <NSObject>
-(void)postDestructiveMessage:(LFSMessageAction)message forContent:(LFSContent*)content;
-(void)featureContent:(LFSContent*)content;
-(void)banAuthorOfContent:(LFSContent*)content;
-(void)flagContent:(LFSContent*)content withFlag:(LFSContentFlag)flag;
-(void)editReviewOfContent:(LFSMessageAction)message forContent:(LFSContent*)content;

@end

@interface LFRDetailViewController : UIViewController<UITableViewDataSource,UITableViewDelegate,UIActionSheetDelegate>
@property (weak, nonatomic) id <Delete> deletedContent;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
 @property (nonatomic, copy) NSDictionary *collection;
@property (nonatomic, copy) NSString *collectionId;
@property (retain, nonatomic) UIActionSheet *actionSheet;
@property (retain, nonatomic) UIActionSheet *actionSheet1;
@property (retain, nonatomic) UIActionSheet *actionSheet2;
@property (nonatomic, strong) LFSContent *contentItem;
@property (nonatomic, strong) NSMutableArray *mainContent;
@property (nonatomic, retain) NSString *navigationHideen;
@property (nonatomic, weak)LFSUser *user;
@end
