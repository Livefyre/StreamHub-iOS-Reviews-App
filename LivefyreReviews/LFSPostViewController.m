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
#import <LFAsyncDictionary/APAsyncDictionary.h>
#import <FilepickerSDK/FPMBProgressHUD.h>
#import <FilepickerSDK/FPLibrary.h>
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
    // NSLog(@"%@",config.collections);
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
            UIAlertView * alertView=[[UIAlertView alloc]initWithTitle:@"alert" message:@"Your review must include a title" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alertView show];
        }
        else if (((int) value<1  && (int) value > 100) || self.writeCommentView.ratingPost==nil){
            UIAlertView * alertView=[[UIAlertView alloc]initWithTitle:@"alert" message:@"Your review must include a star rating" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
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
        
        NSLog(@"%@", ratingjsonString);
            NSString *bodyofReview=[NSString stringWithFormat:@"%@%@%@",pros,cons,text];

        [textView setText:@""];
          
        id<LFSPostViewControllerDelegate> collectionViewController = nil;
        if ([self.delegate respondsToSelector:@selector(collectionViewController)]) {
            collectionViewController = [self.delegate collectionViewController];
        }
            NSMutableArray *oembedArray = [NSMutableArray array];
            [_oembeds enumerateKeysAndObjectsUsingBlock:^(id key, APAsyncDictionary *obj, BOOL *stop) {
                // Clone all oembed objects into regular dictionaries because our
                // thread-safe dictionary object does not support JSONKit serialization
                [oembedArray addObject:[obj underlyingDictionary]];
            }];
//            NSMutableDictionary *temp=[NSMutableDictionary dictionary];
//        temp[@"url"]=@"http://media.fyre.co/RqimEzoDRmiMLXrGFwNn_98014e8e710111e393ee0efe85b0f5ce_8.jpg";
//        temp[@"link"]=@"http://media.fyre.co/RqimEzoDRmiMLXrGFwNn_98014e8e710111e393ee0efe85b0f5ce_8.jpg";
//        temp[@"provider_name"] =@"LivefyreFilePicker";
//        temp[@"type"]=@"photo";
//            
//            NSMutableArray *attachments =[[NSMutableArray alloc]initWithObjects:temp, nil];
//            
            
            NSData *jsonData1 = [NSJSONSerialization dataWithJSONObject:oembedArray options:0 error:NULL];
            NSString *ratingjsonString1 = [[NSString alloc] initWithData:jsonData1 encoding:NSUTF8StringEncoding];
            
            
            NSMutableDictionary *dict=[[NSMutableDictionary alloc]initWithObjectsAndKeys:ratingjsonString, LFSCollectionPostRatingKey,bodyofReview,LFSCollectionPostBodyKey,userToken,LFSCollectionPostUserTokenKey,title,LFSCollectionPostTitleKey,ratingjsonString1,@"attachments", nil ];
            
            
            
            
            
            
//            if(self.isEdit){
//                [self.writeClient postMessage:LFSMessageEdit
//                                   forContent:self.content.idString
//                                 inCollection:self.collectionId
//                                    userToken:userToken
//                                   parameters:dict
//                                    onSuccess:^(NSOperation *operation, id responseObject) {
//                                        if ([collectionViewController respondsToSelector:@selector(didPostContentWithOperation:response:)])
//                                        {
//                                            [collectionViewController didPostContentWithOperation:operation response:responseObject];
//                                        }
//                                    } onFailure:^(NSOperation *operation, NSError *error) {
//                                        [[[UIAlertView alloc]
//                                          initWithTitle:kFailurePostTitle
//                                          message:[error localizedRecoverySuggestion]
//                                          delegate:nil
//                                          cancelButtonTitle:@"OK"
//                                          otherButtonTitles:nil] show];
//                                    }];
//
////                [self.writeClient postContentType:13 forCollection:self.collectionId parameters:dict
////                                        onSuccess:^(NSOperation *operation, id responseObject) {
////                                            if ([collectionViewController respondsToSelector:@selector(didPostContentWithOperation:response:)])
////                                            {
////                                                [collectionViewController didPostContentWithOperation:operation response:responseObject];
////                                            }
////                                        } onFailure:^(NSOperation *operation, NSError *error) {
////                                            [[[UIAlertView alloc]
////                                              initWithTitle:kFailurePostTitle
////                                              message:[error localizedRecoverySuggestion]
////                                              delegate:nil
////                                              cancelButtonTitle:@"OK"
////                                              otherButtonTitles:nil] show];
////                                        }];
//
//            }else{
        

                
        [self.writeClient postContentType:2 forCollection:self.collectionId parameters:dict
                           onSuccess:^(NSOperation *operation, id responseObject) {
                               self.writeCommentView.textView.text=@"";
                               self.writeCommentView.titleTextField.text=@"";
                               self.writeCommentView.prosTextField.text=@"";
                               self.writeCommentView.consTextField.text=@"";
                               self.writeCommentView.attachmentImage=nil;
                               self.writeCommentView.starView.rating=0.0f;
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
    [self.actionSheet showInView:self.view];
}


#pragma mark -
@synthesize actionSheet = _actionSheet;
-(UIActionSheet*)actionSheet
{
    if (_actionSheet == nil) {
        _actionSheet = [[UIActionSheet alloc]
                        initWithTitle:nil
                        delegate:self
                        cancelButtonTitle:@"Cancel"
                        destructiveButtonTitle:nil
                        otherButtonTitles:
                        kPhotoActionsArray[kAddPhotoTakePhoto],
                        kPhotoActionsArray[kAddPhotoChooseExisting],
                        kPhotoActionsArray[kAddPhotoSocialSource],
                        nil];
    }
    return _actionSheet;
}
#pragma mark - UIActionSheetDelegate

-(void)startOembed
{
    NSUInteger count = [_oembeds count];
    [self setCurrentOembedKey:[NSString stringWithFormat:@"key%lu",
                               (unsigned long)count]];
    [_oembeds setObject:[[APAsyncDictionary alloc] init]
                 forKey:self.currentOembedKey];
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // TODO: this method is incomplete
    
    // Get the name of the button pressed
    NSString *action = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    if (actionSheet == self.actionSheet) {
        if ([action isEqualToString:kPhotoActionsArray[kAddPhotoTakePhoto]])
        {
            // Camera (ImagePicker)
            [self startOembed];
            [self presentImagePickerWithSourceType:UIImagePickerControllerSourceTypeCamera];
        }
        else if ([action isEqualToString:kPhotoActionsArray[kAddPhotoChooseExisting]])
        {
            // Photo Album (ImagePicker)
            [self startOembed];
            [self presentImagePickerWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
        }
        else if ([action isEqualToString:kPhotoActionsArray[kAddPhotoSocialSource]])
        {
            // Social source (FilePicker control)
            [self startOembed];
            [self presentSocialPicker];
        }
        else {
            // do nothing
        }
    }
}

- (void)presentImagePickerWithSourceType:(UIImagePickerControllerSourceType)sourceType
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    [picker setDelegate:self];
    @try {
        [picker setSourceType:sourceType];
    }
    @catch (NSException *e) {
        if ([e name] == NSInvalidArgumentException) {
            return; // source type not available (on iOS simulator)
        } else {
            @throw e;
        }
    }
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)presentSocialPicker
{
    FPPickerController *picker = [[FPPickerController alloc] init];
    [picker setFpdelegate:self];
    [picker setDataTypes:[NSArray arrayWithObjects:@"image/*", nil]];
    [picker setSourceNames:[[NSArray alloc]
                            initWithObjects: FPSourceImagesearch, FPSourceFacebook, FPSourceInstagram, FPSourceFlickr, FPSourcePicasa, FPSourceBox, FPSourceDropbox, FPSourceGoogleDrive, nil]];
    
    [picker setSelectMultiple:NO];
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark - UIImagePickerControllerDelegate

-(void)uploadAssetAtURL:(NSURL*)referenceURL
{
    // Upload from album
    //
    ALAssetsLibrary* assetslibrary = [[ALAssetsLibrary alloc] init];
    [assetslibrary assetForURL:referenceURL resultBlock:^(ALAsset *asset)
     {
         FPMBProgressHUD __block *hud;
         dispatch_async(dispatch_get_main_queue(),^{
             hud = [FPMBProgressHUD showHUDAddedTo:self.view animated:YES];
             hud.labelText = @"Uploading file";
             hud.mode = FPMBProgressHUDModeDeterminate;
         });
         
         // Upload full-size image
         ALAssetRepresentation *representation = [asset defaultRepresentation];
         UIImage *image = [UIImage imageWithCGImage:[representation fullScreenImage]];
         [FPLibrary uploadAsset:asset withOptions:nil shouldUpload:YES
                        success:^(id JSON, NSURL *localurl)
          {
              NSDictionary *dictionary = FPDictionaryFromJSONInfoPhoto(JSON, image, localurl);
              [self addOembedMainInfo:dictionary];
              [FPMBProgressHUD hideAllHUDsForView:self.view animated:YES];
              _pauseKeyboard = NO;
              [self.writeCommentView.textView becomeFirstResponder];
          }
                        failure:^(NSError *error, id JSON, NSURL *localurl)
          {
              //NSDictionary *dictionary = FPDictionaryFromJSONInfoPhotoFailure(image, localurl, nil);
              [FPMBProgressHUD hideAllHUDsForView:self.view animated:YES];
              _pauseKeyboard = NO;
              [self.writeCommentView.textView becomeFirstResponder];
          }
                       progress:^(float progress)
          {
              hud.progress = progress;
          }];
         
         // Upload the thumbnail
         UIImage *thumbnail = [UIImage imageWithCGImage:[asset aspectRatioThumbnail]];
         if (thumbnail) {
             [self addAndUploadThumbnail:thumbnail scale:1.f];
         }
         
     } failureBlock:nil];
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    if (![mediaType isEqualToString:(__bridge NSString *)kUTTypeImage])
    {
        // only accept @"public.image" types -- ignore video
        [self dismissViewControllerAnimated:NO completion:^{
            [self.writeCommentView.textView becomeFirstResponder];
        }];
        return;
    }
    
    UIImage *originalImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    NSURL *referenceURL = [info objectForKeyedSubscript:UIImagePickerControllerReferenceURL];
    
    if (referenceURL != nil) {
        // Upload from photo album
        //
        [self uploadAssetAtURL:referenceURL];
        _pauseKeyboard = YES;
        [self.writeCommentView.textView resignFirstResponder];
    }
    else if (originalImage != nil) {
        // Upload from camera
        //
        FPMBProgressHUD __block *hud = [FPMBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.labelText = @"Uploading file";
        hud.mode = FPMBProgressHUDModeDeterminate;
        
        ALAssetsLibrary *library = [ALAssetsLibrary new];
        [library writeImageToSavedPhotosAlbum:[originalImage CGImage]
                                  orientation:(ALAssetOrientation)[originalImage imageOrientation]
                              completionBlock:^(NSURL *assetURL, NSError *error)
         {
             if (error) {
                 // TODO: handle error writing image to disk
                 return;
             }
             [self uploadAssetAtURL:assetURL];
         }];
        
        _pauseKeyboard = YES;
        [self.writeCommentView.textView resignFirstResponder];
    }
    else {
        _pauseKeyboard = NO;
        [self.writeCommentView.textView becomeFirstResponder];
    }
    
    [self dismissViewControllerAnimated:NO completion:nil];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:NO completion:^{
        [self.writeCommentView.textView becomeFirstResponder];
    }];
}

#pragma mark - FPPickerDelegate

-(void)addOembedThumbnailInfo:(NSDictionary*)info
{
    NSString *urlString;
    NSString *imageKey = [info objectForKey:FPPickerControllerKey];
    if (imageKey != nil) {
        urlString = [@"http://media.fyre.co/" stringByAppendingString:imageKey];
    } else {
        urlString = [info objectForKey:FPPickerControllerRemoteURL];
    }
    
    // Add to oembed dictionary
    APAsyncDictionary *oembed = [_oembeds objectForKey:self.currentOembedKey];
    [oembed setObjectsAndKeysFromDictionary:@{@"thumbnail_url": urlString}];
}

-(void)addOembedMainInfo:(NSDictionary*)info
{
    NSString *urlString;
    NSString *imageKey = [info objectForKey:FPPickerControllerKey];
    if (imageKey != nil) {
        urlString = [@"http://media.fyre.co/" stringByAppendingString:imageKey];
    } else {
        urlString = [info objectForKey:FPPickerControllerRemoteURL];
    }
    
    LFSOembedType oembedType = attachmentCodeFromUTType([info objectForKey:FPPickerControllerMediaType]);
    
    // Add to oembed dictionary
    NSParameterAssert(oembedType < LFS_OEMBED_TYPES_LENGTH);
    APAsyncDictionary *oembed = [_oembeds objectForKey:self.currentOembedKey];
    [oembed setObjectsAndKeysFromDictionary:@{@"url": urlString,
                                              @"link": urlString,
                                              @"provider_name": @"LivefyreFilePicker",
                                              @"type": LFSOembedTypes[oembedType]}];
    
    UIImage *originalImage = [info objectForKey:FPPickerControllerOriginalImage];
    if (originalImage != nil) {
     [self.writeCommentView setAttachmentImage:originalImage];
    } else {
     [self.writeCommentView setAttachmentImageWithURL:[NSURL URLWithString:urlString]];
    }
}

-(void)addAndUploadThumbnail:(UIImage*)thumbnail scale:(CGFloat)scale
{
    APAsyncDictionary *oembed = [_oembeds objectForKey:self.currentOembedKey];
    [oembed setObjectsAndKeysFromDictionary:@{
                                              @"thumbnail_width": [NSNumber numberWithUnsignedInteger:(NSUInteger)(scale * thumbnail.size.width)],
                                              @"thumbnail_height": [NSNumber numberWithUnsignedInteger:(NSUInteger)(scale * thumbnail.size.height)]}];
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),
                   ^(void)
                   {
                       [FPLibrary uploadImage:thumbnail
                                   ofMimetype:@"image/jpeg"
                                  withOptions:nil
                                 shouldUpload:YES
                                      success:^(id JSON, NSURL *localurl)
                        {
                            NSDictionary *dictionary = FPDictionaryFromJSONInfoPhoto(JSON, thumbnail, localurl);
                            [self addOembedThumbnailInfo:dictionary];
                        }
                                      failure:nil
                                     progress:nil];
                   });
}

-(void)FPPickerController:(FPPickerController *)picker didPickMediaWithInfo:(NSDictionary *)info
{
    UIImage *thumbnail = [info objectForKey:FPPickerControllerThumbnailImage];
    if (thumbnail) {
        [self addAndUploadThumbnail:thumbnail scale:2.f];
    }
}

-(void)FPPickerController:(FPPickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [self addOembedMainInfo:info];
    [self dismissViewControllerAnimated:NO completion:^{
        [self.writeCommentView.textView becomeFirstResponder];
    }];
}

-(void)FPPickerControllerDidCancel:(FPPickerController *)picker
{
    [self dismissViewControllerAnimated:NO completion:^{
        [self.writeCommentView.textView becomeFirstResponder];
    }];
}



@end
