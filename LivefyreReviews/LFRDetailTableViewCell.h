//
//  LFRDetailTableViewCell.h
//  LiveFyreReviewsIOS2
//
//  Created by kvana inc on 28/06/14.
//  Copyright (c) 2014 kvana inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LFSBasicHTMLLabel.h"
#import "LFSBasicHTMLParser.h"
#import "DYRateView.h"
#import "LFSContentToolbar.h"


@interface LFRDetailTableViewCell : UITableViewCell<DYRateViewDelegate>
 @property (readonly, nonatomic) LFSContentToolbar *toolbar;

@property (nonatomic, strong) UIImageView *profileImage;
@property (nonatomic, strong) UILabel *userName;
@property (nonatomic, strong) UILabel *moderator;
@property (nonatomic, strong) UILabel *date;
@property (nonatomic, strong) LFSBasicHTMLLabel *title;
@property (nonatomic, strong) LFSBasicHTMLLabel *body;
@property (nonatomic, strong) UILabel *footerLeftView;
@property (nonatomic, strong) UILabel *footerRightView;
@property (nonatomic, strong) DYRateView *rateView;
@property (readonly, nonatomic) UIButton *button1;
@property (readonly, nonatomic) UIButton *button2;
@property (readonly, nonatomic) UIButton *button3;
@property (nonatomic, strong) UIButton *repliesCount;
@property (nonatomic, strong) UIImageView *featuredImage;
@property (nonatomic, strong) UIImageView *attachedImage;

-(void)layoutsets;
-(void)layoutsets1;
-(void)layoutsetsForSubcell;
-(NSMutableAttributedString*)getAttributedTextWithFormat:(NSString*)text :(float) fontSize :(NSString*)fontName :(float)lineSpace;

@end

