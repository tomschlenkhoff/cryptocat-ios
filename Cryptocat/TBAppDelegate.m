//
//  TBAppDelegate.m
//  Cryptocat
//
//  Created by Thomas Balthazar on 23/09/13.
//  Copyright (c) 2013 Thomas Balthazar. All rights reserved.
//
//  This file is part of Cryptocat for iOS.
//
//  Cryptocat for iOS is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Cryptocat for iOS is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Cryptocat for iOS.  If not, see <http://www.gnu.org/licenses/>.
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
#import "TBBuddy.h"
#import "TBMessage.h"
#import "XMPPPresence+Cryptocat.h"
#import "UIColor+Cryptocat.h"
#import "TBLoginNavigationController.h"

typedef void (^TBGoneSecureCompletionBlock)();

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TBAppDelegate () <
  TBXMPPManagerDelegate,
  TBOTRManagerDelegate,
  TBMultipartyProtocolManagerDelegate,
  TBChatViewControllerDelegate,
  TBLoginViewControllerDelegate
>

@property (nonatomic, strong) TBMultipartyProtocolManager *multipartyProtocolManager;
@property (nonatomic, strong) TBOTRManager *OTRManager;
@property (nonatomic, strong) TBXMPPManager *XMPPManager;
@property (nonatomic, strong) TBXMPPMessagesHandler *XMPPMessageHandler;
@property (nonatomic, strong) TBChatViewController *chatViewController;
@property (nonatomic, strong) TBLoginViewController *loginViewController;
@property (nonatomic, strong) NSMutableDictionary *goneSecureCompletionBlocks;
@property (nonatomic, assign) UIBackgroundTaskIdentifier bgTaskIdentifier;

- (BOOL)isLoginScreenPresented;
- (BOOL)presentLoginVCAnimated:(BOOL)animated;
- (void)addCompletionBlock:(TBGoneSecureCompletionBlock)completionBlock
                   forUser:(TBBuddy *)user
                 recipient:(TBBuddy *)recipient;
- (void)executeGoneSecureCompletionBlocsForUser:(NSString *)user recipient:(NSString *)recipient;
- (void)startObservingForMessages;
- (void)stopObservingForMessages;
- (void)notifyUserOfBgSessionEnd;
- (void)logout;

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
  self.goneSecureCompletionBlocks = [NSMutableDictionary dictionary];
  
  // get the chatVC
  UINavigationController *nc = (UINavigationController *)self.window.rootViewController;
  self.chatViewController = (TBChatViewController *)nc.topViewController;
  self.chatViewController.delegate = self;
  
  // customize appearance
  [[UINavigationBar appearance] setBarTintColor:[UIColor tb_navigationBarColor]];
  [[UIView appearance] setTintColor:[UIColor tb_buttonTitleColor]];
  [[UINavigationBar appearance] setTitleTextAttributes:
    @{NSForegroundColorAttributeName: [UIColor whiteColor]}];
  [[UITableView appearance] setBackgroundColor:[UIColor tb_backgroundColor]];
  
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
  XMPPPresence *presence = [XMPPPresence tb_awayPresenceForJID:self.XMPPManager.xmppRoom.myRoomJID];
  [self.XMPPManager.xmppStream sendElement:presence];

  [self startObservingForMessages];
  self.bgTaskIdentifier = [application beginBackgroundTaskWithExpirationHandler:^{
    [self stopObservingForMessages];
    [self logout];
    [application endBackgroundTask:self.bgTaskIdentifier];
    self.bgTaskIdentifier = UIBackgroundTaskInvalid;
  }];
  
  // if a chat session is open, notify the user 60 sec before the bg task finishes
  if (self.XMPPManager.xmppStream.isConnected) {
    NSTimeInterval bgTimeoutDelay = application.backgroundTimeRemaining - 60.0;
    [self performSelector:@selector(notifyUserOfBgSessionEnd)
               withObject:nil
               afterDelay:bgTimeoutDelay];
    TBLOG(@"-- remaining time : %.1f", application.backgroundTimeRemaining);
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)applicationWillEnterForeground:(UIApplication *)application {
  // Called as part of the transition from the background to the inactive state;
  // here you can undo many of the changes made on entering the background.
  [self stopObservingForMessages];
  [NSObject cancelPreviousPerformRequestsWithTarget:self
                                           selector:@selector(notifyUserOfBgSessionEnd)
                                             object:nil];
  
  [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
  [[UIApplication sharedApplication] cancelAllLocalNotifications];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)applicationDidBecomeActive:(UIApplication *)application {
  // Restart any tasks that were paused (or not yet started) while the application was inactive.
  // If the application was previously in the background, optionally refresh the user interface.
  [self presentLoginVCAnimated:NO];
  
  XMPPPresence *presence = [XMPPPresence
                            tb_availablePresenceForJID:self.XMPPManager.xmppRoom.myRoomJID];
  [self.XMPPManager.xmppStream sendElement:presence];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)applicationWillTerminate:(UIApplication *)application {
  // Called when the application is about to terminate.
  // Save data if appropriate. See also applicationDidEnterBackground:.
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private Properties

////////////////////////////////////////////////////////////////////////////////////////////////////
- (TBXMPPManager *)XMPPManager {
  if (_XMPPManager==nil) {
    _XMPPManager = [[TBXMPPManager alloc] init];
    _XMPPManager.delegate = self;
  }
  
  return _XMPPManager;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (TBMultipartyProtocolManager *)multipartyProtocolManager {
  if (_multipartyProtocolManager==nil) {
    _multipartyProtocolManager = [[TBMultipartyProtocolManager alloc] init];
    _multipartyProtocolManager.delegate = self;
  }
  
  return _multipartyProtocolManager;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (TBOTRManager *)OTRManager {
  if (_OTRManager==nil) {
    _OTRManager = [TBOTRManager sharedOTRManager];
    _OTRManager.delegate = self;
  }
  
  return _OTRManager;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (TBXMPPMessagesHandler *)XMPPMessageHandler {
  if (_XMPPMessageHandler==nil) {
    _XMPPMessageHandler = [[TBXMPPMessagesHandler alloc] initWithOTRManager:self.OTRManager
                                          multipartyProtocolManager:self.multipartyProtocolManager];
  }
  
  return _XMPPMessageHandler;
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
- (BOOL)presentLoginVCAnimated:(BOOL)animated {
  if (![self isLoginScreenPresented] &&
      !self.XMPPManager.isConnected && !self.XMPPManager.isConnecting) {
    // show loginVC
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    TBLoginNavigationController *loginNC = [storyboard
                                       instantiateViewControllerWithIdentifier:@"LoginNCID"];
    loginNC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    self.loginViewController = (TBLoginViewController *)loginNC.topViewController;
    self.loginViewController.delegate = self;
    [self.chatViewController presentViewController:loginNC
                                          animated:animated
                                        completion:NULL];
    return YES;
  }
  
  return NO;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)addCompletionBlock:(TBGoneSecureCompletionBlock)completionBlock
                   forUser:(TBBuddy *)user
                 recipient:(TBBuddy *)recipient {
  NSString *username = user.fullname;
  NSString *recipientName = recipient.fullname;
  
  if (username==nil || recipientName==nil) return;
  
  // make sure to have a mutable dic for each username's recipients
  if ([self.goneSecureCompletionBlocks objectForKey:user]==nil) {
    [self.goneSecureCompletionBlocks setObject:[NSMutableDictionary dictionary] forKey:username];
  }
  
  // make sure to have a mutable array for each recipient's completion blocks
  if ([[self.goneSecureCompletionBlocks objectForKey:username] objectForKey:recipientName]==nil) {
    [[self.goneSecureCompletionBlocks objectForKey:username] setObject:[NSMutableArray array]
                                                                forKey:recipientName];
  }
  
  [[[self.goneSecureCompletionBlocks objectForKey:username]
    objectForKey:recipientName] addObject:completionBlock];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)executeGoneSecureCompletionBlocsForUser:(NSString *)user recipient:(NSString *)recipient {
  // check that there are completion blocks for the account/recipient
  if ([self.goneSecureCompletionBlocks objectForKey:user]==nil ||
      [[self.goneSecureCompletionBlocks objectForKey:user] objectForKey:recipient]==nil) return;
  
  NSMutableArray *completionBlocks = [[self.goneSecureCompletionBlocks objectForKey:user]
                                      objectForKey:recipient];
  TBLOG(@"-- gone secure, will execute %d completion blocks", [completionBlocks count]);
  for (TBGoneSecureCompletionBlock completionBlock in completionBlocks) {
    completionBlock();
  }
  
  // empty the completion blocks array
  [[self.goneSecureCompletionBlocks objectForKey:user] setObject:[NSMutableArray array]
                                                          forKey:recipient];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)startObservingForMessages {
  NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
  [defaultCenter addObserver:self
                    selector:@selector(didReceiveGroupMessage:)
                        name:TBDidReceiveGroupChatMessageNotification
                      object:nil];
  [defaultCenter addObserver:self
                    selector:@selector(didReceivePrivateMessage:)
                        name:TBDidReceivePrivateChatMessageNotification
                      object:nil];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)stopObservingForMessages {
  NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
  [defaultCenter removeObserver:self name:TBDidReceiveGroupChatMessageNotification object:nil];
  [defaultCenter removeObserver:self name:TBDidReceivePrivateChatMessageNotification object:nil];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)notifyUserOfBgSessionEnd {
  UILocalNotification *messageNotification = [[UILocalNotification alloc] init];
  if (messageNotification==nil) return;
  
  NSString *body = TBLocalizedString(
                                     @"Your chat session will end in a minute if you don't come back",
                                     @"Chat session expiration message");
  
  messageNotification.alertBody = body;
  messageNotification.alertAction = TBLocalizedString(@"Ok", @"Alert View Ok Button");
  messageNotification.soundName = UILocalNotificationDefaultSoundName;
  [[UIApplication sharedApplication] presentLocalNotificationNow:messageNotification];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)logout {
  [self.chatViewController reset];

  [self.XMPPManager disconnect];
  [self presentLoginVCAnimated:YES];
  
  [self.OTRManager reset];
  self.OTRManager = nil;
  
  self.multipartyProtocolManager = nil;
  self.XMPPMessageHandler = nil;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark TBXMPPManagerDelegate

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)XMPPManager:(TBXMPPManager *)XMPPManager didJoinRoom:(XMPPRoom *)room {
  NSString *account = room.myRoomJID.full;
  [self.OTRManager generatePrivateKeyForAccount:account
                                       protocol:TBMessagingProtocol
                                completionBlock:^
  {
    XMPPManager.me.chatFingerprint = [self.OTRManager fingerprintForAccountName:account
                                                                      protocol:TBMessagingProtocol];
    XMPPManager.me.groupChatFingerprint = self.multipartyProtocolManager.fingerprint;
  }];
  
  self.chatViewController.roomName = room.roomJID.user;
  self.chatViewController.me = XMPPManager.me;
  self.chatViewController.buddies = XMPPManager.buddies;
  self.chatViewController.isReconnecting = NO;

  if ([self isLoginScreenPresented]) {
    [self.chatViewController dismissViewControllerAnimated:YES completion:NULL];
  }
  
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:room.roomJID.user forKey:@"roomName"];
  [defaults setObject:XMPPManager.me.nickname forKey:@"nickname"];
  [defaults synchronize];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)XMPPManager:(TBXMPPManager *)XMPPManager
  didReceiveMessage:(XMPPMessage *)message {
  [self.XMPPMessageHandler handleMessage:message XMPPManager:XMPPManager];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)XMPPManager:(TBXMPPManager *)XMPPManager buddyDidSignIn:(TBBuddy *)buddy {
  TBLOG(@"-- %@ signed in", buddy.fullname);

  if (![buddy isEqual:XMPPManager.me]) {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:TBBuddyDidSignInNotification object:buddy];
    
    [self.XMPPMessageHandler sendPublicKeyToRecipient:buddy XMPPManager:XMPPManager];
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)XMPPManager:(TBXMPPManager *)XMPPManager buddyDidSignOut:(TBBuddy *)buddy {
  TBLOG(@"-- %@ signed out", buddy.fullname);
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc postNotificationName:TBBuddyDidSignOutNotification object:buddy];
  [self.OTRManager disconnectRecipient:buddy.fullname
                        forAccountName:self.XMPPManager.me.fullname
                              protocol:TBMessagingProtocol];
  [self.multipartyProtocolManager disconnectUsername:buddy.nickname];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)XMPPManager:(TBXMPPManager *)XMPPManager buddyDidGoAway:(TBBuddy *)buddy {
  TBLOG(@"-- %@ went away", buddy.fullname);
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc postNotificationName:TBBuddyDidGoAwayNotification object:buddy];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)XMPPManager:(TBXMPPManager *)XMPPManager
didTryToRegisterAlreadyInUseUsername:(NSString *)username {
  if ([self isLoginScreenPresented]) {
    NSString *message = TBLocalizedString(@"Nickname in use.", @"Nickname in use. Error Message");
    [self.loginViewController showError:[NSError tb_errorWithMessage:message]];
    [self logout];
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)XMPPManagerDidFailToAuthenticate:(TBXMPPManager *)XMPPManager {
  if ([self isLoginScreenPresented]) {
    NSString *message = TBLocalizedString(@"Authentication failure.",
                                          @"Authentication failure. Error Message");
    [self.loginViewController showError:[NSError tb_errorWithMessage:message]];
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)XMPPManagerDidFailToConnect:(TBXMPPManager *)XMPPManager {
  if ([self isLoginScreenPresented]) {
    NSString *message = TBLocalizedString(@"Connection failed.",
                                          @"Connection failed. Error Message");
    [self.loginViewController showError:[NSError tb_errorWithMessage:message]];
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)XMPPManagerDidDisconnect:(TBXMPPManager *)XMPPManager {
  [self logout];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)XMPPManagerDidStartReconnecting:(TBXMPPManager *)XMPPManager {
  self.chatViewController.isReconnecting = YES;
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
                    toUser:(TBBuddy *)recipient {
  TBBuddy *account = self.XMPPManager.me;
  NSString *accountName = account.fullname;
  NSString *recipientName = recipient.fullname;
  
  // this block will send the message
  TBGoneSecureCompletionBlock goneSecureCompletionBlock = ^{
    [self.XMPPMessageHandler sendMessageWithBody:message
                                       recipient:recipient
                                     XMPPManager:self.XMPPManager];
  };
  
  // if we are already in a secure mode, send the message straight away
  if ([self.OTRManager isConversationEncryptedForAccountName:accountName
                                                   recipient:recipientName
                                                    protocol:TBMessagingProtocol]) {
    goneSecureCompletionBlock();
  }
  else {
    [self addCompletionBlock:goneSecureCompletionBlock forUser:account recipient:recipient];
    NSString *queryMsg = [self.OTRManager queryMessageForAccount:accountName];
    [self.XMPPMessageHandler sendRawMessageWithBody:queryMsg
                                          recipient:recipient
                                        XMPPManager:self.XMPPManager];
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)chatViewControllerDidStartComposing:(TBChatViewController *)controller
                               forRecipient:(TBBuddy *)recipient {
  [self.XMPPMessageHandler sendStateNotification:@"composing"
                                       recipient:recipient
                                     XMPPManager:self.XMPPManager];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)chatViewControllerDidPauseComposing:(TBChatViewController *)controller
                               forRecipient:(TBBuddy *)recipient {
  [self.XMPPMessageHandler sendStateNotification:@"paused"
                                       recipient:recipient
                                     XMPPManager:self.XMPPManager];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)chatViewControllerDidEndComposing:(TBChatViewController *)controller
                             forRecipient:(TBBuddy *)recipient {
  [self.XMPPMessageHandler sendStateNotification:@"active"
                                       recipient:recipient
                                     XMPPManager:self.XMPPManager];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)chatViewControllerDidAskToLogout:(TBChatViewController *)controller {
  [self logout];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)chatViewController:(TBChatViewController *)controller
didAskFingerprintsForBuddy:(TBBuddy *)buddy {
  NSString *accountName = self.XMPPManager.me.fullname;
  NSString *recipientName = buddy.fullname;
  
  // if we are not yet in a secure mode
  if (![self.OTRManager isConversationEncryptedForAccountName:accountName
                                                    recipient:recipientName
                                                     protocol:TBMessagingProtocol]) {
    NSString *queryMsg = [self.OTRManager queryMessageForAccount:accountName];
    [self.XMPPMessageHandler sendRawMessageWithBody:queryMsg
                                          recipient:buddy
                                        XMPPManager:self.XMPPManager];
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark TBMultipartyProtocolManagerDelegate

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)multipartyProtocolManager:(TBMultipartyProtocolManager *)manager didEstablishSecureConnectionWithUsername:(NSString *)username {
  for (TBBuddy *aBuddy in self.XMPPManager.buddies) {
    if ([aBuddy.nickname isEqualToString:username]) {
      aBuddy.groupChatFingerprint = [self.multipartyProtocolManager
                                     fingerprintForUsername:username];
      TBLOG(@"-- fingerprint for %@ is %@", username, aBuddy.groupChatFingerprint);
      break;
    }
  }

  TBLOG(@"-- group chat with %@ is now secured", username);
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
  XMPPJID *recipientJID = [XMPPJID jidWithString:recipient];
  TBBuddy *buddy = [[TBBuddy alloc] initWithXMPPJID:recipientJID];
  TBLOG(@"-- will ask to send OTR message to %@ : %@", recipient, message);
  [self.XMPPMessageHandler sendRawMessageWithBody:message
                                        recipient:buddy
                                      XMPPManager:self.XMPPManager];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)OTRManager:(TBOTRManager *)OTRManager
didUpdateEncryptionStatus:(BOOL)isEncrypted
      forRecipient:(NSString *)recipient
       accountName:(NSString *)accountName
          protocol:(NSString *)protocol {
  TBLOG(@"-- conversation with %@ is now %@", recipient, (isEncrypted ? @"secure" : @"insecure"));
  
  if (isEncrypted) {
    [self executeGoneSecureCompletionBlocsForUser:accountName recipient:recipient];
    for (TBBuddy *aBuddy in self.XMPPManager.buddies) {
      if ([aBuddy.fullname isEqualToString:recipient]) {
        aBuddy.chatFingerprint = [self.OTRManager fingerprintForRecipient:recipient
                                                              accountName:accountName
                                                                 protocol:TBMessagingProtocol];
        TBLOG(@"-- %@ now has a fingerprint : %@", recipient, aBuddy.chatFingerprint);
        break;
      }
    }
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark TBLoginViewControllerDelegate

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)loginController:(TBLoginViewController *)controller
didAskToConnectWithRoomName:(NSString *)roomName
               nickname:(NSString *)nickname {
  BOOL isConnected = [self.XMPPManager connectToRoomName:roomName withNickname:nickname];
  self.multipartyProtocolManager.myName = self.XMPPManager.me.nickname;
  
  TBLOG(@"-- isConnected : %d", isConnected);
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)loginController:(TBLoginViewController *)controller
      didChangeLanguage:(NSString *)language {
  [self.chatViewController updateLanguageDependentElements];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Observers

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didReceiveGroupMessage:(NSNotification *)notification {
  UILocalNotification *messageNotification = [[UILocalNotification alloc] init];
  if (messageNotification==nil) return;
  
  TBMessage *message = notification.object;
  NSError *error = [notification.userInfo objectForKey:@"error"];
  
  TBBuddy *sender = nil;
  if (message==nil) {
    if (error!=nil &&
        [error.domain isEqualToString:TBErrorDomainGroupChatMessage] &&
        error.code==TBErrorCodeUnreadableMessage) {
      sender = [error.userInfo objectForKey:TBErrorCodeUnreadableMessageSenderKey];
    }
  }
  else {
    sender = message.sender;
  }
  
  if (sender==nil) return;
  
  NSString *roomName = sender.roomName;
  NSString *nickname = sender.nickname;
  NSString *body = TBLocalizedString(@"%@ sent you a message in %@",
                                     @"Sender sent you a message in roomName notification text");
  NSString *alertBody = [NSString stringWithFormat:body, nickname, roomName];
  messageNotification.alertBody = alertBody;
  messageNotification.alertAction = TBLocalizedString(@"Ok", @"Alert View Ok Button");
  messageNotification.soundName = UILocalNotificationDefaultSoundName;
  [[UIApplication sharedApplication] presentLocalNotificationNow:messageNotification];
  [UIApplication sharedApplication].applicationIconBadgeNumber+=1;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didReceivePrivateMessage:(NSNotification *)notification {
  UILocalNotification *messageNotification = [[UILocalNotification alloc] init];
  if (messageNotification==nil) return;
  
  TBMessage *message = notification.object;
  TBBuddy *sender = message.sender;

  NSString *body = TBLocalizedString(@"%@ sent you a message",
                                     @"Sender sent you a message notification text");

  NSString *alertBody = [NSString stringWithFormat:body, sender.nickname];
  messageNotification.alertBody = alertBody;
  messageNotification.alertAction = TBLocalizedString(@"Ok", @"Alert View Ok Button");
  messageNotification.soundName = UILocalNotificationDefaultSoundName;
  [[UIApplication sharedApplication] presentLocalNotificationNow:messageNotification];
  [UIApplication sharedApplication].applicationIconBadgeNumber+=1;
}

///


@end
