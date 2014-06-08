//
//  LFRAppDelegate.h
//  LivefyreReviews
//
//  Created by sunil maganti on 6/8/14.
//  Copyright (c) 2014 Kvana Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#define AppDelegate (LFRAppDelegate *)[[UIApplication sharedApplication] delegate]

@interface LFRAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) UIStoryboard *mainStoryboard;

-(NSString*)processStreamUrl:(NSString*)urlString;

@end
