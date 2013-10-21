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
  XMPPJID *myRoomJID = XMPPManager.xmppRoom.myRoomJID;
  if ([message tb_isArchiveMessage]) return;
  if ([message.from isEqualToJID:myRoomJID]) return;
  
  // TODO: If message is from someone not on buddy list, ignore.
  
  // -- composing
  if ([message tb_isComposingMessage]) {
    TBLOG(@"-- %@ is composing", message.fromStr);
  }
  
  // TODO : Check if message has an "active" (stopped writing) notification.
  
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
    [self handleGroupMessage:message myRoomJID:myRoomJID];
  }
  
  // -- private chat
  else if ([message isChatMessage]) {
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
    NSXMLElement *bodyElt = [NSXMLElement elementWithName:@"body"];
    [bodyElt setStringValue:encodedMessage];
    
    NSXMLElement *messageElt = [NSXMLElement elementWithName:@"message"];
    [messageElt addAttributeWithName:@"type" stringValue:@"chat"];
    [messageElt addAttributeWithName:@"to" stringValue:recipient];
    
    [messageElt addChild:bodyElt];
    TBLOG(@"-- will send message to %@ : %@", recipient, messageElt);
    [XMPPManager.xmppStream sendElement:messageElt];
  }];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)sendGroupMessage:(NSString *)message XMPPManager:(TBXMPPManager *)XMPPManager {
  NSArray *usernames = [XMPPManager.usernames allObjects];
  NSString *encryptedJSONMessage = [self.multipartyProtocolManager encryptMessage:message
                                                                     forUsernames:usernames];
  [XMPPManager.xmppRoom sendMessageWithBody:encryptedJSONMessage];
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
- (void)handlePrivateMessage:(XMPPMessage *)message XMPPManager:(TBXMPPManager *)XMPPManager {
  TBLOG(@"-- private message from %@ to %@ : %@", message.fromStr, message.toStr, message.body);
  
  NSString *messageBody = message.body;
  NSString *accountName = XMPPManager.xmppRoom.myRoomJID.full;
  NSString *sender = message.fromStr;

  NSString *decodedMessage = [self.OTRManager decodeMessage:messageBody
                                                     sender:sender
                                                accountName:accountName
                                                   protocol:@"xmpp"];
  
  
  TBLOG(@"-- decoded message : |%@|", decodedMessage);
  
  NSDictionary *userInfo = @{@"message": decodedMessage};
  NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
  [defaultCenter postNotificationName:TBDidReceivePrivateChatMessageNotification
                               object:sender
                             userInfo:userInfo];
}

@end
