//
//  TBXMPPManager.h
//  Cryptocat
//
//  Created by Thomas Balthazar on 23/09/13.
//  Copyright (c) 2013 Thomas Balthazar. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XMPPMessage, XMPPJID;
@protocol TBXMPPManagerDelegate;

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TBXMPPManager : NSObject

@property (nonatomic, weak) id <TBXMPPManagerDelegate> delegate;

- (id)initWithUsername:(NSString *)username
              password:(NSString *)password
                domain:(NSString *)domain
      conferenceDomain:(NSString *)conferenceDomain
                  room:(NSString *)room
              nickname:(NSString *)nickname;

- (BOOL)connect;
- (void)disconnect;
- (void)sendMessageWithBody:(NSString *)body
                  recipient:(NSString *)recipient;
- (void)sendGroupMessageWithBody:(NSString *)body;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@protocol TBXMPPManagerDelegate <NSObject>

@required

- (void)XMPPManager:(TBXMPPManager *)XMPPManager
  didReceiveMessage:(XMPPMessage *)message
          myRoomJID:(XMPPJID *)myRoomJID;

@end