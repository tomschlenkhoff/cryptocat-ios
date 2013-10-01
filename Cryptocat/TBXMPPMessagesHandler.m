//
//  TBXMPPMessagesHandler.m
//  Cryptocat
//
//  Created by Thomas Balthazar on 01/10/13.
//  Copyright (c) 2013 Thomas Balthazar. All rights reserved.
//

#import "TBXMPPMessagesHandler.h"

#import "XMPP.h"
#import "TBXMPPManager.h"
#import <TBOTRManager.h>
#import "XMPPMessage+XEP0045.h"
#import "XMPPMessage+Cryptocat.h"

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TBXMPPMessagesHandler ()

@property (nonatomic, strong) TBXMPPManager *XMPPManager;
@property (nonatomic, strong) TBOTRManager *OTRManager;

- (void)handlePrivateMessage:(XMPPMessage *)message;

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
- (id)initWithXMPPManager:(TBXMPPManager *)XMPPManager {
  if (self=[super init]) {
    _XMPPManager = XMPPManager;
    _OTRManager = [TBOTRManager sharedOTRManager];
  }
  
  return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Public Methods

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)handleMessage:(XMPPMessage *)message myJID:(XMPPJID *)myJID {
  if ([message tb_isArchiveMessage]) return;
  if (message.from==myJID) return;
  
  // TODO: If message is from someone not on buddy list, ignore.
  
  // -- composing
  if ([message tb_isComposingMessage]) {
    TBLOG(@"-- %@ is composing", message.fromStr);
  }
  
  // TODO : Check if message has an "active" (stopped writing) notification.
  
  // -- publicKey
  else if ([message tb_isPublicKeyMessage]) {
    TBLOG(@"-- publicKey message : %@", message);
  }
  
  // -- publicKey request
  else if ([message tb_isPublicKeyRequestMessage]) {
    TBLOG(@"-- this is a public key request message : %@", [message body]);
  }
  
  // -- group chat
  else if ([message isGroupChatMessage]) {
    TBLOG(@"-- group message from %@ to %@ : %@", message.fromStr, message.toStr, message.body);
  }
  
  // -- private chat
  else if ([message isChatMessage]) {
    [self handlePrivateMessage:message];
  }
  
  // -- other messages
  else {
    TBLOG(@"-- message : %@", message);
  }
  
  //  - (BOOL)isChatMessage;
  //  - (BOOL)isChatMessageWithBody;
  //  - (BOOL)isErrorMessage;
  //  - (BOOL)isMessageWithBody;
  //  - (BOOL)isGroupChatMessage;
  //  - (BOOL)isGroupChatMessageWithBody;
  //  - (BOOL)isGroupChatMessageWithSubject;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private Methods

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)handlePrivateMessage:(XMPPMessage *)message {
  TBLOG(@"-- private message from %@ to %@ : %@", message.fromStr, message.toStr, message.body);
  
//  TBOTRManager *otrManager = [TBOTRManager sharedOTRManager];
//  NSString *messageBody = message.body;
//  NSString *recipient = message.toStr;
//  NSString *sender = message.fromStr;
//  
//  [otrManager decodeMessage:messageBody recipient:recipient accountName:sender protocol:@"xmpp"];
}


@end
