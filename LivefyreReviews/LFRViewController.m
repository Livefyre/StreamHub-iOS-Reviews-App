//
//  LFRViewController.m
//  LivefyreReviews
//
//  Created by sunil maganti on 6/8/14.
//  Copyright (c) 2014 Kvana Inc. All rights reserved.
//

#import "LFRViewController.h"
#import "LFRConfig.h"
#import <StreamHub-iOS-SDK/LFSClient.h>
#import "LFSTextField.h"
#import "LFSContent.h"
#import "LFSAttributedTextCell.h"
#import "LFSAttributedLabelDelegate.h"


@interface LFRViewController ()
@property (nonatomic, strong) LFSContentCollection *content;
@property (nonatomic, strong) LFSAttributedLabelDelegate *attributedLabelDelegate;

@end

static NSString* const kAttributedCellReuseIdentifier = @"LFSAttributedCell";

@implementation LFRViewController{
    
    
    CGPoint _scrollOffset;

}

#pragma mark - Properties
@synthesize content = _content;
@synthesize attributedLabelDelegate = _attributedLabelDelegate;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate=self;
    self.tableView.dataSource=self;
    LFRConfig *config = [[LFRConfig alloc] initwithValues];
    NSLog(@"%@",config.collections);
	// Do any additional setup after loading the view, typically from a nib.
    
    
    // {{{ Navigation bar
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    [navigationBar setBarStyle:UIBarStyleDefault];
    
    if (LFS_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(LFSSystemVersion70)) {
        [navigationBar setBackgroundColor:[UIColor clearColor]];
        [navigationBar setTranslucent:YES];
    }
    
    _scrollOffset = CGPointZero;

    CGFloat textFieldWidth =
    self.navigationController.navigationBar.frame.size.width -
    (LFS_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(LFSSystemVersion70) ? 32.f : 25.f);
    
    BOOL isPortrait = UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication]
                                                        statusBarOrientation]);
    UITextField *textField= [[LFSTextField alloc]
                         initWithFrame:
                         CGRectMake(0.f, 0.f, textFieldWidth, (isPortrait ? 30.f : 18.f))];
    
    [textField setDelegate:self];
    [textField setPlaceholder:@"Write a comment…"];
    
    
    UIBarButtonItem *writeCommentItem = [[UIBarButtonItem alloc]
                                         initWithCustomView:textField];
    [self setToolbarItems:
     [NSArray arrayWithObjects:writeCommentItem, nil]];
    
    UIToolbar *toolbar = self.navigationController.toolbar;
    [toolbar setBackgroundColor:[UIColor clearColor]];
    [toolbar setBarStyle:UIBarStyleDefault];
    if (LFS_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(LFSSystemVersion70))
    {
        // iOS7
        [toolbar setBackgroundColor:[UIColor clearColor]];
        [toolbar setTranslucent:YES];
    }
    else
    {
        // iOS6
        [toolbar setBarStyle:UIBarStyleDefault];
        //[toolbar setTintColor:[UIColor lightGrayColor]];
    }


}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(LFSAttributedLabelDelegate*)attributedLabelDelegate
{
    if (_attributedLabelDelegate == nil) {
        _attributedLabelDelegate = [[LFSAttributedLabelDelegate alloc] init];
        _attributedLabelDelegate.navigationController = self.navigationController;
    }
    return _attributedLabelDelegate;
}


#pragma mark - Toolbar behavior
-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self.navigationController
     setToolbarHidden:(scrollView.contentOffset.y <= _scrollOffset.y)
     animated:YES];
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                 willDecelerate:(BOOL)decelerate
{
    _scrollOffset = scrollView.contentOffset;
}

#pragma mark - UITextFieldDelegate

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    //[self createComment:textField];
    [textField resignFirstResponder];
    return NO;
}

#pragma mark - Table view data source

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
   
    return 100;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
     LFSContent *content = [_content objectAtIndex:indexPath.row];
     LFSContentVisibility visibility = LFSContentVisibilityEveryone;

    id returnedCell;
    
    
    if (visibility == LFSContentVisibilityEveryone)
    {
        LFSAttributedTextCell *cell = (LFSAttributedTextCell*)[tableView dequeueReusableCellWithIdentifier:kAttributedCellReuseIdentifier];
        
        if (!cell) {
            cell = [[LFSAttributedTextCell alloc]
                    initWithReuseIdentifier:kAttributedCellReuseIdentifier];
            [cell.bodyView setDelegate:self.attributedLabelDelegate];
        }
        //[self configureAttributedCell:cell forContent:content];
        returnedCell = cell;
    }
    else
    {
//        LFSDeletedCell *cell = (LFSDeletedCell *)[tableView dequeueReusableCellWithIdentifier:
//                                                  kDeletedCellReuseIdentifier];
//        if (!cell) {
//            cell = [[LFSDeletedCell alloc]
//                    initWithReuseIdentifier:kDeletedCellReuseIdentifier];
//            [cell.imageView setBackgroundColor:[UIColor colorWithRed:(217.f/255.f)
//                                                               green:(217.f/255.f)
//                                                                blue:(217.f/255.f)
//                                                               alpha:1.f]];
//            [cell.imageView setImage:[UIImage imageNamed:@"Trash"]];
//            [cell.imageView setContentMode:UIViewContentModeCenter];
//            [cell.textLabel setFont:[UIFont italicSystemFontOfSize:12.f]];
//            [cell.textLabel setTextColor:[UIColor lightGrayColor]];
//        }
//        [self configureDeletedCell:cell forContent:content];
//        returnedCell = cell;
    }
    
    return returnedCell;

}

@end
