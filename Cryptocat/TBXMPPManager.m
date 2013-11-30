//
//  TBXMPPManager.m
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

#import "TBXMPPManager.h"
#import "TBBuddy.h"
#import "XMPP.h"
#import "XMPPReconnect.h"
#import "XMPPMUC.h"
#import <XMPPRoom.h>

#import "XMPPMessage+XEP0045.h"
#import "XMPPMessage+Cryptocat.h"
#import "XMPPPresence+Cryptocat.h"

#import "XMPPInBandRegistration.h"

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TBXMPPManager () <
  XMPPStreamDelegate,
  XMPPInBandRegistrationDelegate,
  XMPPRoomDelegate,
  XMPPRoomStorage>

@property (nonatomic, strong, readwrite) TBBuddy *me;
@property (nonatomic, strong, readwrite) XMPPStream *xmppStream;
@property (nonatomic, strong, readwrite) XMPPReconnect *xmppReconnect;
@property (nonatomic, strong, readwrite) XMPPInBandRegistration *xmppInBandRegistration;
@property (nonatomic, strong, readwrite) XMPPRoom *xmppRoom;

@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) NSString *roomName;
@property (nonatomic, strong) NSString *conferenceDomain;

// -- connection steps
- (void)requestRegistrationFields;
- (void)registerUsername;
- (void)authenticate;
- (void)joinRoom;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TBXMPPManager

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Initializer

////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)init {
  if (self=[super init]) {
    _me = nil;
    _xmppStream = [[XMPPStream alloc] init];
    
#if !TARGET_IPHONE_SIMULATOR
    _xmppStream.enableBackgroundingOnSocket = YES;
#endif

    _xmppReconnect = [[XMPPReconnect alloc] init];
    _xmppInBandRegistration = [[XMPPInBandRegistration alloc] init];

    [_xmppReconnect activate:_xmppStream];
    [_xmppInBandRegistration activate:_xmppStream];
    
    [_xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [_xmppInBandRegistration addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    _xmppRoom = nil;
    _username = nil;
    _password = nil;
    _roomName = nil;
    _conferenceDomain = nil;
    _buddies = [NSMutableArray array];
  }
  
  return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)dealloc {
  [_xmppStream removeDelegate:self];
  [_xmppReconnect deactivate];
  [_xmppInBandRegistration deactivate];
  [_xmppStream disconnect];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Public Methods

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)connectWithUsername:(NSString *)username
                   password:(NSString *)password
                     domain:(NSString *)domain
           conferenceDomain:(NSString *)conferenceDomain
                   roomName:(NSString *)roomName
                   nickname:(NSString *)nickname {
  TBLOGMARK;
  if (!self.xmppStream.isDisconnected) return YES;
  
  // something like lobby@conference.crypto.cat/thomas
  XMPPJID *myRoomJID = [XMPPJID jidWithUser:roomName
                                     domain:conferenceDomain
                                   resource:nickname];
  self.me = [[TBBuddy alloc] initWithXMPPJID:myRoomJID];
  self.username = username;
  self.password = password;
  self.roomName = roomName;
  self.conferenceDomain = conferenceDomain;
  self.xmppStream.myJID = [XMPPJID jidWithUser:username domain:domain resource:nil];
  self.xmppStream.hostName = domain;
  
	NSError *error = nil;
	if (![self.xmppStream connectWithTimeout:XMPPStreamTimeoutNone error:&error]) {
		TBLOG(@"Error connecting: %@", error);
		return NO;
	}
  
	return YES;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)disconnect {
	[self.xmppStream disconnect];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private Methods

////////////////////////////////////////////////////////////////////////////////////////////////////
/*
 *  Connection Step #1 : ask for registration fields
 */
- (void)requestRegistrationFields {
  [self.xmppInBandRegistration requestRegistrationFields];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
/*
 *  Connection Step #2 : register username
 */
- (void)registerUsername {
  [self.xmppInBandRegistration registerUsername:self.username password:self.password];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
/*
 *  Connection Step #3 : authenticate
 */
- (void)authenticate {
  NSError *error = nil;
	if (![self.xmppStream authenticateWithPassword:self.password error:&error]) {
    TBLOG(@"Error authenticating : %@", error);
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////
/*
 *  Connection Step #4 : join room
 */
- (void)joinRoom {
  XMPPJID *roomJID = [XMPPJID jidWithUser:self.roomName
                                   domain:self.conferenceDomain
                                 resource:nil];
  self.xmppRoom = [[XMPPRoom alloc] initWithRoomStorage:self jid:roomJID];
  [self.xmppRoom activate:self.xmppStream];
  [self.xmppRoom addDelegate:self delegateQueue:dispatch_get_main_queue()];
  [self.xmppRoom joinRoomUsingNickname:self.me.nickname history:nil password:self.password];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark XMPPStreamDelegate

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)xmppStream:(XMPPStream *)sender socketDidConnect:(GCDAsyncSocket *)socket {
	TBLOGMARK;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
// TODO: is this method used?
- (void)xmppStream:(XMPPStream *)sender willSecureWithSettings:(NSMutableDictionary *)settings {
	TBLOGMARK;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)xmppStreamDidSecure:(XMPPStream *)sender {
	TBLOGMARK;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)xmppStreamDidConnect:(XMPPStream *)sender {
	TBLOGMARK;
  [self requestRegistrationFields];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender {
	TBLOGMARK;

	[self joinRoom];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error {
	TBLOG(@"%@", error);
  if ([self.delegate respondsToSelector:@selector(XMPPManagerDidFailToAuthenticate:)]) {
    [self.delegate XMPPManagerDidFailToAuthenticate:self];
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq {
	TBLOG(@"didReceiveIQ : %@", iq);
	
	return NO;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message {
  if ([self.delegate respondsToSelector:@selector(XMPPManager:didReceiveMessage:)]) {
    [self.delegate XMPPManager:self didReceiveMessage:message];
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence {
  TBBuddy *presenceBuddy = [[TBBuddy alloc] initWithXMPPJID:presence.from];
  
  // nickname is already in use by another occupant
  if ([presence tb_isNicknameAlreadyInUseError]) {
    if ([self.delegate
         respondsToSelector:@selector(XMPPManager:didTryToRegisterAlreadyInUseUsername:)]) {
      [self.delegate XMPPManager:self didTryToRegisterAlreadyInUseUsername:presenceBuddy.nickname];
    }
  }
  
  // sign out
  if ([presence tb_isUnavailable]) {
    [self.buddies removeObject:presenceBuddy];
    if ([self.delegate respondsToSelector:@selector(XMPPManager:buddyDidSignOut:)]) {
      [self.delegate XMPPManager:self buddyDidSignOut:presenceBuddy];
    }
  }
  
  // sign in
  else if ([presence tb_isAvailable]) {
    if (![presenceBuddy isEqual:self.me] && ![self.buddies containsObject:presenceBuddy]) {
      [self.buddies addObject:presenceBuddy];
    }
    if ([self.delegate respondsToSelector:@selector(XMPPManager:buddyDidSignIn:)]) {
      [self.delegate XMPPManager:self buddyDidSignIn:presenceBuddy];
    }
  }
  
  // go away
  else if ([presence tb_isAway]) {
    if (![presenceBuddy isEqual:self.me] && ![self.buddies containsObject:presenceBuddy]) {
      [self.buddies addObject:presenceBuddy];
    }
    if ([self.delegate respondsToSelector:@selector(XMPPManager:buddyDidGoAway:)]) {
      [self.delegate XMPPManager:self buddyDidGoAway:presenceBuddy];
    }
  }
  
  // unhandled
  else {
    TBLOG(@"Unhandled presence : %@", presence);
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)xmppStream:(XMPPStream *)sender didReceiveError:(id)error {
	TBLOG(@"-- XMPPStream error : %@", error);
}

////////////////////////////////////////////////////////////////////////////////////////////////////
/**
 * This method is called after the stream is closed.
 *
 * The given error parameter will be non-nil if the error was due to something outside the general xmpp realm.
 * Some examples:
 * - The TCP socket was unexpectedly disconnected.
 * - The SRV resolution of the domain failed.
 * - Error parsing xml sent from server.
 **/
- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error {
	TBLOG(@"-- stream did disconnect with error : %@", error);
  
  if (error!=nil && [self.delegate respondsToSelector:@selector(XMPPManagerDidFailToConnect:)]) {
    [self.delegate XMPPManagerDidFailToConnect:self];
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark XMPPInBandRegistrationDelegate

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)xmppInBandRegistration:(XMPPInBandRegistration *)sender
didReceiveRegistrationFieldsAnswer:(XMPPIQ *)iq {
  [self registerUsername];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)xmppInBandRegistration:(XMPPInBandRegistration *)sender
           didRegisterUsername:(NSString *)username {
  TBLOG(@"-- username registered : %@", username);
  [self authenticate];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)xmppInBandRegistration:(XMPPInBandRegistration *)sender
     didFailToRegisterUsername:(NSString *)username
                 withErrorCode:(NSInteger)errorCode {
  TBLOG(@"-- username registration error %d for %@", errorCode, username);
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark XMPPRoomDelegate

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)xmppRoomDidJoin:(XMPPRoom *)sender {
  TBLOGMARK;
  if ([self.delegate respondsToSelector:@selector(XMPPManager:didJoinRoom:)]) {
    [self.delegate XMPPManager:self didJoinRoom:sender];
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)xmppRoomDidLeave:(XMPPRoom *)sender {
  TBLOG(@"-- did leave room : %@", sender);
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark XMPPRoomStorage

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)configureWithParent:(XMPPRoom *)aParent queue:(dispatch_queue_t)queue {
  TBLOGMARK;
  return YES;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)handlePresence:(XMPPPresence *)presence room:(XMPPRoom *)room {
  /* -- presence : 
   <presence xmlns="jabber:client" 
    from="cryptocatdev@conference.crypto.cat/thomas" 
    to="1380123858.290953@crypto.cat/32032381791380123852967666">
      <x xmlns="http://jabber.org/protocol/muc#user">
        <item affiliation="owner" role="moderator"></item>
      </x>
   </presence>
  */

  TBLOG(@"-- presence : %@", presence);
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)handleIncomingMessage:(XMPPMessage *)message room:(XMPPRoom *)room {
  //TBLOGMARK;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)handleOutgoingMessage:(XMPPMessage *)message room:(XMPPRoom *)room {
  TBLOGMARK;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)handleDidLeaveRoom:(XMPPRoom *)room {
  TBLOG(@"-- did leave room : %@", room);
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)handleDidJoinRoom:(XMPPRoom *)room withNickname:(NSString *)nickname {
  
}

@end
