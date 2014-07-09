//
//  LFRDetailViewController.m
//  LiveFyreReviewsIOS2
//
//  Created by kvana inc on 28/06/14.
//  Copyright (c) 2014 kvana inc. All rights reserved.
//

#import "LFRDetailViewController.h"
#import "LFRDetailTableViewCell.h"
#import "LFSContent.h"
#import <StreamHub-iOS-SDK/LFSClient.h>
#import "UIImage+LFSColor.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "LFRReplyViewController.h"
#import <StreamHub-iOS-SDK/LFSWriteClient.h>
#import <StreamHub-iOS-SDK/NSDateFormatter+RelativeTo.h>
#import "LFSContentCollection.h"


@interface LFRDetailViewController ()
@property (nonatomic, copy) NSMutableDictionary *contentDictionary;
@property (nonatomic, readonly) LFSWriteClient *writeClient;
@property (nonatomic, weak) LFSContentCollection *content1;
@end

@implementation LFRDetailViewController

const static CGFloat kGenerationOffset = 20.f;
 // hardcode author id for now
static NSString* const kCurrentUserId = @"_up19433660@livefyre.com";
- (id)initWithCoder:(NSCoder*)aDecoder
{
    if(self = [super initWithCoder:aDecoder])
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receiveTestNotification:)
                                                     name:@"ToDetail"
                                                   object:nil];
    }
    return self;
}
- (void) receiveTestNotification:(NSNotification *) notification
{
    // [notification name] should always be @"TestNotification"
    // unless you use this method for observation of other notifications
    // as well.
    
    if ([[notification name] isEqualToString:@"ToDetail"]){
        
        NSMutableArray *chaildContent=[[NSMutableArray alloc]init];
        [chaildContent addObject:[self.mainContent objectAtIndex:0]];
        LFSContent *rootContent=[self.mainContent objectAtIndex:0];
        for (int i=0; i<[[notification object] count]; i++) {
            LFSContent *singleContent=[[notification object] objectAtIndex:i];
            if ([singleContent.parentId isEqual:rootContent.idString]) {
                [chaildContent addObject:singleContent];
            }
        }
        _mainContent=nil;
        _mainContent=[[NSMutableArray alloc]initWithArray:chaildContent];
        _mainContent=chaildContent;
        [self.tableView reloadData];
    }
}

@synthesize writeClient = _writeClient;
- (LFSWriteClient*)writeClient
{
    if (_writeClient == nil) {
        NSString *network = [self.collection objectForKey:@"network"];
        NSString *environment = [self.collection objectForKey:@"environment"];
        _writeClient = [LFSWriteClient
                        clientWithNetwork:network
                        environment:environment];
    }
    return _writeClient;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate=self;
    self.tableView.dataSource=self;
    self.title=@"Review";
    self.contentDictionary=[[NSMutableDictionary alloc]initWithObjectsAndKeys:self.contentItem,@"content",nil];
    //self.navigationController.navigationBarHidden=YES;
     self.view.backgroundColor=UIColorFromRGB(0xF3F3F3);
   
    //[self.contentDictionary setObject:self.content forKey:@"content"];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
}
-(void)viewWillAppear:(BOOL)animated{
         [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    [self.navigationController setToolbarHidden:YES animated:YES];

     self.navigationController.navigationBarHidden=NO;
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    [navigationBar setBarStyle:UIBarStyleDefault];
    if (LFS_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(LFSSystemVersion70)) {
        self.navigationController.navigationBar.barTintColor = UIColorFromRGB(0xF3F3F3) ;
        [navigationBar setTranslucent:NO];
        self.navigationController.title=@"Review";
    }

}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
     // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
//    NSArray *sortedArray;
//    
//    sortedArray = [self.mainContent sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
//        NSDate *first = [(LFSContent*)a updatedAt];
//        NSDate *second=[(LFSContent*)b updatedAt];
//        return [second compare:first];
//    }];
//    
//    [self.mainContent removeAllObjects];
    [self.mainContent insertObject:self.contentItem atIndex:0];
//    [self.mainContent addObjectsFromArray:sortedArray];
    return [self.mainContent count];
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    LFSContent *contentValues = [self.mainContent objectAtIndex:indexPath.row];

    if ([contentValues.parentId isEqualToString:@""]) {
        
        LFRDetailTableViewCell *cell=[[LFRDetailTableViewCell alloc]init];
    
    NSMutableAttributedString *attributedTitle=[cell getAttributedTextWithFormat:contentValues.title :24 :@"Georgia" :14];
    CGSize titleSize = [attributedTitle sizeConstrainedToSize:CGSizeMake(290, CGFLOAT_MAX)];
    
    NSMutableAttributedString *attributedbody=[cell getAttributedTextWithFormat:contentValues.bodyHtml :18 :@"Georgia" :5];
    CGSize bodySize = [attributedbody sizeConstrainedToSize:CGSizeMake(290, CGFLOAT_MAX)];
        return titleSize.height+137+bodySize.height;
    }
    else{
        LFRDetailTableViewCell *cell=[[LFRDetailTableViewCell alloc]init];
        
        NSMutableAttributedString *attributedbody=[cell getAttributedTextWithFormat:contentValues.bodyHtml :18 :@"Georgia" :5];
        CGSize bodySize = [attributedbody sizeConstrainedToSize:CGSizeMake(290, CGFLOAT_MAX)];
        return 91+bodySize.height;
    }
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    LFSContent *contentValues = [self.mainContent objectAtIndex:indexPath.row];

  static NSString *cellIdentifier = @"ConfigureCell";
    LFRDetailTableViewCell *cell=nil;
    //(LFRDetailTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
  
        if (cell == nil) {
            cell = [[LFRDetailTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        }
            if ([contentValues.parentId isEqualToString:@""]) {
                 [self configureAttributedCell:cell forContent:contentValues];
            }
            else{
                [self configureAttributedCell1:cell forContent:contentValues];
            }
     

    return cell;
}
- (void)configureAttributedCell:(LFRDetailTableViewCell*)cell forContent:(LFSContent*)content
{
    //profile image
    UIImage *placeholder=[UIImage imageWithColor:
                          [UIColor colorWithRed:232.f / 255.f
                                          green:236.f / 255.f
                                           blue:239.f / 255.f
                                          alpha:1.f]];
    
    //setting profile pic
    [cell.profileImage  setImageWithURL:[NSURL URLWithString:content.author.avatarUrlString75]
                       placeholderImage:placeholder];
    //user name
    cell.userName.text=content.author.displayName ?: @"";
    
    //if moderator
    if (content.authorIsModerator) {
        cell.moderator.text=@"Moderator";
        cell.moderator.frame=CGRectMake(73,10, 80, 18);
    }
    else{
        cell.moderator.text=nil;
    }
    if (content.isFeatured){
        cell.featuredImage.frame=CGRectMake(73,10, 80, 18);
        cell.featuredImage.image=[UIImage imageNamed:@"Featured"];
    }
    else{
        cell.featuredImage.image=nil;
    }
    
    
    
    //    ////if self
    if (content.authorId) {
        cell.moderator.frame=CGRectMake(73,8, 80, 18);
        cell.moderator.text=@"";
//        heightForModeFeat=10;
        cell.featuredImage.frame=CGRectMake(73,8, 80, 18);
        cell.featuredImage.image=[UIImage imageNamed:@"Featured"];
    }else if (content.isFeatured){
        cell.featuredImage.frame=CGRectMake(73,10, 80, 18);
        cell.featuredImage.image=[UIImage imageNamed:@"Featured"];
    }
    
    
    
    //rating
    [cell.rateView
     setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin)];
    [cell.rateView setBackgroundColor:[UIColor clearColor]];
    NSNumber *rating=[[content.annotations objectForKey:@"rating"] objectAtIndex:0];
    [cell.rateView setRate:[rating floatValue]/20];
    
    //helpful
    int count=0;
    NSArray *votes=[[NSArray alloc]initWithArray:[content.annotations objectForKey:@"vote" ]];
    for (NSDictionary *voteObject in votes) {
        if ([[voteObject valueForKey:@"value"] integerValue] ==1) {
            count++;
        }[voteObject valueForKey:@"value"];
    }
    
    cell.footerLeftView.text=[NSString stringWithFormat:@"%d of %lu found helpful",count,(unsigned long)[[content.annotations valueForKey:@"vote"] count]] ;
    cell.footerLeftView.frame=CGRectMake(160,41, 180, 20);
    
    //date
    NSDateFormatter *format=[[NSDateFormatter alloc]init];
    cell.date.text = [format relativeStringFromDate:content.createdAt];
    CGSize textSize1 = [[cell.date text] sizeWithAttributes:@{NSFontAttributeName:[cell.date font]}];
    cell.date.frame=CGRectMake(320-textSize1.width-15, 10, 55, 15);
    
    //title
    NSString *text = content.title
    ? content.title:@"";
    NSMutableAttributedString *attributedTitle=[cell getAttributedTextWithFormat:text :24.0f :@"Georgia" :14];
    [cell.title setAttributedText:attributedTitle];
    CGSize titleSize = [attributedTitle sizeConstrainedToSize:CGSizeMake(290, CGFLOAT_MAX)];
    cell.title.frame=CGRectMake(15, 68, 290, titleSize.height);
    
    //body
    NSMutableAttributedString *attributedBody=[ cell getAttributedTextWithFormat:content.bodyHtml :18.0f :@"Georgia" :5];
    [cell.body setAttributedText:attributedBody];
    CGSize bodySize = [attributedBody sizeConstrainedToSize:CGSizeMake(290, CGFLOAT_MAX)];
    cell.body.frame=CGRectMake(15, 63+cell.title.frame.size.height+10, 290, bodySize.height);
    
    
    [cell.button1 setImage:[UIImage imageNamed:@"icon_heart_initial"]
                  forState:UIControlStateNormal];
    [cell.button1 setTitle:@"Helpful"
                  forState:UIControlStateNormal];
    [cell.button1 addTarget:self action:@selector(didSelectButton1:)
           forControlEvents:UIControlEventTouchUpInside];
    cell.button1.frame=CGRectMake(10, 63+cell.title.frame.size.height+cell.body.frame.size.height, 100, 100);

    
    [cell.button2 setImage:[UIImage imageNamed:@"ActionReply"]
                  forState:UIControlStateNormal];
    [cell.button2 setTitle:@"Reply"
                  forState:UIControlStateNormal];
    [cell.button2 addTarget:self action:@selector(didSelectButton2:content:)
           forControlEvents:UIControlEventTouchUpInside];
    cell.button2.frame=CGRectMake(cell.button1.frame.size.width+15, 63+cell.title.frame.size.height+cell.body.frame.size.height, 100, 100);
 
    
    [cell.button3 setImage:[UIImage imageNamed:@"More"]
                  forState:UIControlStateNormal];
    [cell.button3 setTitle:@"More"
                  forState:UIControlStateNormal];
    [cell.button3 addTarget:self action:@selector(didSelectButton3:)
           forControlEvents:UIControlEventTouchUpInside];
    cell.button3.frame=CGRectMake(cell.button1.frame.size.width+15+cell.button2.frame.size.width, 63+cell.title.frame.size.height+cell.body.frame.size.height, 100, 100);
    [cell layoutsets];
  
}
- (void)configureAttributedCell1:(LFRDetailTableViewCell*)cell forContent:(LFSContent*)content
{
    //((CGFloat)([content.datePath count] - 1) * kGenerationOffset
    float dateCount;
    
    if([content.datePath count] <=6){
        dateCount=([content.datePath count] - 2)* kGenerationOffset;
    }
    else{
        dateCount=4*kGenerationOffset;
    }
    //profile image
    UIImage *placeholder=[UIImage imageWithColor:
                          [UIColor colorWithRed:232.f / 255.f
                                          green:236.f / 255.f
                                           blue:239.f / 255.f
                                          alpha:1.f]];
    
    //setting profile pic
    [cell.profileImage  setImageWithURL:[NSURL URLWithString:content.author.avatarUrlString75]
                       placeholderImage:placeholder];
    [cell.profileImage setFrame:CGRectMake(15+dateCount, 10, 28, 28)];
    //user name
    cell.userName.text=content.author.displayName ?: @"";
    
    
    cell.userName.frame=CGRectMake(51+dateCount, 8, 200, 16);
    CGSize headerTestSize = [[cell.userName text] sizeWithAttributes:@{NSFontAttributeName:[cell.userName font]}];
    CGFloat headerStrikeWidth = headerTestSize.width;
        //if moderator
        if (content.authorIsModerator) {
            cell.moderator.text=@"Moderator";
            cell.moderator.frame=CGRectMake(headerStrikeWidth+10+cell.userName.frame.origin.x,8, 80, 18);
        }
        else{
            cell.moderator.text=nil;
        }
        if (content.isFeatured){
            cell.featuredImage.frame=CGRectMake(headerStrikeWidth+10+cell.userName.frame.origin.x,8, 80, 18);
            cell.featuredImage.image=[UIImage imageNamed:@"Featured"];
        }
        else{
        cell.featuredImage.image=nil;
        }
    //rating
    cell.rateView.frame=CGRectMake(0, 0, 0, 0);
    
    //helpful
    int count=0;
    NSArray *votes=[[NSArray alloc]initWithArray:[content.annotations objectForKey:@"vote" ]];
    for (NSDictionary *voteObject in votes) {
        if ([[voteObject valueForKey:@"value"] integerValue] ==1) {
            count++;
        }[voteObject valueForKey:@"value"];
    }
    
    cell.footerLeftView.text=[NSString stringWithFormat:@"%d of %lu found helpful",count,(unsigned long)[[content.annotations valueForKey:@"vote"] count]] ;
    cell.footerLeftView.frame=CGRectMake(51+dateCount,26,150,14);
    
    //date
    NSDateFormatter *format=[[NSDateFormatter alloc]init];
    cell.date.text = [format relativeStringFromDate:content.createdAt];
    CGSize textSize1 = [[cell.date text] sizeWithAttributes:@{NSFontAttributeName:[cell.date font]}];
    cell.date.frame=CGRectMake(320-textSize1.width-15, 10, 55, 15);
    
    //body
    NSMutableAttributedString *attributedBody=[ cell getAttributedTextWithFormat:content.bodyHtml :18.0f :@"Georgia" :5];
    [cell.body setAttributedText:attributedBody];
    CGSize bodySize = [attributedBody sizeConstrainedToSize:CGSizeMake(290, CGFLOAT_MAX)];

    cell.body.frame=CGRectMake(15+dateCount, 48, 290-dateCount, bodySize.height);

        [cell.button1 setImage:[UIImage imageNamed:@"icon_heart_initial"]
                  forState:UIControlStateNormal];
    [cell.button1 setTitle:@""
                  forState:UIControlStateNormal];
    [cell.button1 addTarget:self action:@selector(didSelectButton1:)
           forControlEvents:UIControlEventTouchUpInside];
    
    cell.button1.frame=CGRectMake(10+dateCount, 23+cell.body.frame.size.height, 50, 100);
    [cell addSubview:cell.button1];
    
    [cell.button2 setImage:[UIImage imageNamed:@"ActionReply"]
                  forState:UIControlStateNormal];
    [cell.button2 setTitle:@""
                  forState:UIControlStateNormal];
    [cell.button2 addTarget:self action:@selector(didSelectButton2:content:) forControlEvents:UIControlEventTouchUpInside];
    cell.button2.frame=CGRectMake(cell.button1.frame.origin.x+cell.button1.frame.size.width+15, 23+cell.body.frame.size.height, 50, 100);
    [cell addSubview:cell.button2];
    
    [cell.button3 setImage:[UIImage imageNamed:@"More"]
                  forState:UIControlStateNormal];
    [cell.button3 setTitle:@""
                  forState:UIControlStateNormal];
    [cell.button3 addTarget:self action:@selector(didSelectButton3:)
           forControlEvents:UIControlEventTouchUpInside];
    cell.button3.frame=CGRectMake(cell.button2.frame.origin.x+cell.button2.frame.size.width+15, 23+cell.title.frame.size.height+cell.body.frame.size.height, 100, 100);
    [cell addSubview:cell.button3];
    
    
    CAShapeLayer *line5=[self drawline:CGPointMake(dateCount+10, 43+cell.body.frame.size.height+cell.body.frame.origin.y) :CGPointMake(320,43+cell.body.frame.size.height+cell.body.frame.origin.y)];
    [cell.layer addSublayer:line5];
    
    //    CGFloat leftDistence=((CGFloat)([content.datePath count] - 2) * kGenerationOffset);
    //    [cell layoutsetsForSubcell:&leftDistence];
    
}
-(CAShapeLayer*)drawline:(CGPoint)from :(CGPoint)to{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:from];
    [path addLineToPoint:to];
    
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.path = [path CGPath];
    shapeLayer.strokeColor = [[UIColor grayColor] CGColor];
    shapeLayer.lineWidth = 0.1;
    shapeLayer.fillColor = [[UIColor grayColor] CGColor];
    
    //[self.layer addSublayer:shapeLayer];
    return shapeLayer;
}
- (void)didSelectButton1:(id)sender
{
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    NSLog(@" Index path is %ld",(long)indexPath.row);
    
    self.actionSheet=[[UIActionSheet alloc]initWithTitle:@"Was this helpful?" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Yes" otherButtonTitles:@"No", nil];
         self.actionSheet.destructiveButtonIndex=1;
        [ self.actionSheet showInView:self.view];
}



-(void)didSelectButton2:(id)sender content:(id)content  {
    
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    LFRReplyViewController *replyViewController = [storyboard instantiateViewControllerWithIdentifier:@"ReplyViewController"];
    
    NSSet *touches = [content allTouches];
    UITouch *touch = [touches anyObject];
    
    CGPoint currentTouchPosition = [touch locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint: currentTouchPosition];
    
    replyViewController.collectionId=self.collectionId;
    replyViewController.collection=self.collection;
    replyViewController.replyToContent=[self.mainContent objectAtIndex:indexPath.row];
    [self presentViewController:replyViewController animated:YES completion:nil];
    
    
}
-(void)didSelectButton3:(id)sender{
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    self.contentItem =[self.mainContent objectAtIndex:indexPath.row];
    
    if ([self.user.permissions objectForKey:@"moderator_key"] && self.contentItem.authorIsModerator) {
        self.actionSheet1=[[UIActionSheet alloc]initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete" otherButtonTitles:@"Edit",@"Feature",nil];
    }
    else if([self.user.permissions objectForKey:@"moderator_key"]){
        self.actionSheet1=[[UIActionSheet alloc]initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete" otherButtonTitles:@"Ban User",@"Bozo",@"Edit",@"Feature",@"Flag",nil];
    }
    else if([self.user.idString isEqualToString:self.contentItem.author.idString]){
        self.actionSheet1=[[UIActionSheet alloc]initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete" otherButtonTitles:@"Edit",nil];
    }
    else{
        self.actionSheet1=[[UIActionSheet alloc]initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Flag",nil];
        
    }
    [ self.actionSheet1 showInView:self.view];
    
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
//    id<LFSContentActionsDelegate> delegate = self.delegate;
    //static NSString* const kFailureModifyTitle = @"Action Failed";
    

    // Get the name of the button pressed
    NSString *action = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    if (actionSheet == self.actionSheet) {
        
        if ([action isEqualToString:@"Yes"])
        {
            NSString *userToken = [self.collection objectForKey:@"lftoken"];
                if (userToken != nil) {
                    LFSMessageAction action;
                    action = LFSMessageVote;
                    
                    
//                    NSDictionary *parameters=[[NSDictionary alloc]initWithObjectsAndKeys:@1,@"value", nil];
                NSMutableDictionary *dict=[[NSMutableDictionary alloc]initWithObjectsAndKeys:userToken,LFSCollectionPostUserTokenKey,@1,@"value",self.contentItem.idString,@"message_id",nil ];
                    
                    LFRDetailTableViewCell *detailCell=[[LFRDetailTableViewCell alloc]init];
                    [detailCell.button1 setImage:[UIImage imageNamed:@"StateLiked"] forState:UIControlStateNormal];
                    
//                [self.writeClient postMessage:action
//                forContent:self.contentItem.idString
//                inCollection:self.collectionId
//                userToken:userToken
//                parameters:parameters
//                onSuccess:^(NSOperation *operation, id responseObject)
//                 {
//                     NSLog(@"success posting opine %d", action);
//                 }
//                onFailure:^(NSOperation *operation, NSError *error)
//                 {
//                     NSLog(@"failed posting opine %d", action);
//                 }];
                    
                    [self.writeClient postMessage:action
                                       forContent:self.contentItem.idString
                                     inCollection:self.collectionId
                                        userToken:userToken
                                       parameters:dict
                                        onSuccess:^(NSOperation *operation, id responseObject) {
//                                            if ([collectionViewController respondsToSelector:@selector(didPostContentWithOperation:response:)])
//                                            {
//                                                [collectionViewController didPostContentWithOperation:operation response:responseObject];
//                                            }
                                       
                                        } onFailure:^(NSOperation *operation, NSError *error) {
                                            [[[UIAlertView alloc]
                                              initWithTitle:@"Livefyre Reviews says:"
                                              message:[error localizedRecoverySuggestion]
                                              delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil] show];
                                        }];                     
                }
            
                else {
                    // userToken is nil -- show an error message
                    [[[UIAlertView alloc]
                      initWithTitle:@"Livefyre Reviews says:"
                      message:@"You do not have permission to like comments in this collection"
                      delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
                }

            
        }
        else if ([action isEqualToString:@"No"])
      {
          NSString *userToken = [self.collection objectForKey:@"lftoken"];
          if (userToken != nil) {
              LFSMessageAction action;
              action = LFSMessageVote;
              
              LFRDetailTableViewCell *detailCell=[[LFRDetailTableViewCell alloc]init];
              [detailCell.button1 setImage:[UIImage imageNamed:@"StateNotLiked"] forState:UIControlStateNormal];
              NSDictionary *parameters=[[NSDictionary alloc]initWithObjectsAndKeys:@2,@"value", nil];
              
              
              [self.writeClient postMessage:action
                                 forContent:self.contentItem.idString
                               inCollection:self.collectionId
                                  userToken:userToken
                                 parameters:parameters
                                  onSuccess:^(NSOperation *operation, id responseObject)
               {
                   NSLog(@"success posting opine %d", action);
               }
                                  onFailure:^(NSOperation *operation, NSError *error)
               {
                   NSLog(@"failed posting opine %d", action);
               }];
              
          }
          
          else {
              // userToken is nil -- show an error message
              [[[UIAlertView alloc]
                initWithTitle:@"Livefyre Reviews says:"
                message:@"You do not have permission to like comments in this collection"
                delegate:nil
                cancelButtonTitle:@"OK"
                otherButtonTitles:nil] show];
          }
          
        }
        else if ([action isEqualToString:@"Cancel"])
        {
            // do nothing
        }
    }
    else if (actionSheet == self.actionSheet1) {
             if  ([action isEqualToString:@"Delete"])
            {
                if ([self.deletedContent respondsToSelector:@selector(postDestructiveMessage:forContent:)]) {
                    [self.deletedContent postDestructiveMessage:LFSMessageDelete forContent:self.contentItem];
                    [self.navigationController popToRootViewControllerAnimated:YES];
                }
            }
            else if ([action isEqualToString:@"Ban User"])
            {
                [self.deletedContent banAuthorOfContent:self.contentItem];
                 [self.navigationController popToRootViewControllerAnimated:YES];
             }
            else if ([action isEqualToString:@"Bozo"])
            {
                if ([self.deletedContent respondsToSelector:@selector(postDestructiveMessage:forContent:)]) {
                    [self.deletedContent postDestructiveMessage:LFSMessageBozo forContent:self.contentItem];
                    [self.navigationController popToRootViewControllerAnimated:YES];
                }
            }
            else if ([action isEqualToString:@"Edit"])
            {
                if ([self.deletedContent respondsToSelector:@selector(editReviewOfContent:forContent:)]) {
                    [self.deletedContent editReviewOfContent:LFSMessageEdit forContent:self.contentItem];
//                    [self.navigationController popToRootViewControllerAnimated:YES];
                }
            }
            else if ([action isEqualToString:@"Feature"])
            {
                [self.deletedContent featureContent:self.contentItem];

            }
            else if ([action isEqualToString:@"Flag"])
            {
                
                self.actionSheet2=[[UIActionSheet alloc]initWithTitle:@"Flag Comment" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Spam" otherButtonTitles:@"Offensive",@"Off-Topic",@"Disagree",nil];
                
                [ self.actionSheet2 showInView:self.view];

             }
            else if ([action isEqualToString:@"Cancel"])
            {
                // do nothing
            }

    }
    
    else if(actionSheet == self.actionSheet2){
        if ([self.deletedContent respondsToSelector:@selector(flagContent:withFlag:)]) {
            if  ([action isEqualToString:[LFSContentFlags[LFSFlagSpam] capitalizedString]])
            {
                [self.deletedContent flagContent:self.contentItem withFlag:LFSFlagSpam];
            }
            else if ([action isEqualToString:[LFSContentFlags[LFSFlagOffensive] capitalizedString]])
            {
                [self.deletedContent flagContent:self.contentItem withFlag:LFSFlagOffensive];
            }
            else if ([action isEqualToString:[LFSContentFlags[LFSFlagOfftopic] capitalizedString]])
            {
                [self.deletedContent flagContent:self.contentItem withFlag:LFSFlagOfftopic];
            }
            else if ([action isEqualToString:[LFSContentFlags[LFSFlagDisagree] capitalizedString]])
            {
                [self.deletedContent flagContent:self.contentItem withFlag:LFSFlagDisagree];
            }
            else if ([action isEqualToString:@"Cancel"])
            {
                // do nothing
            }
        }
    }
}
@end
