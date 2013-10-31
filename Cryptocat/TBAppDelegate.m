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
#import "TBBuddy.h"
#import "XMPPPresence+Cryptocat.h"

typedef void (^TBGoneSecureCompletionBlock)();

#define kDomain           @"crypto.cat"
#define kConferenceDomain @"conference.crypto.cat"

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

- (BOOL)isLoginScreenPresented;
- (BOOL)presentLoginVCAnimated:(BOOL)animated;
- (void)addCompletionBlock:(TBGoneSecureCompletionBlock)completionBlock
                   forUser:(TBBuddy *)user
                 recipient:(TBBuddy *)recipient;
- (void)executeGoneSecureCompletionBlocsForUser:(NSString *)user recipient:(NSString *)recipient;

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
  
  // xmpp manager
  self.XMPPManager = [[TBXMPPManager alloc] init];
  self.XMPPManager.delegate = self;

  // multiparty chat manager
  self.multipartyProtocolManager = [TBMultipartyProtocolManager sharedMultipartyProtocolManager];
  self.multipartyProtocolManager.delegate = self;
  
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
  
  // <presence xmlns="jabber:client" from="cryptocatdev@conference.crypto.cat/safari" to="rx21bjikfqyzvyvq@crypto.cat/353544399813835940523576"><show>away</show><status>away</status><x xmlns="http://jabber.org/protocol/muc#user"><item affiliation="none" role="visitor"/></x></presence>
  
  // -- will send presence : <presence from="cryptocatdev@conference.crypto.cat/iOSTestApp" type="available"><status>away</status></presence>
  
  // -- will send presence : <presence from="cryptocatdev@conference.crypto.cat/iOSTestApp"><status>away</status><show>away</show></presence>
  
  // TODO: should use something like [XMPPPresence tb_awayPresence]
//  XMPPPresence *presence = [XMPPPresence presence];
//  [presence addAttributeWithName:@"from" stringValue:self.XMPPManager.xmppRoom.myRoomJID.full];
//  [presence addAttributeWithName:@"to" stringValue:@"cryptocatdev@conference.crypto.cat/safari"];
//  //[presence addAttributeWithName:@"type" stringValue:@"available"];
//  NSXMLElement *status = [NSXMLElement elementWithName:@"status"];
//  [status setStringValue:@"away"];
//  [presence addChild:status];
//  NSXMLElement *show = [NSXMLElement elementWithName:@"show"];
//  [show setStringValue:@"away"];
//  [presence addChild:show];
//  TBLOG(@"-- will send presence : %@", presence);
//  [self.XMPPManager.xmppStream sendElement:presence];
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
  [self presentLoginVCAnimated:NO];
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
- (BOOL)presentLoginVCAnimated:(BOOL)animated {
  // if xmpp is not connected or connecting, show loginVC
  if (!self.XMPPManager.xmppStream.isConnected && !self.XMPPManager.xmppStream.isConnecting) {
    // show loginVC
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *loginNC = [storyboard
                                       instantiateViewControllerWithIdentifier:@"LoginNCID"];
    loginNC.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
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
    TBLOG(@"-- my OTR fingerprint is : %@", XMPPManager.me.chatFingerprint);
    TBLOG(@"-- my group fingerprint is : %@", XMPPManager.me.groupChatFingerprint);
    
    TBLOG(@"-- safari OTR fingerprint is : %@",
          [self.OTRManager fingerprintForAccountName:@"cryptocatdev@conference.crypto.cat/safari"
                                            protocol:TBMessagingProtocol]);
    BOOL isChatWithSafariSecure = [self.OTRManager isConversationEncryptedForAccountName:account
                                                                               recipient:@"cryptocatdev@conference.crypto.cat/safari"
                                                                                protocol:TBMessagingProtocol];
    TBLOG(@"-- chat with safari is %@", (isChatWithSafariSecure ? @"secure" : @"insecure"));
  }];
  
  self.chatViewController.roomName = room.roomJID.user;
  self.chatViewController.me = XMPPManager.me;
  self.chatViewController.buddies = XMPPManager.buddies;

  if ([self isLoginScreenPresented]) {
    [self.chatViewController dismissViewControllerAnimated:YES completion:NULL];
  }
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
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)XMPPManager:(TBXMPPManager *)XMPPManager buddyDidSignOut:(TBBuddy *)buddy {
  TBLOG(@"-- %@ signed out", buddy.fullname);
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc postNotificationName:TBBuddyDidSignOutNotification object:buddy];
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
  [self.XMPPManager.xmppStream disconnect];
  [self presentLoginVCAnimated:YES];
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
  self.multipartyProtocolManager.myName = self.XMPPManager.me.nickname;
  
  TBLOG(@"-- isConnected : %d", isConnected);
}

@end
