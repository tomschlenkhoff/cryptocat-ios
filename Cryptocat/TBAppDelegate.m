//
//  TBAppDelegate.m
//  Cryptocat
//
//  Created by Thomas Balthazar on 23/09/13.
//  Copyright (c) 2013 Thomas Balthazar. All rights reserved.
//

#import "TBAppDelegate.h"
#import "TBXMPPManager.h"
#import "TBXMPPMessagesHandler.h"
#import "TBLoginViewController.h"
#import "TBChatViewController.h"
#import "NSString+Cryptocat.h"
#import <TBMultipartyProtocolManager.h>
#import <TBOTRManager.h>
#import "XMPPRoom.h"
#import "NSError+Cryptocat.h"

#define kDomain           @"crypto.cat"
#define kConferenceDomain @"conference.crypto.cat"

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TBAppDelegate () <
  TBXMPPManagerDelegate,
  TBOTRManagerDelegate,
  TBChatViewControllerDelegate,
  TBLoginViewControllerDelegate
>

@property (nonatomic, strong) TBMultipartyProtocolManager *multipartyProtocolManager;
@property (nonatomic, strong) TBOTRManager *OTRManager;
@property (nonatomic, strong) TBXMPPManager *XMPPManager;
@property (nonatomic, strong) TBXMPPMessagesHandler *XMPPMessageHandler;
@property (nonatomic, strong) TBChatViewController *chatViewController;
@property (nonatomic, strong) TBLoginViewController *loginViewController;

- (BOOL)isLoginScreenPresented;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TBAppDelegate

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Application Lifecycle

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  // xmpp manager
  self.XMPPManager = [[TBXMPPManager alloc] init];
  self.XMPPManager.delegate = self;

  // multiparty chat manager
  self.multipartyProtocolManager = [TBMultipartyProtocolManager sharedMultipartyProtocolManager];
  
  // otr manager
  self.OTRManager = [TBOTRManager sharedOTRManager];
  self.OTRManager.delegate = self;

  // message handler
  self.XMPPMessageHandler = [[TBXMPPMessagesHandler alloc] initWithOTRManager:self.OTRManager
                                                    multipartyProtocolManager:
                                                                    self.multipartyProtocolManager];
  
  // get the chatVC
  UINavigationController *nc = (UINavigationController *)self.window.rootViewController;
  self.chatViewController = (TBChatViewController *)nc.topViewController;
  self.chatViewController.delegate = self;
  
  return YES;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)applicationWillResignActive:(UIApplication *)application {
  // Sent when the application is about to move from active to inactive state.
  // This can occur for certain types of temporary interruptions (such as an incoming phone call
  // or SMS message) or when the user quits the application and it begins the transition to the
  // background state. Use this method to pause ongoing tasks, disable timers, and throttle down
  // OpenGL ES frame rates. Games should use this method to pause the game.
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)applicationDidEnterBackground:(UIApplication *)application {
  // Use this method to release shared resources, save user data, invalidate timers, and store
  // enough application state information to restore your application to its current state in case
  // it is terminated later. If your application supports background execution, this method is
  // called instead of applicationWillTerminate: when the user quits.
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)applicationWillEnterForeground:(UIApplication *)application {
  // Called as part of the transition from the background to the inactive state;
  // here you can undo many of the changes made on entering the background.
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)applicationDidBecomeActive:(UIApplication *)application {
  // Restart any tasks that were paused (or not yet started) while the application was inactive.
  // If the application was previously in the background, optionally refresh the user interface.
  
  // if xmpp is not connected or connecting, show loginVC
  if (!self.XMPPManager.xmppStream.isConnected && !self.XMPPManager.xmppStream.isConnecting) {
    // show loginVC
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *loginNC = [storyboard
                                       instantiateViewControllerWithIdentifier:@"LoginNCID"];
    self.loginViewController = (TBLoginViewController *)loginNC.topViewController;
    self.loginViewController.delegate = self;
    [self.chatViewController presentViewController:loginNC
                                          animated:NO
                                        completion:NULL];
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)applicationWillTerminate:(UIApplication *)application {
  // Called when the application is about to terminate.
  // Save data if appropriate. See also applicationDidEnterBackground:.
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private Methods

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)isLoginScreenPresented {
  TBChatViewController *cvc = self.chatViewController;
  BOOL cvcPresentedVCIsNC = [cvc.presentedViewController
                             isKindOfClass:[UINavigationController class]];
  if (!cvcPresentedVCIsNC) return NO;
  
  UINavigationController *nc = (UINavigationController *)cvc.presentedViewController;
  return [nc.topViewController isKindOfClass:[TBLoginViewController class]];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark TBXMPPManagerDelegate

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)XMPPManager:(TBXMPPManager *)XMPPManager didJoinRoom:(XMPPRoom *)room {
  NSString *account = room.myRoomJID.full;
  [self.OTRManager generatePrivateKeyForAccount:account protocol:TBMessagingProtocol];
  
  self.chatViewController.roomName = room.roomJID.user;
  self.chatViewController.usernames = [NSMutableArray
                                       arrayWithArray:[XMPPManager.usernames allObjects]];

  if ([self isLoginScreenPresented]) {
    [self.chatViewController dismissViewControllerAnimated:YES completion:NULL];
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)XMPPManager:(TBXMPPManager *)XMPPManager
  didReceiveMessage:(XMPPMessage *)message
          myRoomJID:(XMPPJID *)myRoomJID {
  [self.XMPPMessageHandler handleMessage:message XMPPManager:XMPPManager];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)XMPPManager:(TBXMPPManager *)XMPPManager usernameDidSignIn:(NSString *)username {
  TBLOG(@"-- %@ signed in", username);

  if (![username isEqualToString:XMPPManager.myNickname]) {
    UINavigationController *nc = (UINavigationController *)self.window.rootViewController;
    TBChatViewController *cvc = (TBChatViewController *)nc.topViewController;
    [cvc.usernames addObject:username];
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)XMPPManager:(TBXMPPManager *)XMPPManager usernameDidSignOut:(NSString *)username {
  TBLOG(@"-- %@ signed out", username);
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)XMPPManager:(TBXMPPManager *)XMPPManager usernameDidGoAway:(NSString *)username {
  TBLOG(@"-- %@ went away", username);
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)XMPPManager:(TBXMPPManager *)XMPPManager
didTryToRegisterAlreadyInUseUsername:(NSString *)username {
  if ([self isLoginScreenPresented]) {
    NSString *message = NSLocalizedString(@"Nickname in use.", @"Nickname in use. Error Message");
    [self.loginViewController showError:[NSError tb_errorWithMessage:message]];
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)XMPPManagerDidFailToAuthenticate:(TBXMPPManager *)XMPPManager {
  if ([self isLoginScreenPresented]) {
    NSString *message = NSLocalizedString(@"Authentication failure.",
                                          @"Authentication failure. Error Message");
    [self.loginViewController showError:[NSError tb_errorWithMessage:message]];
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)XMPPManagerDidFailToConnect:(TBXMPPManager *)XMPPManager {
  if ([self isLoginScreenPresented]) {
    NSString *message = NSLocalizedString(@"Connection failed.",
                                          @"Connection failed. Error Message");
    [self.loginViewController showError:[NSError tb_errorWithMessage:message]];
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark TBChatViewControllerDelegate

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)chatViewController:(TBChatViewController *)controller
       didAskToSendMessage:(NSString *)message {
  [self.XMPPMessageHandler sendGroupMessage:message XMPPManager:self.XMPPManager];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)chatViewController:(TBChatViewController *)controller
       didAskToSendMessage:(NSString *)message
                    toUser:(NSString *)recipient {
  [self.XMPPMessageHandler sendMessageWithBody:message
                                     recipient:recipient
                                   XMPPManager:self.XMPPManager];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark TBOTRManagerDelegate

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)OTRManager:(TBOTRManager *)OTRManager
       sendMessage:(NSString *)message
       accountName:(NSString *)accountName
                to:(NSString *)recipient
          protocol:(NSString *)protocol {
  [self.XMPPMessageHandler sendMessageWithBody:message
                                     recipient:recipient
                                   XMPPManager:self.XMPPManager];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark TBLoginViewControllerDelegate

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)loginController:(TBLoginViewController *)controller
didAskToConnectWithRoomName:(NSString *)roomName
               nickname:(NSString *)nickname {
  NSString *username = [NSString tb_randomStringWithLength:16];
  NSString *password = [NSString tb_randomStringWithLength:16];
  NSString *domain = kDomain;
  NSString *conferenceDomain = kConferenceDomain;
  
  BOOL isConnected = [self.XMPPManager connectWithUsername:username
                                                  password:password
                                                    domain:domain
                                          conferenceDomain:conferenceDomain
                                                  roomName:roomName
                                                  nickname:nickname];
  self.multipartyProtocolManager.myName = self.XMPPManager.myNickname;
  
  TBLOG(@"-- isConnected : %d", isConnected);
}

@end
