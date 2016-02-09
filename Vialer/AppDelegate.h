//
//  AppDelegate.h
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GSCall;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

/**
 *  Core Data Parent Managed Object Context.
 *
 *  Every other object context should be a child context from this context.
 */
@property (readonly, nonatomic) NSManagedObjectContext *managedObjectContext;

- (void)handleSipCall:(GSCall *)sipCall;

/**
 * @return YES when the app was started for the purpose of taking screenshots
 */
+ (BOOL)isSnapshotScreenshotRun;

@end
