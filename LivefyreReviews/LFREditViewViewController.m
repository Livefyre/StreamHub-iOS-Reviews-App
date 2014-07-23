//
//  LFREditViewViewController.m
//  LivefyreReviews
//
//  Created by kvana inc on 09/07/14.
//  Copyright (c) 2014 Kvana Inc. All rights reserved.
//
#import <StreamHub-iOS-SDK/LFSWriteClient.h>
#import "LFREditViewViewController.h"
#import "LFSBasicHTMLParser.h"
#import "LFSContentCollection.h"


@interface LFREditViewViewController ()
@property (nonatomic, strong) LFSContentCollection *content1;
@property (nonatomic, readonly) LFSWriteClient *writeClient;
@property (nonatomic, retain) NSString *ratingjsonString;
@property (nonatomic, retain) NSString *bodyofReview;
@property (nonatomic, retain) UITextField *titleTextField;
@property (nonatomic, retain) UITextView *description;
@property (nonatomic, retain) UITextField *prosTextField;
@property (nonatomic, retain) UITextField *consTextField;

@end

@implementation LFREditViewViewController
@synthesize writeClient = _writeClient;
static const UIEdgeInsets kPostContentInset = {
    .top=130.f, .left=7.f, .bottom=20.f, .right=5.f
};

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

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

-(void)viewWillAppear:(BOOL)animated{
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    [self.navigationController setToolbarHidden:YES animated:YES];
    self.navigationController.navigationBarHidden=YES;
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    [navigationBar setBarStyle:UIBarStyleDefault];
    if (LFS_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(LFSSystemVersion70)) {
        self.navigationController.navigationBar.barTintColor = UIColorFromRGB(0xF3F3F3) ;
        [navigationBar setTranslucent:NO];
        self.navigationController.title=@"Review";
    }
    
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor=UIColorFromRGB(0xF3F3F3);
    
    UIView *view1=[[UIView alloc]initWithFrame:CGRectMake(0, 0, 320, 60)];
    view1.backgroundColor=UIColorFromRGB(0xF3F3F3);
    UIButton *butt=[[UIButton alloc]initWithFrame:CGRectMake(15, 20,60,40)];
    [butt setTitle:@"Cancel" forState:UIControlStateNormal];
    [butt setTitleColor:UIColorFromRGB(0x0F98EC) forState:UIControlStateNormal];
    [butt addTarget:self action:@selector(cancelClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:view1];
    [view1 addSubview:butt];
    
    UIButton *postButton=[[UIButton alloc]initWithFrame:CGRectMake(250, 20,60,40)];
    [postButton setTitle:@"Post" forState:UIControlStateNormal];
    [postButton setTitleColor:UIColorFromRGB(0x0F98EC) forState:UIControlStateNormal];
    [postButton addTarget:self action:@selector(actionClicked:) forControlEvents:UIControlEventTouchUpInside];
    [view1 addSubview:postButton];
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenHeight = screenRect.size.height;
    UIView *Scrool=[[UIView alloc]initWithFrame:CGRectMake(0, 62, 320, screenHeight-330)];
    
    //description textarea
    self.description=[[UITextView alloc]initWithFrame:CGRectMake(0,0, 320, screenHeight-330)];
    
    
    NSAttributedString *text=[LFSBasicHTMLParser attributedStringByProcessingMarkupInString:_content.bodyHtml];
    if (text.length) {
        NSAttributedString *last = [text attributedSubstringFromRange:NSMakeRange(text.length - 1, 1)];
        if ([[last string] isEqualToString:@"\n"]) {
            text = [text attributedSubstringFromRange:NSMakeRange(0, text.length - 1)];
        }
    }

    [_description setAttributedText:text];
    [self.description setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin)];
    [_description setFont:[UIFont fontWithName:@"Georgia" size:18.0f]];
    [_description setTextColor:UIColorFromRGB(0x474C52)];
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:_description.text];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 28;
    NSDictionary *dict = @{NSParagraphStyleAttributeName : paragraphStyle };
    [attributedString addAttributes:dict range:NSMakeRange(0, [_description.text length])];
    [_description setTextContainerInset:kPostContentInset];
    [Scrool addSubview:_description];
    
    // Title Lable
    UILabel *headerTitleLable = [[UILabel alloc] init];
    [headerTitleLable
     setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin)];
    [headerTitleLable setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:15.0f]];
    [headerTitleLable setText:@"Title"];
    [headerTitleLable setFrame:CGRectMake(15,16, 40, 28)];
    [headerTitleLable setTextColor:UIColorFromRGB(0x969696)];
    [_description addSubview:headerTitleLable];
    
    // Title TextField
    CGSize headerTestSize = [[headerTitleLable text] sizeWithAttributes:@{NSFontAttributeName:[headerTitleLable font]}];
    CGFloat headerStrikeWidth = headerTestSize.width;
    self.titleTextField = [[UITextField alloc] initWithFrame:CGRectMake(headerStrikeWidth+25,16, 260, 28)];
    [self.titleTextField
     setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin)];
    [self.titleTextField setFont:[UIFont fontWithName:@"Georgia" size:18]];
    [self.titleTextField setTextColor:UIColorFromRGB(0x474C52)];
//    [self.titleTextField setPlaceholder:@"Enter Title"];
    
//    [self.writeCommentView.textView setAttributedText:[LFSBasicHTMLParser attributedStringByProcessingMarkupInString:_content.bodyHtml]];
//    [self.writeCommentView.titleTextField setText:_content.title];
//    NSNumber *rating=[[_content.annotations objectForKey:@"rating"] objectAtIndex:0];
//    //[cell.rateView setRate:[rating floatValue]/20];
//    self.writeCommentView.starView.rating=[rating floatValue]/20;
//    self.writeCommentView.starView.userInteractionEnabled=NO;
    
    [self.titleTextField setText:_content.title];
    [self.titleTextField becomeFirstResponder];
    [_description addSubview:self.titleTextField];
    
    //ratings
    CGRect frame = CGRectMake(48,76,320,60);
    DYRateView *headerRatingView = [[DYRateView alloc] initWithFrame:frame fullStar:[UIImage imageNamed:@"icon_star_large"] emptyStar:[UIImage imageNamed:@"icon_star_empty_large"]];
    headerRatingView.padding = 12;
    headerRatingView.alignment = RateViewAlignmentLeft;
    if ([self.user.idString isEqualToString:self.content.author.idString])
        headerRatingView.editable = YES;
    else
        headerRatingView.editable = NO;    NSNumber *rating=[[_content.annotations objectForKey:@"rating"] objectAtIndex:0];
    headerRatingView.rate=[rating floatValue]/20;
    headerRatingView.delegate = self;
    
    NSNumber * value = [[_content.annotations objectForKey:@"rating"] objectAtIndex:0];
    NSDictionary *rating1 = @{@"default":value};
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:rating1 options:0 error:NULL];
    _ratingjsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    [_description addSubview:headerRatingView];
    
//    //pros
//    UILabel *headerProsLable = [[UILabel alloc] initWithFrame:CGRectMake(15, 136, 30, 28)];
//    [headerProsLable
//     setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin)];
//    [headerProsLable setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:15]];
//    [headerProsLable setTextColor:UIColorFromRGB(0x969696)];
//    [headerProsLable setText:@"Pros"];
//    [_description addSubview:headerProsLable];
//    
//    //pros TextField
//    CGSize prosTestSize = [[headerProsLable text] sizeWithAttributes:@{NSFontAttributeName:[headerProsLable font]}];
//    CGFloat ProsStrikeWidth = prosTestSize.width;
//    self.prosTextField = [[UITextField alloc] initWithFrame:CGRectMake(ProsStrikeWidth+25, 136, 260, 28)];
//    [self.prosTextField
//     setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin)];
//    [self.prosTextField setFont:[UIFont fontWithName:@"Georgia" size:18.0f]];
//    [self.prosTextField setTextColor:UIColorFromRGB(0x474C52)];
////    [self.prosTextField setPlaceholder:@"Enter Pros"];
//    
//    [_description addSubview:self.prosTextField];
//
//    
//    //cons
//    // initialize
//    UILabel *consTitleLable = [[UILabel alloc] initWithFrame:CGRectMake(15, 196, 40, 28)];
//    [consTitleLable
//     setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin)];
//    [consTitleLable setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:15]];
//    [consTitleLable setTextColor:UIColorFromRGB(0x969696)];
//    [consTitleLable setText:@"Cons"];
//    [_description addSubview:consTitleLable];
//    
//    //cons TextField
//    CGSize consTestSize = [[consTitleLable text] sizeWithAttributes:@{NSFontAttributeName:[consTitleLable font]}];
//    CGFloat consStrikeWidth = consTestSize.width;
//    self.consTextField = [[UITextField alloc] initWithFrame:CGRectMake(consStrikeWidth+25, 196, 260, 28)];
//    
//    [self.consTextField
//     setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin)];
//    [self.consTextField setFont:[UIFont fontWithName:@"Georgia" size:18.0f]];
//    [self.consTextField setTextColor:UIColorFromRGB(0x474C52)];
//    [self.consTextField setPlaceholder:@"Enter Cons"];
//    [_description addSubview:self.consTextField];
//
    
    
//    UIView *addPhotoImageView=[[UIView alloc]initWithFrame:CGRectMake(0, screenHeight-265, 320, 50)];
//    [addPhotoImageView setBackgroundColor:UIColorFromRGB(0xF3F3F3)];
//    addPhotoImageView.alpha=0.8;
//    
//    UIButton *addImageButton=[[UIButton alloc]initWithFrame:CGRectMake(100,11, 30, 24)];
//    [addImageButton setImage:[UIImage imageNamed:@"icon_photo"] forState:UIControlStateNormal];
//    [addPhotoImageView addSubview:addImageButton];
    
    
    UIButton *addPhoto=[[UIButton alloc]initWithFrame:CGRectMake(116,11, 100, 28)];
    [addPhoto setTitle:@"Add Photo" forState:UIControlStateNormal];
//    [addPhotoImageView addSubview:addPhoto];
    addPhoto.titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
    [addPhoto setTitleColor:UIColorFromRGB(0x80848B) forState:UIControlStateNormal];
    [addPhoto addTarget:self action:@selector(addPhotoClicked) forControlEvents:UIControlEventTouchUpInside];
    
    CAShapeLayer *line1=[self drawline:CGPointMake(0, 60) :CGPointMake(320, 60)];
    [_description.layer addSublayer:line1];
    
    CAShapeLayer *line2=[self drawline:CGPointMake(0, 120) :CGPointMake(320, 120)];
    [_description.layer addSublayer:line2];
    
//    CAShapeLayer *line3=[self drawline:CGPointMake(0, 180) :CGPointMake(320, 180)];
//    [_description.layer addSublayer:line3];
//    
//    CAShapeLayer *line5=[self drawline:CGPointMake(0, 240) :CGPointMake(320, 240)];
//    [_description.layer addSublayer:line5];
    
    [self.view addSubview:Scrool];
//    [self.view addSubview:addPhotoImageView];
    
    CAShapeLayer *line4=[self drawline:CGPointMake(0, screenHeight-265) :CGPointMake(320, screenHeight-265)];
    [self.view.layer addSublayer:line4];
    
    //Do any additional setup after loading the view.
}


-(void)addPhotoClicked{
    
    
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
- (void)rateView:(DYRateView *)rateView changedToNewRate:(NSNumber *)rate{
    NSNumber * value = rate;
    value= @([value floatValue] * 20);
    NSDictionary *rating = @{@"default":value};
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:rating options:0 error:NULL];
    _ratingjsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)cancelClicked:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)actionClicked:(id)sender {
    
    static NSString* const kFailurePostTitle = @"Failed to post content";
    
    if (self.titleTextField.text.length==0) {
        
        [[[UIAlertView alloc]
          initWithTitle:kFailurePostTitle
          message:@"Your review must include a title"
          delegate:nil
          cancelButtonTitle:@"OK"
          otherButtonTitles:nil] show];
    }
  
    else if (self.description.text.length ==0 ){
        [[[UIAlertView alloc]
          initWithTitle:kFailurePostTitle
          message:@"Your review must include a review body"
          delegate:nil
          cancelButtonTitle:@"OK"
          otherButtonTitles:nil] show];
    }
    else if ([self.ratingjsonString isEqualToString:nil] ){
        
        [[[UIAlertView alloc]
          initWithTitle:kFailurePostTitle
          message:@"Your review must include a star rating"
          delegate:nil
          cancelButtonTitle:@"OK"
          otherButtonTitles:nil] show];
    }
    
    else{
        [ _description.text stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];

    _bodyofReview=[NSString stringWithFormat:@"%@",_description.text];
        NSString *userToken = [self.collection objectForKey:@"lftoken"];
        if (userToken != nil) {
            NSMutableDictionary *dict=[[NSMutableDictionary alloc]initWithObjectsAndKeys:_ratingjsonString, LFSCollectionPostRatingKey,_bodyofReview,LFSCollectionPostBodyKey,userToken,LFSCollectionPostUserTokenKey,self.titleTextField.text,LFSCollectionPostTitleKey, nil ];
          
            
            id<LFSEditViewControllerDelegate> collectionViewController = nil;
            if ([self.delegate respondsToSelector:@selector(collectionViewController)]) {
                collectionViewController = [self.delegate collectionViewController];
            }
            
            [self.writeClient postMessage:LFSMessageEdit
                               forContent:self.content.idString
                             inCollection:self.collectionId
                                userToken:userToken
                               parameters:dict
                                onSuccess:^(NSOperation *operation, id responseObject) {
 
                                    if ([collectionViewController respondsToSelector:@selector(didPostContentWithOperation:response:)])
                                    {
                                        [collectionViewController didPostContentWithOperation:operation response:responseObject];
                                    }
                                    [_content1 addContent:[responseObject objectForKey:@"messages"]
                                             withAuthors:[responseObject objectForKey:@"authors"]];

                                } onFailure:^(NSOperation *operation, NSError *error) {
                                    [[[UIAlertView alloc]
                                      initWithTitle:nil
                                      message:@"An error has occurred. Please try again."
                                      delegate:nil
                                      cancelButtonTitle:@"OK"
                                      otherButtonTitles:nil] show];
                                }];
            
            [self dismissViewControllerAnimated:YES completion:nil];

        }
    }
    
    
}

@end
