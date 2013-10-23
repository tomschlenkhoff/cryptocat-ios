//
//  TBXMPPMessagesHandler.m
//  Cryptocat
//
//  Created by Thomas Balthazar on 01/10/13.
//  Copyright (c) 2013 Thomas Balthazar. All rights reserved.
//

#import "TBXMPPMessagesHandler.h"

#import "XMPP.h"
#import "XMPPRoom.h"
#import "TBXMPPManager.h"
#import <TBOTRManager.h>
#import <TBMultipartyProtocolManager.h>
#import "XMPPMessage+XEP0045.h"
#import "XMPPMessage+XEP_0085.h"
#import "XMPPMessage+Cryptocat.h"

NSString * const TBMessagingProtocol = @"xmpp";
NSString * const TBDidReceiveGroupChatMessageNotification =
                                                        @"TBDidReceiveGroupChatMessageNotification";
NSString * const TBDidReceivePrivateChatMessageNotification =
                                                      @"TBDidReceivePrivateChatMessageNotification";

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
- (void)sendMessageWithBody:(NSString *)body
                  recipient:(NSString *)recipient
                XMPPManager:(TBXMPPManager *)XMPPManager {
  
  NSString *accountName = XMPPManager.xmppRoom.myRoomJID.full;
  
  [self.OTRManager encodeMessage:body
                       recipient:recipient
                     accountName:accountName
                        protocol:TBMessagingProtocol
                 completionBlock:^(NSString *encodedMessage)
  {
    XMPPMessage *message = [XMPPMessage messageWithType:@"chat"
                                                     to:[XMPPJID jidWithString:recipient]];
    [message addBody:encodedMessage];
    [message addActiveChatState];

    TBLOG(@"-- will send message to %@ : %@", recipient, message);
    [XMPPManager.xmppStream sendElement:message];
  }];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)sendGroupMessage:(NSString *)message XMPPManager:(TBXMPPManager *)XMPPManager {
  NSArray *usernames = [XMPPManager.usernames allObjects];
  NSString *encryptedJSONMessage = [self.multipartyProtocolManager encryptMessage:message
                                                                     forUsernames:usernames];
  XMPPMessage *xmppMessage = [XMPPMessage message];
  [xmppMessage addBody:encryptedJSONMessage];
  [xmppMessage addActiveChatState];
  [XMPPManager.xmppRoom sendMessage:xmppMessage];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)sendStateNotification:(NSString *)state
                    recipient:(NSString *)recipient
                  XMPPManager:(TBXMPPManager *)XMPPManager {
  XMPPMessage *message = nil;
  
  if (recipient==nil) {
    message = [XMPPMessage message];
  }
  else {
    message = [XMPPMessage messageWithType:@"chat" to:[XMPPJID jidWithString:recipient]];
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
    TBLOG(@"-- will send chat state message to %@ : %@", recipient, message);
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
  
  NSString *sender = message.from.resource;
  NSString *roomName = message.from.user;
  NSString *decryptedMessage = [self.multipartyProtocolManager decryptMessage:message.body
                                                                 fromUsername:sender];
  NSDictionary *userInfo = @{@"message": decryptedMessage, @"sender": sender};
  
  TBLOG(@"-- decrypted message : %@", decryptedMessage);
  
  NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
  [defaultCenter postNotificationName:TBDidReceiveGroupChatMessageNotification
                               object:roomName
                             userInfo:userInfo];  
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)handleChatStateMessage:(XMPPMessage *)message XMPPManager:(TBXMPPManager *)XMPPManager {
  // -- composing
  if ([message tb_isComposingMessage]) {
    if ([message isGroupChatMessage]) {
      TBLOG(@"-- %@ is composing in meeting room", message.fromStr);
    }
    else {
      TBLOG(@"-- %@ is composing in private", message.fromStr);
    }
  }
  
  // -- paused (composing paused)
  else if ([message tb_isPausedMessage]) {
    if ([message isGroupChatMessage]) {
      TBLOG(@"-- %@ is paused in meeting room", message.fromStr);
    }
    else {
      TBLOG(@"-- %@ is paused in private", message.fromStr);
    }
  }
  
  // -- active (finished composing)
  else if ([message tb_isActiveMessage]) {
    if ([message isGroupChatMessage]) {
      TBLOG(@"-- %@ is active in meeting room", message.fromStr);
    }
    else {
      TBLOG(@"-- %@ is active in private", message.fromStr);
    }
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)handlePrivateMessage:(XMPPMessage *)message XMPPManager:(TBXMPPManager *)XMPPManager {
  TBLOG(@"-- private message from %@ to %@ : %@", message.fromStr, message.toStr, message.body);
  
  NSString *messageBody = message.body;
  NSString *accountName = XMPPManager.xmppRoom.myRoomJID.full;
  NSString *sender = message.fromStr;

  NSString *decodedMessage = [self.OTRManager decodeMessage:messageBody
                                                     sender:sender
                                                accountName:accountName
                                                   protocol:TBMessagingProtocol];
  
  
  TBLOG(@"-- decoded message : |%@|", decodedMessage);
  
  NSDictionary *userInfo = @{@"message": decodedMessage};
  NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
  [defaultCenter postNotificationName:TBDidReceivePrivateChatMessageNotification
                               object:sender
                             userInfo:userInfo];
}

@end
