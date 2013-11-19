//
//  TBXMPPMessagesHandler.m
//  Cryptocat
//
//  Created by Thomas Balthazar on 01/10/13.
//  Copyright (c) 2013 Thomas Balthazar. All rights reserved.
//

#import "TBXMPPMessagesHandler.h"
#import "TBMessage.h"
#import "TBBuddy.h"
#import "XMPP.h"
#import "XMPPRoom.h"
#import "TBXMPPManager.h"
#import <TBOTRManager.h>
#import <TBMultipartyProtocolManager.h>
#import "XMPPMessage+XEP0045.h"
#import "XMPPMessage+XEP_0085.h"
#import "XMPPMessage+Cryptocat.h"
#import "TBChateStateNotification.h"

NSString * const TBMessagingProtocol = @"xmpp";
NSString * const TBDidReceiveGroupChatMessageNotification =
                                                        @"TBDidReceiveGroupChatMessageNotification";
NSString * const TBDidReceivePrivateChatMessageNotification =
                                                      @"TBDidReceivePrivateChatMessageNotification";
NSString * const TBDidReceiveGroupChatStateNotification = @"TBDidReceiveGroupChatStateNotification";
NSString * const TBDidReceivePrivateChatStateNotification =
                                                        @"TBDidReceivePrivateChatStateNotification";

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TBXMPPMessagesHandler ()

@property (nonatomic, strong) TBOTRManager *OTRManager;
@property (nonatomic, strong) TBMultipartyProtocolManager *multipartyProtocolManager;

- (void)handlePublicKeyMessage:(XMPPMessage *)message XMPPManager:(TBXMPPManager *)XMPPManager;
- (void)handlePrivateMessage:(XMPPMessage *)message XMPPManager:(TBXMPPManager *)XMPPManager;
- (void)handleGroupMessage:(XMPPMessage *)message myRoomJID:(XMPPJID *)myRoomJID;
- (void)handleChatStateMessage:(XMPPMessage *)message XMPPManager:(TBXMPPManager *)XMPPManager;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TBXMPPMessagesHandler

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Initializer

////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithOTRManager:(TBOTRManager *)OTRManager
multipartyProtocolManager:(TBMultipartyProtocolManager *)multipartyProtocolManager {
  if (self=[super init]) {
    _OTRManager = OTRManager;
    _multipartyProtocolManager = multipartyProtocolManager;
  }
  
  return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Public Methods

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)handleMessage:(XMPPMessage *)message XMPPManager:(TBXMPPManager *)XMPPManager {
  TBLOG(@"-- received message : %@", message);
  
  XMPPJID *myRoomJID = XMPPManager.xmppRoom.myRoomJID;
  if ([message tb_isArchiveMessage]) return;
  if ([message.from isEqualToJID:myRoomJID]) return;
  
  // TODO: If message is from someone not on buddy list, ignore.
    
  // -- publicKey
  else if ([message tb_isPublicKeyMessage]) {
    [self handlePublicKeyMessage:message XMPPManager:XMPPManager];
  }
  
  // -- publicKey request
  else if ([message tb_isPublicKeyRequestMessage]) {
    TBLOG(@"-- this is a public key request message : %@", [message body]);
  }
  
  // -- group chat
  else if ([message isGroupChatMessage]) {
    // group message can also contain chat state info
    if ([message tb_isChatState]) {
      [self handleChatStateMessage:message XMPPManager:XMPPManager];
    }
    [self handleGroupMessage:message myRoomJID:myRoomJID];
  }
  
  // -- private chat
  else if ([message isChatMessage]) {
    // private message can also contain chat state info
    if ([message tb_isChatState]) {
      [self handleChatStateMessage:message XMPPManager:XMPPManager];
    }
    [self handlePrivateMessage:message XMPPManager:XMPPManager];
  }
  
  // -- other messages
  else {
    TBLOG(@"-- message : %@", message);
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)sendRawMessageWithBody:(NSString *)body
                     recipient:(TBBuddy *)recipient
                   XMPPManager:(TBXMPPManager *)XMPPManager {
  XMPPMessage *message = [XMPPMessage messageWithType:@"chat"
                                                   to:recipient.XMPPJID];
  [message addBody:body];
  [message addActiveChatState];
  
  TBLOG(@"-- will send raw message to %@ : %@", recipient.fullname, message);
  [XMPPManager.xmppStream sendElement:message];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)sendMessageWithBody:(NSString *)body
                  recipient:(TBBuddy *)recipient
                XMPPManager:(TBXMPPManager *)XMPPManager {
  
  NSString *accountName = XMPPManager.me.fullname;
  
  [self.OTRManager encodeMessage:body
                       recipient:recipient.fullname
                     accountName:accountName
                        protocol:TBMessagingProtocol
                 completionBlock:^(NSString *encodedMessage)
  {
    XMPPMessage *message = [XMPPMessage messageWithType:@"chat"
                                                     to:recipient.XMPPJID];
    [message addBody:encodedMessage];
    [message addActiveChatState];

    TBLOG(@"-- will send message to %@ : %@", recipient.fullname, message);
    [XMPPManager.xmppStream sendElement:message];
  }];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)sendGroupMessage:(NSString *)message XMPPManager:(TBXMPPManager *)XMPPManager {
  NSMutableArray *usernames = [NSMutableArray arrayWithCapacity:[XMPPManager.buddies count]];
  for (TBBuddy *buddy in XMPPManager.buddies) {
    [usernames addObject:buddy.nickname];
  }
  
  NSString *encryptedJSONMessage = [self.multipartyProtocolManager encryptMessage:message
                                                                     forUsernames:usernames];
  XMPPMessage *xmppMessage = [XMPPMessage message];
  [xmppMessage addBody:encryptedJSONMessage];
  [xmppMessage addActiveChatState];
  [XMPPManager.xmppRoom sendMessage:xmppMessage];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)sendStateNotification:(NSString *)state
                    recipient:(TBBuddy *)recipient
                  XMPPManager:(TBXMPPManager *)XMPPManager {
  XMPPMessage *message = nil;
  
  if (recipient==nil) {
    message = [XMPPMessage message];
  }
  else {
    message = [XMPPMessage messageWithType:@"chat" to:recipient.XMPPJID];
  }

  if ([state isEqualToString:@"composing"]) {
    [message addComposingChatState];
  }
  else if ([state isEqualToString:@"active"]) {
    [message addActiveChatState];
  }
  else if ([state isEqualToString:@"paused"]) {
    [message addPausedChatState];
  }
  
  if (recipient==nil) {
    TBLOG(@"-- will send chat state message to group : %@", message);
    [XMPPManager.xmppRoom sendMessage:message];
  }
  else {
    TBLOG(@"-- will send chat state message to %@ : %@", recipient.fullname, message);
    [XMPPManager.xmppStream sendElement:message];
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private Methods

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)handlePublicKeyMessage:(XMPPMessage *)message XMPPManager:(TBXMPPManager *)XMPPManager {
  /*
   <message xmlns="jabber:client" 
            from="cryptocatdev@conference.crypto.cat/thomas" 
            to="1381138993.096637@crypto.cat/14922274781381138980964345" 
            type="groupchat" 
            id="9012">
              <body xmlns="jabber:client">
                { "type":"publicKey",
                  "text":{"iOSTestApp":{"message":"6ZpMAta860/myjWIkwgFj1fMaLgTcdCMeYtnd6O0q1Y="}}}
              </body>
              <x xmlns="jabber:x:event">
                <active/>
              </x>
   </message>
  */
  [self.multipartyProtocolManager addPublicKeyFromMessage:message.body
                                              forUsername:message.from.resource];

  NSString *messageBody = [self.multipartyProtocolManager
                           publicKeyMessageForUsername:message.from.resource];
  [XMPPManager.xmppRoom sendMessageWithBody:messageBody];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)handleGroupMessage:(XMPPMessage *)message myRoomJID:(XMPPJID *)myRoomJID {
  TBLOG(@"-- group message from %@ to %@ : %@", message.fromStr, message.toStr, message.body);
  if (message.body==nil || [message.body isEqualToString:@""]) return;
  
  TBBuddy *sender = [[TBBuddy alloc] initWithXMPPJID:message.from];
  NSString *decryptedMessage = [self.multipartyProtocolManager decryptMessage:message.body
                                                                 fromUsername:sender.nickname];

  TBMessage *receivedMsg = [[TBMessage alloc] init];
  receivedMsg.sender = sender;
  receivedMsg.text = decryptedMessage;
  if (decryptedMessage==nil) {
    NSString *warningMessage = @"Warning: You have received an unreadable message from %@. \
This may indicate an untrustworthy user or messages that \
failed to be received. You may also be running an outdated \
version of Cryptocat. Please check for updates.";
    receivedMsg.text = [NSString stringWithFormat:warningMessage, sender.nickname];
    receivedMsg.isWarningMessage = YES;
  }
  
  TBLOG(@"-- decrypted message : %@", decryptedMessage);
  
  NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
  [defaultCenter postNotificationName:TBDidReceiveGroupChatMessageNotification
                               object:receivedMsg
                             userInfo:nil];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)handleChatStateMessage:(XMPPMessage *)message XMPPManager:(TBXMPPManager *)XMPPManager {
  TBChateStateNotification *csn = nil;
  NSString *notificationName = nil;
  
  // -- composing
  if ([message tb_isComposingMessage]) {
    if ([message isGroupChatMessage]) {
      TBLOG(@"-- %@ is composing in meeting room", message.fromStr);
      csn = [TBChateStateNotification composingNotification];
      notificationName = TBDidReceiveGroupChatStateNotification;
    }
    else {
      TBLOG(@"-- %@ is composing in private", message.fromStr);
      csn = [TBChateStateNotification composingNotification];
      notificationName = TBDidReceivePrivateChatStateNotification;
    }
  }
  
  // -- paused (composing paused)
  else if ([message tb_isPausedMessage]) {
    if ([message isGroupChatMessage]) {
      TBLOG(@"-- %@ is paused in meeting room", message.fromStr);
      csn = [TBChateStateNotification pausedNotification];
      notificationName = TBDidReceiveGroupChatStateNotification;
    }
    else {
      TBLOG(@"-- %@ is paused in private", message.fromStr);
      csn = [TBChateStateNotification pausedNotification];
      notificationName = TBDidReceivePrivateChatStateNotification;
    }
  }
  
  // -- active (finished composing)
  else if ([message tb_isActiveMessage]) {
    if ([message isGroupChatMessage]) {
      TBLOG(@"-- %@ is active in meeting room", message.fromStr);
      csn = [TBChateStateNotification activeNotification];
      notificationName = TBDidReceiveGroupChatStateNotification;
    }
    else {
      TBLOG(@"-- %@ is active in private", message.fromStr);
      csn = [TBChateStateNotification activeNotification];
      notificationName = TBDidReceivePrivateChatStateNotification;
    }
  }
  
  csn.sender = [[TBBuddy alloc] initWithXMPPJID:message.from];
  NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
  [defaultCenter postNotificationName:notificationName
                               object:csn
                             userInfo:nil];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)handlePrivateMessage:(XMPPMessage *)message XMPPManager:(TBXMPPManager *)XMPPManager {
  TBLOG(@"-- private message from %@ to %@ : %@", message.fromStr, message.toStr, message.body);
  
  if ([message.body isEqualToString:@""]) {
    TBLOG(@"-- private message is empty, don't do anything with it.");
    return;
  }
  
  NSString *messageBody = message.body;
  NSString *accountName = XMPPManager.me.fullname;
  TBBuddy *sender = [[TBBuddy alloc] initWithXMPPJID:message.from];

  NSString *decodedMessage = [self.OTRManager decodeMessage:messageBody
                                                     sender:sender.fullname
                                                accountName:accountName
                                                   protocol:TBMessagingProtocol];
  
  
  TBLOG(@"-- decoded message : |%@|", decodedMessage);
  
  TBMessage *receivedMsg = [[TBMessage alloc] init];
  receivedMsg.sender = sender;
  receivedMsg.text = decodedMessage;

  NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
  [defaultCenter postNotificationName:TBDidReceivePrivateChatMessageNotification
                               object:receivedMsg
                             userInfo:nil];
}

@end
