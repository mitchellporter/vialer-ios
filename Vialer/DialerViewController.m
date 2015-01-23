//
//  DialerViewController.m
//  Vialer
//
//  Created by Reinier Wieringa on 15/11/13.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import "DialerViewController.h"
#import "AppDelegate.h"
#import "ConnectionHandler.h"
#import "NumberPadViewController.h"
#import "SIPCallingViewController.h"

#import "AFNetworkReachabilityManager.h"

#import <AudioToolbox/AudioServices.h>
#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCall.h>

@interface DialerViewController ()
@property (nonatomic, strong) CTCallCenter *callCenter;
@property (nonatomic, strong) NumberPadViewController *numberPadViewController;
@end

@implementation DialerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Call", nil);
        self.tabBarItem.image = [UIImage imageNamed:@"call"];

        __weak typeof(self) weakSelf = self;
        self.callCenter = [[CTCallCenter alloc] init];
        [self.callCenter setCallEventHandler:^(CTCall *call) {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.backButton.hidden = YES;
                weakSelf.numberTextView.text = @"";
            });
            NSLog(@"callEventHandler2: %@", call.callState);
        }];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionStatusChangedNotification:) name:ConnectionStatusChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sipCallStartedNotification:) name:SIPCallStartedNotification object:nil];

    self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.width);

    self.numberPadViewController = [[NumberPadViewController alloc] init];
    self.numberPadViewController.view.frame = self.buttonsView.bounds;
    [self.buttonsView addSubview:self.numberPadViewController.view];
    [self addChildViewController:self.numberPadViewController];
    self.numberPadViewController.delegate = self;
    self.numberPadViewController.tonesEnabled = YES;

    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(backButtonLongPress:)];
    [self.backButton addGestureRecognizer:longPress];
    
    self.backButton.hidden = YES;

    [self.callButton setTitle:([ConnectionHandler sharedConnectionHandler].connectionStatus == ConnectionStatusHigh && [ConnectionHandler sharedConnectionHandler].accountStatus == GSAccountStatusConnected ? [NSString stringWithFormat:@"%@ SIP", NSLocalizedString(@"Call", nil)] : NSLocalizedString(@"Call", nil)) forState:UIControlStateNormal];
//    [self.callButton setTitle:NSLocalizedString(@"Call", nil) forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    CGRect frame = [UIScreen mainScreen].bounds;
    frame.size.height -= 49.f;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0f) {
        frame.origin.y -= 20.0f;
    }
    self.view.frame = frame;
    
    if ([UIScreen mainScreen].bounds.size.height < 568.f) {
        self.callButton.frame = CGRectMake(0, frame.size.height - 46.f, self.view.frame.size.width, 46.f);
    }
}

- (void)connectionStatusChangedNotification:(NSNotification *)notification {
    [self.callButton setTitle:([ConnectionHandler sharedConnectionHandler].connectionStatus == ConnectionStatusHigh && [ConnectionHandler sharedConnectionHandler].accountStatus == GSAccountStatusConnected ? [NSString stringWithFormat:@"%@ SIP", NSLocalizedString(@"Call", nil)] : NSLocalizedString(@"Call", nil)) forState:UIControlStateNormal];
}

- (void)sipCallStartedNotification:(NSNotification *)notification {
    self.backButton.hidden = YES;
    self.numberTextView.text = @"";
}

#pragma mark - TextView delegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSString *newString = [textView.text stringByReplacingCharactersInRange:range withString:text];
    NSMutableCharacterSet *characterSet = [NSMutableCharacterSet characterSetWithCharactersInString:@"0123456789+#*() "];
    if (newString.length != [[newString componentsSeparatedByCharactersInSet:[characterSet invertedSet]] componentsJoinedByString:@""].length) {
        return NO;
    }

    self.backButton.hidden = NO;

    return YES;
}

#pragma mark - Actions

- (void)backButtonLongPress:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        self.numberTextView.text = @"";
        self.backButton.hidden = YES;
    }
}

- (IBAction)dialerBackButtonPressed:(UIButton *)sender {
    if (self.numberTextView.text.length) {
        self.numberTextView.text = [self.numberTextView.text substringToIndex:self.numberTextView.text.length - 1];
    }
    self.backButton.hidden = (self.numberTextView.text.length == 0);
}

- (IBAction)callButtonPressed:(UIButton *)sender {
    NSString *phoneNumber = self.numberTextView.text;
    if (!phoneNumber.length) {
        return;
    }

    AppDelegate *appDelegate = ((AppDelegate *)[UIApplication sharedApplication].delegate);
    [appDelegate handlePhoneNumber:phoneNumber];
}

#pragma mark - NumberPadViewController delegate

- (void)numberPadPressedWithCharacter:(NSString *)character {
    if (!self.numberTextView.text) {
        self.numberTextView.text = @"";
    }

    if ([character isEqualToString:@"+"] && self.numberTextView.text.length > 0) {
        self.numberTextView.text = [self.numberTextView.text substringToIndex:self.numberTextView.text.length - 1];
    }
    self.numberTextView.text = [self.numberTextView.text stringByAppendingString:character];

    self.backButton.hidden = NO;
}

@end
