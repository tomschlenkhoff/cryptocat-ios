//
//  TBXMPPManager.h
//  Cryptocat
//
//  Created by Thomas Balthazar on 23/09/13.
//  Copyright (c) 2013 Thomas Balthazar. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XMPPMessage, XMPPJID, XMPPRoom, XMPPStream;
@protocol TBXMPPManagerDelegate;

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TBXMPPManager : NSObject

@property (nonatomic, weak) id <TBXMPPManagerDelegate> delegate;
@property (nonatomic, readonly) NSString *myNickname;
@property (nonatomic, readonly) NSSet *usernames;
@property (nonatomic, readonly) XMPPStream *xmppStream;
@property (nonatomic, readonly) XMPPRoom *xmppRoom;

- (id)initWithUsername:(NSString *)username
              password:(NSString *)password
                domain:(NSString *)domain
      conferenceDomain:(NSString *)conferenceDomain
              roomName:(NSString *)roomName
              nickname:(NSString *)nickname;

- (BOOL)connect;
- (void)disconnect;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@protocol TBXMPPManagerDelegate <NSObject>

@required

- (void)XMPPManager:(TBXMPPManager *)XMPPManager
  didReceiveMessage:(XMPPMessage *)message
          myRoomJID:(XMPPJID *)myRoomJID;

- (void)XMPPManager:(TBXMPPManager *)XMPPManager usernameDidSignIn:(NSString *)username;
- (void)XMPPManager:(TBXMPPManager *)XMPPManager usernameDidGoAway:(NSString *)username;
- (void)XMPPManager:(TBXMPPManager *)XMPPManager usernameDidSignOut:(NSString *)username;

@end