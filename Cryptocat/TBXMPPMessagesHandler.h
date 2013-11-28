//
//  TBXMPPMessagesHandler.h
//  Cryptocat
//
//  Created by Thomas Balthazar on 01/10/13.
//  Copyright (c) 2013 Thomas Balthazar. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const TBMessagingProtocol;

// message / state notifications
extern NSString * const TBDidReceiveGroupChatMessageNotification;
extern NSString * const TBDidReceivePrivateChatMessageNotification;
extern NSString * const TBDidReceiveGroupChatStateNotification;
extern NSString * const TBDidReceivePrivateChatStateNotification;

// errors
extern NSString * const TBErrorDomainGroupChatMessage;
extern NSInteger const TBErrorCodeUnreadableMessage;
extern NSInteger const TBErrorCodeMissingRecipients;
extern NSString * const TBErrorCodeUnreadableMessageSenderKey;
extern NSString * const TBErrorCodeMissingRecipientsKey;

@class TBXMPPManager, TBOTRManager, TBMultipartyProtocolManager, XMPPMessage, XMPPJID, TBBuddy;

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TBXMPPMessagesHandler : NSObject

- (id)initWithOTRManager:(TBOTRManager *)OTRManager
multipartyProtocolManager:(TBMultipartyProtocolManager *)multipartyProtocolManager;
- (void)handleMessage:(XMPPMessage *)message XMPPManager:(TBXMPPManager *)XMPPManager;
- (void)sendRawMessageWithBody:(NSString *)body
                     recipient:(TBBuddy *)recipient
                   XMPPManager:(TBXMPPManager *)XMPPManager;
- (void)sendMessageWithBody:(NSString *)body
                  recipient:(TBBuddy *)recipient
                XMPPManager:(TBXMPPManager *)XMPPManager;
- (void)sendGroupMessage:(NSString *)message XMPPManager:(TBXMPPManager *)XMPPManager;
- (void)sendStateNotification:(NSString *)state
                    recipient:(TBBuddy *)recipient
                  XMPPManager:(TBXMPPManager *)XMPPManager;
- (void)sendPublicKeyToRecipient:(TBBuddy *)recipient XMPPManager:(TBXMPPManager *)XMPPManager;

@end
