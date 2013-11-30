//
//  TBXMPPMessagesHandler.h
//  Cryptocat
//
//  Created by Thomas Balthazar on 01/10/13.
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
