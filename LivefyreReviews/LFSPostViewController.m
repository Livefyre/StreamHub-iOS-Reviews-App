//
//  LFSNewCommentViewController.m
//  CommentStream
//
//  Created by Eugene Scherba on 9/13/13.
//  Copyright (c) 2013 Livefyre. All rights reserved.
//

#import <StreamHub-iOS-SDK/LFSWriteClient.h>
#import "LFSPostViewController.h"
#import <AssetsLibrary/ALAssetsLibrary.h>
//#import <LFAsyncDictionary/APAsyncDictionary.h>
#import "LFSAuthorProfile.h"
#import "LFSResource.h"
#import "LFRConfig.h"
#import "DYRateView.h"
#import "LFSWriteCommentView.h"
#import "LFSBasicHTMLParser.h"
#define LFS_PHOTO_ACTIONS_LENGTH 3u

typedef NS_ENUM(NSUInteger, kAddPhotoAction) {
    kAddPhotoTakePhoto = 0u,
    kAddPhotoChooseExisting,
    kAddPhotoSocialSource
};

// (for internal use):
// https://github.com/Livefyre/lfdj/blob/production/lfwrite/lfwrite/api/v3_0/urls.py#L75
static NSString* const kPhotoActionsArray[LFS_PHOTO_ACTIONS_LENGTH] =
{
    @"Take Photo",            // 0
    @"Choose Existing Photo", // 1
    @"Use Social Sources",    // 2
};

@interface LFSPostViewController ()

// render iOS7 status bar methods as writable properties
@property (nonatomic, assign) BOOL prefersStatusBarHidden;
@property (nonatomic, assign) UIStatusBarAnimation preferredStatusBarUpdateAnimation;
@property (nonatomic, strong) UIActionSheet *actionSheet;
@property (nonatomic, readonly) LFSWriteClient *writeClient;
@property (weak, nonatomic) IBOutlet LFSWriteCommentView *writeCommentView;
@property (atomic, strong) NSString *currentOembedKey;

@property (weak, nonatomic) IBOutlet UINavigationBar *postNavbar;


- (IBAction)cancelClicked:(UIBarButtonItem *)sender;
- (IBAction)postClicked:(UIBarButtonItem *)sender;

@end

@implementation LFSPostViewController {
    NSDictionary *_authorHandles;
     NSMutableDictionary *_oembeds;
         BOOL _pauseKeyboard;
        BOOL _statusBarHidden;
   
 
}

#pragma mark - Properties

@synthesize writeCommentView;
@synthesize delegate = _delegate;

// render iOS7 status bar methods as writable properties
@synthesize prefersStatusBarHidden = _prefersStatusBarHidden;
@synthesize preferredStatusBarUpdateAnimation = _preferredStatusBarUpdateAnimation;
@synthesize collection = _collection;

@synthesize postNavbar = _postNavbar;
@synthesize user = _user;

@synthesize writeClient = _writeClient;
@synthesize collectionId = _collectionId;
@synthesize replyToContent = _replyToContent;
 
- (LFSWriteClient*)writeClient
{
    if (_writeClient == nil) {
        _writeClient = [LFSWriteClient
                        clientWithNetwork:[self.collection objectForKey:@"network"]
                        environment:[self.collection objectForKey:@"environment"]];
    }
    return _writeClient;
}


#pragma mark - UIViewController

// Hide/show status bar
- (BOOL)prefersStatusBarHidden
{
    return NO;
}

#pragma mark - Lifecycle

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self resetEverything];
    }
    return self;
}

-(void)resetEverything {
    _writeClient = nil;
    _collection = nil;
    _collectionId = nil;
    _replyToContent = nil;
    _delegate = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    LFRConfig *config = [[LFRConfig alloc] initwithValues];
    self.writeCommentView.delegate=self;
    self.collection=[[NSDictionary alloc]init];
    self.collection=[config.collections objectAtIndex:0];
    LFSAuthorProfile *author = self.user.profile;
    NSString *detailString = (author.twitterHandle ? [@"@" stringByAppendingString:author.twitterHandle] : nil);
    LFSResource *headerInfo = [[LFSResource alloc]
                               initWithIdentifier:detailString
                               attribute:nil
                               displayString:@"Title"
                               icon:self.avatarImage];
    [headerInfo setIconURLString:author.avatarUrlString75];
    [self.writeCommentView setProfileLocal:headerInfo];
  _oembeds = [[NSMutableDictionary alloc] init];
    FPPickerController *pickerController = [FPPickerController new];
    pickerController.fpdelegate = self;
    
    oembedArray = [NSMutableArray array];

 }


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    self.navigationController.navigationBar.barTintColor=UIColorFromRGB(0xF6F6F6);

    // show keyboard (doing this in viewDidAppear causes unnecessary lag)
    [self.writeCommentView.textView becomeFirstResponder];
    
    if (self.replyToContent != nil) {
        [self.postNavbar.topItem setTitle:@"NewReview"];
        
        _authorHandles = nil;
        NSString *replyPrefix = [self replyPrefixFromContent:self.replyToContent];
        if (replyPrefix != nil) {
            [self.writeCommentView.textView setText:replyPrefix];
        }
    }
    if(_isEdit){

        [self.writeCommentView.textView setAttributedText:[LFSBasicHTMLParser attributedStringByProcessingMarkupInString:_content.bodyHtml]];
        [self.writeCommentView.titleTextField setText:_content.title];
        NSNumber *rating=[[_content.annotations objectForKey:@"rating"] objectAtIndex:0];
        //[cell.rateView setRate:[rating floatValue]/20];
        self.writeCommentView.starView.rating=[rating floatValue]/20;
        self.writeCommentView.starView.userInteractionEnabled=NO;
        
    }
}

-(void)clearContent
{
    [_oembeds removeAllObjects];
    [self.writeCommentView setAttachmentImage:nil];
    [self.writeCommentView.textView setText:@""];
}



- (NSString*)replyPrefixFromContent:(LFSContent*)content
{
    // remove self (own user handle) from list
    NSMutableDictionary *dictionary = [content authorHandles];
    NSString *currentHandle = self.user.profile.authorHandle;
    if (currentHandle != nil) {
        [dictionary removeObjectForKey:[currentHandle lowercaseString]];
    }
    
    _authorHandles = dictionary;
    NSArray *handles = [_authorHandles allKeys];
    NSString *prefix = nil;
    if (handles.count  > 0) {
        NSString *joinedParticipants = [handles componentsJoinedByString:@" @"];
        prefix = [NSString stringWithFormat:@"@%@ ", joinedParticipants];
    }
    return prefix;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dealloc
{
    [self resetEverything];
}

#pragma mark - Status bar

-(void)setStatusBarHidden:(BOOL)hidden
            withAnimation:(UIStatusBarAnimation)animation
{
    const static CGFloat kStatusBarHeight = 20.f;
    _prefersStatusBarHidden = hidden;
    _preferredStatusBarUpdateAnimation = animation;
    
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)])
    {
        // iOS7
        [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
    }
    else
    {
        // iOS6
        [[UIApplication sharedApplication] setStatusBarHidden:hidden
                                                withAnimation:animation];
        if (self.navigationController) {
            UINavigationBar *navigationBar = self.navigationController.navigationBar;
            if (hidden && navigationBar.frame.origin.y > 0.f)
            {
                CGRect frame = navigationBar.frame;
                frame.origin.y = 0.f;
                navigationBar.frame = frame;
            }
            else if (!hidden && navigationBar.frame.origin.y < kStatusBarHeight)
            {
                CGRect frame = navigationBar.frame;
                frame.origin.y = kStatusBarHeight;
                navigationBar.frame = frame;
            }
        }
    }
}

#pragma mark - Utility methods

-(NSString*)processReplyText:(NSString*)replyText
{
    if (_authorHandles == nil) {
        return replyText;
    }
    
    // process replyText such that all cases of handles get replaced with anchors
    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression
                                  regularExpressionWithPattern:@"@(\\w+)\\b"
                                  options:NSRegularExpressionCaseInsensitive
                                  error:&error];
    
    NSArray *matches = [regex matchesInString:replyText
                                      options:0
                                        range:NSMakeRange(0, replyText.length)];
    
    // enumerate in reverse order because that way we can preserve location
    // in our mutable string
    NSMutableString *mutableReply = [replyText mutableCopy];
    [matches enumerateObjectsWithOptions:NSEnumerationReverse
                              usingBlock:
     ^(NSTextCheckingResult *match, NSUInteger idx, BOOL *stop)
    {
        NSRange handleRange = [match rangeAtIndex:1];
        NSString *candidate = [replyText substringWithRange:match.range];
        
        NSString *urlString = [_authorHandles objectForKey:[[replyText substringWithRange:handleRange] lowercaseString]];
        if (urlString != nil) {
            // candidate found in dictionary
            NSString *replacement = [NSString
                                     stringWithFormat:@"<a href=\"%@\">%@</a>",
                                     urlString, candidate];
            [mutableReply replaceCharactersInRange:match.range withString:replacement];
        }
    }];

    return [mutableReply copy];
}
- (void)rateView:(DYRateView *)rateView changedToNewRate:(NSNumber *)rate {
    //self.headerRatingView.text = [NSString stringWithFormat:@"Rate: %d", rate.intValue];
}

#pragma mark - Actions
- (IBAction)cancelClicked:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)postClicked:(UIBarButtonItem *)sender
{
    static NSString* const kFailurePostTitle = @"Failed to post content";
    
    NSString *userToken = [self.collection objectForKey:@"lftoken"];
    if (userToken != nil) {
        UITextView *textView = self.writeCommentView.textView;
        NSString *text = (self.replyToContent
                          ? [self processReplyText:textView.text]
                          : textView.text);
        
        
        UITextField *titleText=self.writeCommentView.titleTextField;
        NSString *title=titleText.text;
        UITextField *prosText=self.writeCommentView.prosTextField;
        NSString *pros=prosText.text;
        UITextField *consText=self.writeCommentView.consTextField;
        NSString *cons=consText.text;
        NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
        [f setNumberStyle:NSNumberFormatterNoStyle];
        NSNumber * value = [f numberFromString:self.writeCommentView.ratingPost];
        if(self.isEdit){
           value=[[_content.annotations objectForKey:@"rating"] objectAtIndex:0];
         }

        if (title.length == 0 ) {
            UIAlertView * alertView=[[UIAlertView alloc]initWithTitle:@"Oops" message:@"Your review must include a title" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alertView show];
        }
        else if (text.length == 0 ) {
            UIAlertView * alertView=[[UIAlertView alloc]initWithTitle:@"Oops" message:@"Your review must include a Body" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alertView show];
        }
        else if (((int) value<1  && (int) value > 100) || self.writeCommentView.ratingPost==nil){
            UIAlertView * alertView=[[UIAlertView alloc]initWithTitle:@"Oops" message:@"Your review must include a star rating" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alertView show];
            
        }
        
        else{
            
            if (pros.length == 0){
                pros=@"";
            }
            else{
                pros=[NSString stringWithFormat:@"<p><strong>Pros:</strong>%@</p>",pros];

            }
            if (cons.length == 0){
                cons=@"";
            }
            else{
                cons=[NSString stringWithFormat:@"<p><strong>Cons:</strong>%@</p>",cons];
                
            }
            if (pros.length == 0 && cons.length == 0){
                
            }
            else{
                text=[NSString stringWithFormat:@"<p><strong>Description:</strong>%@</p>",text];
                
            }
        NSDictionary *rating = @{@"default":value};
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:rating options:0 error:NULL];
        NSString *ratingjsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        NSString *bodyofReview=[NSString stringWithFormat:@"%@%@%@",pros,cons,text];
        [textView setText:@""];
          
        id<LFSPostViewControllerDelegate> collectionViewController = nil;
        if ([self.delegate respondsToSelector:@selector(collectionViewController)]) {
            collectionViewController = [self.delegate collectionViewController];
        }
            NSString *jsonString = [oembedArray JSONString];
            NSMutableDictionary *dict=[[NSMutableDictionary alloc]initWithObjectsAndKeys:ratingjsonString, LFSCollectionPostRatingKey,bodyofReview,LFSCollectionPostBodyKey,userToken,LFSCollectionPostUserTokenKey,title,LFSCollectionPostTitleKey,jsonString,@"attachments", nil ];
            
            
        [self.writeClient postContentType:2 forCollection:self.collectionId parameters:dict
                           onSuccess:^(NSOperation *operation, id responseObject) {
                               self.writeCommentView.textView.text=@"";
                               self.writeCommentView.titleTextField.text=@"";
                               self.writeCommentView.prosTextField.text=@"";
                               self.writeCommentView.consTextField.text=@"";
                               self.writeCommentView.attachmentImage=nil;
                               self.writeCommentView.starView.rating=0.01f;
                               if ([collectionViewController respondsToSelector:@selector(didPostContentWithOperation:response:)])
                               {
                                   [collectionViewController didPostContentWithOperation:operation response:responseObject];
                                }
                           } onFailure:^(NSOperation *operation, NSError *error) {
                               [[[UIAlertView alloc]
                               initWithTitle:kFailurePostTitle
                               message:[error localizedRecoverySuggestion]
                               delegate:nil
                               cancelButtonTitle:@"OK"
                               otherButtonTitles:nil] show];
                           }];
            [self dismissViewControllerAnimated:YES completion:nil];
    
        }

        if ([self.delegate respondsToSelector:@selector(didSendPostRequestWithReplyTo:)]) {
            [self.delegate didSendPostRequestWithReplyTo:self.replyToContent.idString];
        }
    } else {
        // userToken is nil -- show an error message
        [[[UIAlertView alloc]
          initWithTitle:kFailurePostTitle
          message:@"You do not have permission to write to this collection"
          delegate:nil
          cancelButtonTitle:@"OK"
          otherButtonTitles:nil] show];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - LFSWritecommentViewDelegate
-(void)didClickAddPhotoButton
{
    FPPickerController *pickerController = [FPPickerController new];
    pickerController.fpdelegate = self;
    pickerController.dataTypes = @[
                                   @"image/*"
                                   ];
    
//    pickerController.sourceNames = @[
//                                     FPSourceImagesearch,
//                                     FPSourceDropbox
//                                     ];
//    
//    // You can set some of the in built Camera properties as you would with UIImagePicker
//    
//    pickerController.allowsEditing = YES;
//    
//    // Allowing multiple file selection
//    
//    pickerController.selectMultiple = YES;
//    
//    // Limiting the maximum number of files that can be uploaded at one time
//    
//    pickerController.maxFiles = 5;
//    
    pickerController.navigationItem.rightBarButtonItem.title=@"Close";

    [self presentViewController:pickerController
                       animated:YES
                     completion:nil];
}

#pragma mark - FPPickerController Delegate Methods

- (void)FPPickerController:(FPPickerController *)pickerController didFinishPickingMediaWithInfo:(FPMediaInfo *)info
{
    NSURL *urlString=info.remoteURL;
         [self.writeCommentView setAttachmentImageWithURL:urlString];
    if(pickerController){
        [pickerController dismissViewControllerAnimated:YES completion:nil];
    }
    [self.writeCommentView.textView becomeFirstResponder];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];

    NSString *thumbnail_url=[NSString stringWithFormat:@"%@",info.remoteURL];
    NSString *type=@"photo";
    NSString *provider_name=@"LivefyreFilePicker";
    NSString *url=[NSString stringWithFormat:@"%@",info.remoteURL];
   
    NSDictionary *oemdedDict=[[NSDictionary alloc]initWithObjectsAndKeys:thumbnail_url,@"thumbnail_url",type,@"type",provider_name,@"provider_name",url,@"url", nil];
    
    oembedArray=[[NSMutableArray alloc]initWithObjects:oemdedDict, nil];

}

- (void)FPPickerControllerDidCancel:(FPPickerController *)pickerController{
    // Handle accordingly
    [pickerController dismissViewControllerAnimated:YES completion:nil];
    [self.writeCommentView.textView becomeFirstResponder];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];

}


@end
