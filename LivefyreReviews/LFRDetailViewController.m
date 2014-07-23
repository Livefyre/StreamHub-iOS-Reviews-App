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
#import "TSMessage.h"
#import "LFSDeletedCell.h"

@interface LFRDetailViewController ()
@property (nonatomic, readonly) LFSWriteClient *writeClient;
@property (nonatomic, weak) LFSContentCollection *content1;
@property (nonatomic, weak)LFSContent *contentItem_clicked;
@end

@implementation LFRDetailViewController{
    int updateCount;
    int oldCount;
    BOOL isAlertAdded;
}

const static CGFloat kGenerationOffset = 20.f;
static NSString* const kDeletedCellReuseIdentifier = @"LFSDeletedCell";
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
    [TSMessage dismissActiveNotification];
    if ([[notification name] isEqualToString:@"ToDetail"]){
        NSMutableArray *hash=[[NSMutableArray alloc]init];//=content.children;

        LFSContentCollection *contentCollection=[[notification object]objectAtIndex:0];
         self.chaildContent=[[NSMutableArray alloc]init];
//        [chaildContent addObject:self.contentItem];
        LFSContent *singleContent;
        for (int i=0; i<[contentCollection count]; i++) {
            singleContent=[contentCollection objectAtIndex:i];
            LFSContentVisibility visibility=singleContent.visibility;
            if ([singleContent.idString isEqual:self.contentItem.idString] && visibility==LFSContentVisibilityEveryone) {
                //NSMutableArray *test=[[NSMutableArray alloc]init];
                NSEnumerator *enumerator = [singleContent.children objectEnumerator];
                id value;
                while ((value = [enumerator nextObject])) {
                    /* code that acts on the hash table's values */
                    if([value isKindOfClass:[LFSContent class]])
                    {
                        if( ((LFSContent*)value).bodyHtml ){
                            [hash addObject:value];
                            
                        }
                    }
                }
                NSSortDescriptor *lowestToHighest = [NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:YES];
                [hash sortUsingDescriptors:[NSMutableArray arrayWithObject:lowestToHighest]];
                
                
                for (int i=0; i<hash.count; i++) {
                    LFSContent *content=[hash objectAtIndex:i];
                    if (content.children) {
                        NSMutableArray *temp=[self recursiveChilds:content.children];
                        for (int j=0,index=0; temp.count>j; j++) {
                            //                            LFSContentVisibility tempContentVisibility=((LFSContent *)[temp objectAtIndex:j]).visibility;
                            //                            if (tempContentVisibility==LFSContentVisibilityEveryone) {
                            [hash insertObject:[temp objectAtIndex:index] atIndex:index+i+1];
                            index++;
                            //                            }
                            
                        }
                    }
                }
                [self.chaildContent addObject:singleContent];
                [self.chaildContent addObjectsFromArray:hash];
                break;
            }
        }
        
        NSArray *deletes=[[notification object]objectAtIndex:2];
        NSArray *updates=[[notification object]objectAtIndex:3];

        if (deletes.count>0 || updates.count) {
            [self.tableView reloadData];
        }
        
        NSArray *inserts=[[notification object]objectAtIndex:1];
        if (inserts.count>0) {
            
            for (NSIndexPath *value in inserts) {
                LFSContent *content =[contentCollection objectAtIndex:value.row];
                if ([content.author.idString isEqualToString:self.user.idString]) {
                    _mainContent=nil;
                    _mainContent=[[NSMutableArray alloc]initWithArray:self.chaildContent];
                    NSMutableArray *temp=[[NSMutableArray alloc]initWithArray:self.chaildContent];
                    
                    NSSortDescriptor *lowestToHighest = [NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:YES];
                    [temp sortUsingDescriptors:[NSMutableArray arrayWithObject:lowestToHighest]];
                    LFSContent *tempContent=[temp objectAtIndex:temp.count-1];
                    
                    NSInteger indexpath=[_mainContent indexOfObject:tempContent ];
                    
                    
                    [self.tableView reloadData];
                    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:indexpath inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
                }
            }
        }
        if (hash.count >_mainContent.count-1 && !isAlertAdded ) {
          
            updateCount =hash.count -_mainContent.count+1;
            [_mainContent insertObject:@"Alert Notification" atIndex:1];
            isAlertAdded=YES;

            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:1
                                                        inSection:0];
            [self.tableView beginUpdates];
            [self.tableView insertRowsAtIndexPaths:[[NSArray alloc]initWithObjects:indexPath, nil] withRowAnimation:UITableViewRowAnimationMiddle];
            [self.tableView endUpdates];
//            [self.tableView reloadData];
            
        }
        else if ((hash.count >_mainContent.count-1 && isAlertAdded)){
            updateCount =hash.count -_mainContent.count+2;
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:1
                                                        inSection:0];
            [self.tableView beginUpdates];
            [self.tableView reloadRowsAtIndexPaths:[[NSArray alloc]initWithObjects:indexPath, nil] withRowAnimation:UITableViewRowAnimationMiddle];
            [self.tableView endUpdates];

        }
        
        else if (hash.count <_mainContent.count-1){
            
            _mainContent=nil;
            _mainContent=[[NSMutableArray alloc]initWithArray:self.chaildContent];
            isAlertAdded=NO;
            [self.tableView reloadData];
            
            
        }
 //        _mainContent=nil;
//        _mainContent=[[NSMutableArray alloc]initWithArray:chaildContent];
        
//        if (singleContent != nil) {
//        updateCount=(int)(singleContent.children.count-oldCount);
//        if (updateCount<0) {
//            updateCount=0;
//            oldCount=(int)[_mainContent count];
//        }
//        }
//
//        NSArray *inserts=[[notification object]objectAtIndex:1];
//          if (inserts.count>0) {
//              
//            for (NSIndexPath *value in inserts) {
//                LFSContent *content =[contentCollection objectAtIndex:value.row];
//                if ([content.author.idString isEqualToString:self.user.idString]) {
//                    _mainContent=nil;
//                    _mainContent=[[NSMutableArray alloc]initWithArray:self.chaildContent];
//                
//                }
//                else{
//                    [_mainContent insertObject:@"Alert Notification" atIndex:1];
//                    isAlertAdded=YES;
//                          [self.tableView reloadData];
//                  //  updateCount=(int)(singleContent.children.count-oldCount);
////                    if (updateCount<0) {
////                    updateCount=0;
////                    oldCount=(int)[_mainContent count];
////                    }
//                }
//                
//            }
//        }
//          else{
//              _mainContent=nil;
//              _mainContent=[[NSMutableArray alloc]initWithArray:self.chaildContent];
//                    [self.tableView reloadData];
//              
//          }
   
    }
}


-(NSMutableArray*)recursiveChilds:(NSHashTable*)hashtable {
    NSMutableArray *test=[[NSMutableArray alloc]init];
    NSEnumerator *enumerator = [hashtable objectEnumerator];
    id value;
    while ((value = [enumerator nextObject])) {
        /* code that acts on the hash table's values */
        if([value isKindOfClass:[LFSContent class]])
        {
//            LFSContentVisibility visibility = ((LFSContent*)value).visibility;
            
            //            if( ((LFSContent*)value).bodyHtml && visibility==LFSContentVisibilityEveryone ){
            [test addObject:value];
            
            //            }
            
        }
        
    }
    NSSortDescriptor *lowestToHighest = [NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:YES];
    [test sortUsingDescriptors:[NSMutableArray arrayWithObject:lowestToHighest]];
    return test;
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
    isAlertAdded=NO;
//    _update=NO;
    oldCount= (int)self.contentItem.children.count ;
    updateCount=1;
    self.navigationController.navigationBar.barTintColor = UIColorFromRGB(0xF3F3F3) ;

    //self.navigationController.navigationBarHidden=YES;
     self.view.backgroundColor=UIColorFromRGB(0xF3F3F3);
   
}
-(void)viewWillAppear:(BOOL)animated{
         [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
//    if ([self.navigationHideen isEqualToString:@"YES"]) {
//        self.view.backgroundColor= UIColorFromRGB(0xF3F3F3);
//        CGRect screenRect = [[UIScreen mainScreen] bounds];
//        CGFloat screenHeight = screenRect.size.height;
//        [self.tableView setFrame:CGRectMake(0, 60, 320, screenHeight-60)];
//        UINavigationBar *navBar = [[UINavigationBar alloc] init];
//        [navBar setFrame:CGRectMake(0,20,CGRectGetWidth(self.view.frame),44)];
//        [self.view addSubview: navBar];
//        UIButton *cancelButton=[[UIButton alloc]initWithFrame:CGRectMake(15, 6,60,40)];
//        [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
//        [cancelButton setTitleColor:UIColorFromRGB(0x0F98EC) forState:UIControlStateNormal];
//        [cancelButton addTarget:self action:@selector(cancelClicked:) forControlEvents:UIControlEventTouchUpInside];
//        [navBar addSubview:cancelButton];
//        UILabel *review=[[UILabel alloc]initWithFrame:CGRectMake(130, 6, 60, 40)];
//        [review setText:@"Review"];
//        [navBar addSubview:review];
//
//      }
//    else{
    isAlertAdded=NO;
    self.navigationController.navigationBar.barTintColor = UIColorFromRGB(0xF3F3F3) ;
    [self.navigationController setToolbarHidden:YES animated:YES];
    self.navigationController.navigationBarHidden=NO;
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    [navigationBar setBarStyle:UIBarStyleDefault];
    if (LFS_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(LFSSystemVersion70)) {
        self.navigationController.navigationBar.barTintColor = UIColorFromRGB(0xF3F3F3) ;
        [navigationBar setTranslucent:NO];
        self.navigationController.title=@"Review";
     }
//    }

}

- (IBAction)cancelClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
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
//    [self.mainContent insertObject:self.contentItem atIndex:0];
    
    if (self.mainContent.count ==0) {
        UIView *contentView=[[UIView alloc]initWithFrame:CGRectMake(15, 70, 290, 100)];
        UILabel *contentLable=[[UILabel alloc]initWithFrame:CGRectMake(0, 0, 280, 80)];
        contentLable.numberOfLines=2;
        contentLable.text=@"The Content you are looking for is no longer available.";
        [contentLable setFont:[UIFont fontWithName:@"georgia" size:18]];
        [contentView addSubview:contentLable];
        UIButton *cancelButton=[[UIButton alloc]initWithFrame:CGRectMake(90,60,100,80)];
        [cancelButton setTitle:@"Go Back" forState:UIControlStateNormal];
        [cancelButton setTitleColor:UIColorFromRGB(0x0F98EC) forState:UIControlStateNormal];
        [cancelButton addTarget:self action:@selector(clickBack:) forControlEvents:UIControlEventTouchUpInside];
        [contentView addSubview:cancelButton];
        [self.view addSubview:contentView];
        
    }
     return [self.mainContent count];
    
}
-(void)clickBack:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if ([[_mainContent objectAtIndex:indexPath.row] isKindOfClass:[LFSContent class]] ){
        
        LFSContent *contentValues = [self.mainContent objectAtIndex:indexPath.row];
        LFSContentVisibility visibility = contentValues.visibility;

     if ([contentValues.parentId isEqualToString:@""] && visibility == LFSContentVisibilityEveryone){
        LFRDetailTableViewCell *cell=[[LFRDetailTableViewCell alloc]init];
        
        NSMutableAttributedString *attributedTitle=[cell getAttributedTextWithFormat:contentValues.title :24 :@"Georgia" :14];
        CGSize titleSize = [attributedTitle sizeConstrainedToSize:CGSizeMake(290, CGFLOAT_MAX)];
        
        NSMutableAttributedString *attributedbody=[cell getAttributedTextWithFormat:contentValues.bodyHtml :18 :@"Georgia" :5];
        CGSize bodySize = [attributedbody sizeConstrainedToSize:CGSizeMake(290, CGFLOAT_MAX)];
         if (!contentValues.firstOembed) {

        return titleSize.height+137+bodySize.height;
         }
         else{
             
           return titleSize.height+357+bodySize.height;
         }
     
     }
    else if(visibility == LFSContentVisibilityEveryone){
        LFRDetailTableViewCell *cell=[[LFRDetailTableViewCell alloc]init];
        NSMutableAttributedString *attributedbody=[cell getAttributedTextWithFormat:contentValues.bodyHtml :18 :@"Georgia" :5];
        CGSize bodySize = [attributedbody sizeConstrainedToSize:CGSizeMake(290, CGFLOAT_MAX)];
        return 91+bodySize.height;
    }
    else {
        
        return 40;
    }
    }else{
        return 60;
    }

}
//- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath{
//    
//    if ([[_mainContent objectAtIndex:indexPath.row] isKindOfClass:[LFSContent class]] && isAlertAdded){
//        
//        LFSContent *contentValues = [self.mainContent objectAtIndex:indexPath.row];
//        LFSContentVisibility visibility = contentValues.visibility;
//        
//        if ([contentValues.parentId isEqualToString:@""] && visibility == LFSContentVisibilityEveryone){
//            LFRDetailTableViewCell *cell=[[LFRDetailTableViewCell alloc]init];
//            
//            NSMutableAttributedString *attributedTitle=[cell getAttributedTextWithFormat:contentValues.title :24 :@"Georgia" :14];
//            CGSize titleSize = [attributedTitle sizeConstrainedToSize:CGSizeMake(290, CGFLOAT_MAX)];
//            
//            NSMutableAttributedString *attributedbody=[cell getAttributedTextWithFormat:contentValues.bodyHtml :18 :@"Georgia" :5];
//            CGSize bodySize = [attributedbody sizeConstrainedToSize:CGSizeMake(290, CGFLOAT_MAX)];
//            return titleSize.height+137+bodySize.height;
//        }
//        else if(visibility == LFSContentVisibilityEveryone){
//            LFRDetailTableViewCell *cell=[[LFRDetailTableViewCell alloc]init];
//            NSMutableAttributedString *attributedbody=[cell getAttributedTextWithFormat:contentValues.bodyHtml :18 :@"Georgia" :5];
//            CGSize bodySize = [attributedbody sizeConstrainedToSize:CGSizeMake(290, CGFLOAT_MAX)];
//            return 91+bodySize.height;
//        }
//        else {
//            
//            return 40;
//        }
//    }else{
//        
//        return 60;
//    }
//    
//}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *cellIdentifier = @"ConfigureCell";
    LFRDetailTableViewCell *cell=nil;
    //(LFRDetailTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
  
    
       if([[_mainContent objectAtIndex:indexPath.row] isKindOfClass:[LFSContent class]]){
           LFSContent *contentValues = [self.mainContent objectAtIndex:indexPath.row];


        LFSContentVisibility visibility = contentValues.visibility;
    if (visibility == LFSContentVisibilityEveryone)
    {
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
    else
    {
        
        LFSDeletedCell *cell = (LFSDeletedCell *)[tableView dequeueReusableCellWithIdentifier:
                                                  kDeletedCellReuseIdentifier];
        if (!cell) {
            cell = [[LFSDeletedCell alloc]
                    initWithReuseIdentifier:kDeletedCellReuseIdentifier];
            [cell.imageView setBackgroundColor:[UIColor colorWithRed:(217.f/255.f)
                                                               green:(217.f/255.f)
                                                                blue:(217.f/255.f)
                                                               alpha:1.f]];
            [cell.imageView setImage:[UIImage imageNamed:@"Trash"]];
            [cell.imageView setContentMode:UIViewContentModeCenter];
            [cell.textLabel setFont:[UIFont italicSystemFontOfSize:12.f]];
            [cell.textLabel setTextColor:[UIColor lightGrayColor]];

        }
        [self configureDeletedCell:cell forContent:contentValues];
    return cell;
    }
    

    }
    else {
//        if (![[_mainContent objectAtIndex:1] isEqualToString:@"Alert Notification"]) {
//            return nil;
//        }
        if (cell == nil) {
            cell = [[LFRDetailTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        }

        [self configureAttributedCell2:cell forCount:@"2"];
        return  cell;
    }
}
-(void)configureDeletedCell:(LFSDeletedCell*)cell forContent:(LFSContent*)content
{
    if ([content isKindOfClass:[LFSContent class]]){
    LFSContentVisibility visibility = content.visibility;
        
        float dateCount;
        
        if([content.datePath count] <=5){
            dateCount=([content.datePath count] - 2)* kGenerationOffset;
        }
        else{
            dateCount=3*kGenerationOffset;
        }
     
        
        
    [cell setLeftOffset:dateCount];
    
    NSString *bodyText = (visibility == LFSContentVisibilityPendingDelete
                          ? @""
                          : @"This comment has been removed");
    
    [cell.textLabel setText:[NSString stringWithFormat:@"%@ (%ld)", bodyText, (long)content.nodeCount]];
        [cell.textLabel setText:bodyText];
    }
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
//    //user name
//    cell.userName.text=content.author.displayName ?: @"";
//    
//    //if moderator
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
    
    
    ///////
    //user name
    int heightForModeFeat=0;
    //if moderator
    if (content.authorIsModerator && content.isFeatured) {
//        cell.moderator.frame=CGRectMake(168,8, 80, 18);
//        cell.moderator.text=@"Moderator";
        heightForModeFeat=10;
        cell.featuredImage.frame=CGRectMake(73,8, 80, 18);
        cell.featuredImage.image=[UIImage imageNamed:@"Featured"];
    }
    else if(content.authorIsModerator&& !content.isFeatured ){
        cell.moderator.frame=CGRectMake(73,8, 80, 18);
        cell.moderator.text=@"Moderator";
        heightForModeFeat=10;
        
    }
    else if (content.isFeatured){
        cell.featuredImage.frame=CGRectMake(73,8, 80, 18);
        cell.featuredImage.image=[UIImage imageNamed:@"Featured"];
        heightForModeFeat=10;
        
    }
    else{
        cell.featuredImage.image=nil;
        cell.moderator.text=nil;
        heightForModeFeat=0;
    }
    cell.userName.frame=CGRectMake(73, 15+heightForModeFeat, 200, 16);
    cell.userName.text=content.author.displayName ?: @"";
    
//    [cell.rateView setFrame:CGRectMake(73, 41+heightForModeFeat, 200, 16)];
//    cell.footerLeftView.frame=CGRectMake(160, 40+heightForModeFeat, 200, 16);
    /////
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
        }
        [voteObject valueForKey:@"value"];
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
    
    //attached image
      if (content.firstOembed) {
     UIImageView *attachedImage=[[UIImageView alloc]initWithFrame:CGRectMake(15, 83+cell.title.frame.size.height+cell.body.frame.size.height, 290, 200)];
   
    LFSOembed *oembed=self.contentItem.firstOembed;
    // TODO: ask JS about desired behavior on image download failure
    [attachedImage setImageWithURL:[NSURL URLWithString:oembed.urlString]
                          completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType)
     {
         // find out image size here and re-layout view
         [cell.attachedImage setImage:image];
     }];
    [cell addSubview:attachedImage];
      }
    
    
    if ([content.annotations objectForKey:@"vote"]) {
        for ( NSDictionary *voteString in [content.annotations objectForKey:@"vote"] ) {
            if ([[voteString valueForKey:@"author"] isEqualToString:self.user.idString] && [[voteString valueForKey:@"value"] integerValue]==1 )
                [cell.button1 setImage:[UIImage imageNamed:@"StateLiked"]
                              forState:UIControlStateNormal];
            else
                [cell.button1 setImage:[UIImage imageNamed:@"icon_heart_initial"]
                              forState:UIControlStateNormal];
            
        }
    }
    else{
        [cell.button1 setImage:[UIImage imageNamed:@"icon_heart_initial"]
                      forState:UIControlStateNormal];
    }
    [cell.button1 setTitle:@"Helpful"
                  forState:UIControlStateNormal];
    [cell.button1 addTarget:self action:@selector(didSelectButton1:)
           forControlEvents:UIControlEventTouchUpInside];
    
    [cell.button2 setImage:[UIImage imageNamed:@"ActionReply"]
                  forState:UIControlStateNormal];
    [cell.button2 setTitle:@"Reply"
                  forState:UIControlStateNormal];
    [cell.button2 addTarget:self action:@selector(didSelectButton2:content:)
           forControlEvents:UIControlEventTouchUpInside];
  
    
    [cell.button3 setImage:[UIImage imageNamed:@"More"]
                  forState:UIControlStateNormal];
    [cell.button3 setTitle:@"More"
                  forState:UIControlStateNormal];
    [cell.button3 addTarget:self action:@selector(didSelectButton3:)
           forControlEvents:UIControlEventTouchUpInside];
    
    
    if (content.firstOembed) {
        cell.button1.frame=CGRectMake(10, 283+cell.title.frame.size.height+cell.body.frame.size.height, 100, 100);
        cell.button2.frame=CGRectMake(cell.button1.frame.size.width+15, 283+cell.title.frame.size.height+cell.body.frame.size.height, 100, 100);
        cell.button3.frame=CGRectMake(cell.button1.frame.size.width+15+cell.button2.frame.size.width, 283+cell.title.frame.size.height+cell.body.frame.size.height, 100, 100);
        [cell layoutsets];
    }
    else{
        cell.button1.frame=CGRectMake(10, 63+cell.title.frame.size.height+cell.body.frame.size.height, 100, 100);
        cell.button2.frame=CGRectMake(cell.button1.frame.size.width+15, 63+cell.title.frame.size.height+cell.body.frame.size.height, 100, 100);
        cell.button3.frame=CGRectMake(cell.button1.frame.size.width+15+cell.button2.frame.size.width, 63+cell.title.frame.size.height+cell.body.frame.size.height, 100, 100);
        [cell layoutsets1];
    }
     
  
}
- (void)configureAttributedCell1:(LFRDetailTableViewCell*)cell forContent:(LFSContent*)content
{
    //((CGFloat)([content.datePath count] - 1) * kGenerationOffset
    float dateCount;
    
    if([content.datePath count] <=5){
        dateCount=([content.datePath count] - 2)* kGenerationOffset;
    }
    else{
        dateCount=3*kGenerationOffset;
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

    if ([content.annotations objectForKey:@"vote"]) {
        for ( NSDictionary *voteString in [content.annotations objectForKey:@"vote"]) {
            if ([[voteString valueForKey:@"author"] isEqualToString:self.user.idString] && [[voteString valueForKey:@"value"] integerValue]==1 )
                [cell.button1 setImage:[UIImage imageNamed:@"StateLiked"]
                              forState:UIControlStateNormal];
            else
                [cell.button1 setImage:[UIImage imageNamed:@"icon_heart_initial"]
                              forState:UIControlStateNormal];
            
        }
    }
    else{
        [cell.button1 setImage:[UIImage imageNamed:@"icon_heart_initial"]
                      forState:UIControlStateNormal];
    }
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
- (void)configureAttributedCell2:(LFRDetailTableViewCell*)cell forCount:(NSString *)count{
    [cell.rateView setFrame:CGRectMake(0, 0, 0, 0)];
    if (updateCount == 1) {
        [cell.repliesCount setTitle:[NSString stringWithFormat: @"%d New Reply",updateCount] forState:UIControlStateNormal];
    }
    else{
        [cell.repliesCount setTitle:[NSString stringWithFormat: @"%d New Replies",updateCount] forState:UIControlStateNormal];
    }
    cell.repliesCount.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    [cell.repliesCount addTarget:self action:@selector(countButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    [cell.repliesCount setFrame:CGRectMake(15, 10, 290, 40)];
    [cell addSubview:cell.repliesCount];
}
-(void)countButtonClicked{
    
    [_mainContent removeObjectAtIndex:1];
    updateCount=0;
    oldCount= (int)_mainContent.count;
    isAlertAdded=NO;
  
    _mainContent=nil;
    _mainContent=[[NSMutableArray alloc]initWithArray:self.chaildContent];
    
    NSMutableArray *temp=[[NSMutableArray alloc]initWithArray:self.chaildContent];
    
    NSSortDescriptor *lowestToHighest = [NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:YES];
    [temp sortUsingDescriptors:[NSMutableArray arrayWithObject:lowestToHighest]];
    LFSContent *tempContent=[temp objectAtIndex:temp.count-1];
    
    NSInteger indexpath=[_mainContent indexOfObject:tempContent ];
    
    
    [self.tableView reloadData];
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:indexpath inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
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
   
    self.contentItem_clicked=[self.mainContent objectAtIndex:indexPath.row];
    
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
    _contentItem_clicked =[self.mainContent objectAtIndex:indexPath.row];
    
    
   // if (indexPath.row == 0) {
        if ([self.user.permissions objectForKey:@"moderator_key"] && _contentItem_clicked.authorIsModerator) {
            self.actionSheet1=[[UIActionSheet alloc]initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete" otherButtonTitles:@"Edit",@"Feature",nil];
        }
        else if([self.user.permissions objectForKey:@"moderator_key"]){
            self.actionSheet1=[[UIActionSheet alloc]initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete" otherButtonTitles:@"Ban User",@"Bozo",@"Edit",@"Feature",@"Flag",nil];
        }
        else if([self.user.idString isEqualToString:_contentItem_clicked.author.idString]){
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
                NSMutableDictionary *dict=[[NSMutableDictionary alloc]initWithObjectsAndKeys:userToken,LFSCollectionPostUserTokenKey,@1,@"value",self.contentItem_clicked.idString,@"message_id",nil ];
                    [self.writeClient postMessage:action
                                       forContent:self.contentItem_clicked.idString
                                     inCollection:self.collectionId
                                        userToken:userToken
                                       parameters:dict
                                        onSuccess:^(NSOperation *operation, id responseObject) {
//                                            if ([collectionViewController respondsToSelector:@selector(didPostContentWithOperation:response:)])
//                                            {
//                                                [collectionViewController didPostContentWithOperation:operation response:responseObject];
//                                            }
                                            [self.tableView reloadData];
                                       
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
                                 forContent:self.contentItem_clicked.idString
                               inCollection:self.collectionId
                                  userToken:userToken
                                 parameters:parameters
                                  onSuccess:^(NSOperation *operation, id responseObject)
               {
                   NSLog(@"success posting opine %u", action);
               }
                                  onFailure:^(NSOperation *operation, NSError *error)
               {
                   NSLog(@"failed posting opine %u", action);
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

                    [self.deletedContent postDestructiveMessage:LFSMessageDelete forContent:self.contentItem_clicked];
//                    [self.navigationController popToRootViewControllerAnimated:YES];
                }
            }
            else if ([action isEqualToString:@"Ban User"])
            {
                [self.deletedContent banAuthorOfContent:self.contentItem_clicked];
                 [self.navigationController popToRootViewControllerAnimated:YES];
             }
            else if ([action isEqualToString:@"Bozo"])
            {
                if ([self.deletedContent respondsToSelector:@selector(postDestructiveMessage:forContent:)]) {
                    [self.deletedContent postDestructiveMessage:LFSMessageBozo forContent:self.contentItem_clicked];
                    [self.navigationController popToRootViewControllerAnimated:YES];
                }
            }
            else if ([action isEqualToString:@"Edit"])
            {
                if ([self.contentItem_clicked.parentId isEqualToString:@""]) {
                    if ([self.deletedContent respondsToSelector:@selector(editReviewOfContent:forContent:)]) {
                        [self.deletedContent editReviewOfContent:LFSMessageEdit forContent:self.contentItem_clicked];
                }
                 
                    else{
                        
                    }
//                    [self.navigationController popToRootViewControllerAnimated:YES];
                }
            }
            else if ([action isEqualToString:@"Feature"])
            {
                [self.deletedContent featureContent:self.contentItem_clicked];

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
                [self.deletedContent flagContent:self.contentItem_clicked withFlag:LFSFlagSpam];
            }
            else if ([action isEqualToString:[LFSContentFlags[LFSFlagOffensive] capitalizedString]])
            {
                [self.deletedContent flagContent:self.contentItem_clicked withFlag:LFSFlagOffensive];
            }
            else if ([action isEqualToString:[LFSContentFlags[LFSFlagOfftopic] capitalizedString]])
            {
                [self.deletedContent flagContent:self.contentItem_clicked withFlag:LFSFlagOfftopic];
            }
            else if ([action isEqualToString:[LFSContentFlags[LFSFlagDisagree] capitalizedString]])
            {
                [self.deletedContent flagContent:self.contentItem_clicked withFlag:LFSFlagDisagree];
            }
            else if ([action isEqualToString:@"Cancel"])
            {
                // do nothing
            }
        }
    }
}
- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    [self.tableView setEditing:editing animated:animated]; // not needed if super is a UITableViewController
    
    NSMutableArray* paths = [[NSMutableArray alloc] init];

    // fill paths of insertion rows here
    
    if( editing )
        [self.tableView insertRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationBottom];
    else
        [self.tableView deleteRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationBottom];
    
 }

@end
