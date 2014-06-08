//
//  LFRViewController.h
//  LivefyreReviews
//
//  Created by sunil maganti on 6/8/14.
//  Copyright (c) 2014 Kvana Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LFRViewController : UIViewController <UITableViewDataSource,UITableViewDelegate,UITextFieldDelegate>
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end
