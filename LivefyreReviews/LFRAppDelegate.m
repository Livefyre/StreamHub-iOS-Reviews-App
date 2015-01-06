//
//  LFRAppDelegate.m
//  LivefyreReviews
//
//  Created by sunil maganti on 6/8/14.
//  Copyright (c) 2014 Kvana Inc. All rights reserved.
//

#import "LFRAppDelegate.h"
#import <AFHTTPRequestOperationLogger/AFHTTPRequestOperationLogger.h>
#import <OHAttributedLabel/OHAttributedLabel.h>
#import "LFSAttributedTextCell.h"
#import <FPPicker/FPPicker.h>
typedef NS_ENUM(NSUInteger, kTwitterAppState) {
    kTwitterAppStateUnknown = 0u,
    kTwitterAppStateTwitter,
    kTwitterAppStateBrowser
};
@implementation LFRAppDelegate

@synthesize mainStoryboard = _mainStoryboard;
-(UIStoryboard*)mainStoryboard {
    static NSString* const kLFSMainStoryboardId = @"Main";
    if (_mainStoryboard == nil) {
        _mainStoryboard = [UIStoryboard
                           storyboardWithName:kLFSMainStoryboardId
                           bundle:nil];
    }
    return _mainStoryboard;
}
#pragma mark - Public methods

-(NSString*)processStreamUrl:(NSString*)urlString
{
    static NSRegularExpression* regexHashtag = nil;
    static NSRegularExpression* regexHandle = nil;
    static NSRegularExpression* regexStatus = nil;
    
    // check if urlString is a hashtag
    if (regexHashtag == nil) {
        NSError *error = nil;
        regexHashtag = [NSRegularExpression
                        regularExpressionWithPattern:@"^(http|https)://twitter.com/(#!/)?search/realtime/([^/]*?)$"
                        options:0 error:&error];
        NSAssert(error == nil, @"Error creating regex: %@",
                 error.localizedDescription);
    }
    NSTextCheckingResult *hashtagMatch =
    [regexHashtag firstMatchInString:urlString
                             options:0
                               range:NSMakeRange(0, [urlString length])];
    if (hashtagMatch != nil) {
        // have match, now create Twitter URI, open Twitter app here, and return
        NSString *schemaString = [urlString substringWithRange:[hashtagMatch rangeAtIndex:1u]];
        NSString *contentString = [urlString substringWithRange:[hashtagMatch rangeAtIndex:3u]];
        // [NSString stringWithFormat:@"twitter://search?query=%@", contentString]
        NSString *convertedURL = [NSString stringWithFormat:@"%@://twitter.com/search/realtime/%@",
                                  schemaString, contentString];
        return convertedURL;
    }
    
    // if we are still here, look for possible user handle
    if (regexHandle == nil) {
        NSError *error = nil;
        regexHandle = [NSRegularExpression
                       regularExpressionWithPattern:@"^(http|https)://twitter.com/(#!/)?([^/]*?)$"
                       options:0 error:&error];
        NSAssert(error == nil, @"Error creating regex: %@",
                 error.localizedDescription);
    }
    NSTextCheckingResult *handleMatch =
    [regexHandle firstMatchInString:urlString
                            options:0
                              range:NSMakeRange(0, [urlString length])];
    if (handleMatch != nil) {
        // have match, now create Twitter URI, open Twitter app here, and return
        NSString *schemaString = [urlString substringWithRange:[handleMatch rangeAtIndex:1u]];
        NSString *contentString = [urlString substringWithRange:[handleMatch rangeAtIndex:3u]];
        // [NSString stringWithFormat:@"twitter://user?screen_name=%@", contentString]
        NSString *convertedURL = [NSString stringWithFormat:@"%@://twitter.com/%@",
                                  schemaString, contentString];
        return convertedURL;
    }
    
    // if we are still here, check for status URI
    if (regexStatus == nil) {
        NSError *error = nil;
        regexStatus = [NSRegularExpression
                       regularExpressionWithPattern:@"^(http|https)://twitter.com/(#!/)?([^/]*?)/status/([^/]*?)$"
                       options:0 error:&error];
        NSAssert(error == nil, @"Error creating regex: %@",
                 error.localizedDescription);
    }
    NSTextCheckingResult *statusMatch =
    [regexStatus firstMatchInString:urlString
                            options:0
                              range:NSMakeRange(0, [urlString length])];
    if (statusMatch != nil) {
        // have match, now create Twitter URI, open Twitter app here, and return
        NSString *schemaString = [urlString substringWithRange:[statusMatch rangeAtIndex:1u]];
        NSString *accountString = [urlString substringWithRange:[statusMatch rangeAtIndex:3u]];
        NSString *statusIdString = [urlString substringWithRange:[statusMatch rangeAtIndex:4u]];
        // [NSString stringWithFormat:@"twitter://status?id=%@&account=%@", statusIdString, accountString]
        NSString *convertedURL = [NSString stringWithFormat:@"%@://twitter.com/%@/status/%@",
                                  schemaString, accountString, statusIdString];
        return convertedURL;
    }
    
    return urlString;
}

+ (void)initialize
{
//    [FPConfig sharedInstance].APIKey = @"FILEPICKER_API_KEY" ;
    [FPConfig sharedInstance].APIKey=[[NSBundle mainBundle] objectForInfoDictionaryKey:@"Filepicker API Key"];
    
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    //[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];

    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
#ifdef LOG_ALL_HTTP_REQUESTS
    [[AFHTTPRequestOperationLogger sharedLogger] stopLogging];
#endif
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
#ifdef LOG_ALL_HTTP_REQUESTS
    [[AFHTTPRequestOperationLogger sharedLogger] startLogging];
#endif
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
