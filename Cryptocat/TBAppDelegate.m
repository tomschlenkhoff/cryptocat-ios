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
#import "TBChatViewController.h"
#import <TBMultipartyProtocolManager.h>
#import <TBOTRManager.h>

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TBAppDelegate () <
  TBXMPPManagerDelegate,
  TBOTRManagerDelegate,
  TBChatViewControllerDelegate
>

@property (nonatomic, strong) TBMultipartyProtocolManager *multipartyProtocolManager;
@property (nonatomic, strong) TBOTRManager *OTRManager;
@property (nonatomic, strong) TBXMPPManager *XMPPManager;
@property (nonatomic, strong) TBXMPPMessagesHandler *XMPPMessageHandler;

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
  NSString *username = [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]];
  NSString *password = @"foqmlsdkfj qsmldkfj lmkqsjfd";
  NSString *domain = @"crypto.cat";
  NSString *conferenceDomain = @"conference.crypto.cat";
  NSString *roomName = @"cryptocatdev";
  NSString *nickname = @"iOSTestApp";
  
  // xmpp manager
  self.XMPPManager = [[TBXMPPManager alloc] initWithUsername:username
                                                    password:password
                                                      domain:domain
                                            conferenceDomain:conferenceDomain
                                                        roomName:roomName
                                                    nickname:nickname];
  self.XMPPManager.delegate = self;
  [self.XMPPManager connect];

  // multiparty chat manager
  self.multipartyProtocolManager = [TBMultipartyProtocolManager sharedMultipartyProtocolManager];
  self.multipartyProtocolManager.myName = self.XMPPManager.myNickname;
  
  // otr manager
  self.OTRManager = [TBOTRManager sharedOTRManager];
  self.OTRManager.delegate = self;

  // message handler
  self.XMPPMessageHandler = [[TBXMPPMessagesHandler alloc] initWithOTRManager:self.OTRManager
                                                    multipartyProtocolManager:
                                                                    self.multipartyProtocolManager];
  
  UINavigationController *nc = (UINavigationController *)self.window.rootViewController;
  TBChatViewController *cvc = (TBChatViewController *)nc.topViewController;
  cvc.roomName = roomName;
  cvc.delegate = self;
  
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
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)applicationWillTerminate:(UIApplication *)application {
  // Called when the application is about to terminate.
  // Save data if appropriate. See also applicationDidEnterBackground:.
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark TBXMPPManagerDelegate

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)XMPPManager:(TBXMPPManager *)XMPPManager
  didReceiveMessage:(XMPPMessage *)message
          myRoomJID:(XMPPJID *)myRoomJID {
  [self.XMPPMessageHandler handleMessage:message XMPPManager:XMPPManager];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)XMPPManager:(TBXMPPManager *)XMPPManager usernameDidSignIn:(NSString *)username {
  TBLOG(@"-- %@ signed in", username);
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
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark TBChatViewControllerDelegate

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)chatViewController:(TBChatViewController *)controller
       didAskToSendMessage:(NSString *)message {
  [self.XMPPMessageHandler sendGroupMessage:message XMPPManager:self.XMPPManager];
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
  [self.XMPPManager sendMessageWithBody:message recipient:recipient];
}

@end
