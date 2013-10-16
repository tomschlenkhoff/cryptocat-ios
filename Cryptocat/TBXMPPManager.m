//
//  TBXMPPManager.m
//  Cryptocat
//
//  Created by Thomas Balthazar on 23/09/13.
//  Copyright (c) 2013 Thomas Balthazar. All rights reserved.
//

#import "TBXMPPManager.h"

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

@property (nonatomic, strong, readonly) XMPPStream *xmppStream;
@property (nonatomic, strong, readonly) XMPPReconnect *xmppReconnect;
@property (nonatomic, strong, readonly) XMPPInBandRegistration *xmppInBandRegistration;
@property (nonatomic, strong, readonly) XMPPRoom *xmppRoom;

@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) NSString *room;
@property (nonatomic, strong) NSString *nickname;
@property (nonatomic, strong) NSString *conferenceDomain;
@property (nonatomic, strong, readonly) XMPPJID *myJID;
@property (nonatomic, strong) NSMutableSet *buddies;

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
- (id)initWithUsername:(NSString *)username
              password:(NSString *)password
                domain:(NSString *)domain
      conferenceDomain:(NSString *)conferenceDomain
                  room:(NSString *)room
              nickname:(NSString *)nickname {
  if (self=[super init]) {
    _xmppStream = [[XMPPStream alloc] init];
    _xmppReconnect = [[XMPPReconnect alloc] init];
    _xmppInBandRegistration = [[XMPPInBandRegistration alloc] init];

    [_xmppReconnect activate:_xmppStream];
    [_xmppInBandRegistration activate:_xmppStream];
    
    [_xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [_xmppInBandRegistration addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    _xmppStream.hostName = domain;
    
    _username = username;
    _password = password;
    _room = room;
    _nickname = nickname;
    _conferenceDomain = conferenceDomain;
    _myJID = [XMPPJID jidWithUser:username domain:domain resource:nil];
    _xmppStream.myJID = _myJID;
    _buddies = [NSMutableSet set];
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
- (NSSet *)usernames {
  return self.buddies;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)connect {
  TBLOGMARK;
  if (!self.xmppStream.isDisconnected) return YES;
  
	NSError *error = nil;
	if (![self.xmppStream connectWithTimeout:XMPPStreamTimeoutNone error:&error]) {
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error connecting"
		                                                    message:@"See console for error details."
		                                                   delegate:nil
		                                          cancelButtonTitle:@"Ok"
		                                          otherButtonTitles:nil];
		[alertView show];
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
- (void)sendMessageWithBody:(NSString *)body
                  recipient:(NSString *)recipient {
  NSXMLElement *bodyElt = [NSXMLElement elementWithName:@"body"];
  [bodyElt setStringValue:body];
  
  NSXMLElement *messageElt = [NSXMLElement elementWithName:@"message"];
  [messageElt addAttributeWithName:@"type" stringValue:@"chat"];
  [messageElt addAttributeWithName:@"to" stringValue:recipient];
//  NSString * messageID = [NSString stringWithFormat:@"%@",theMessage.uniqueID];
//  [messageElt addAttributeWithName:@"id" stringValue:messageID];

  [messageElt addChild:bodyElt];
  NSLog(@"-- will send message to %@ : %@", recipient, messageElt);
  [self.xmppStream sendElement:messageElt];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)sendGroupMessageWithBody:(NSString *)body {
  [self.xmppRoom sendMessageWithBody:body];
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
  XMPPJID *roomJID = [XMPPJID jidWithUser:self.room
                                   domain:self.conferenceDomain
                                 resource:nil];
  _xmppRoom = [[XMPPRoom alloc] initWithRoomStorage:self jid:roomJID];
  [_xmppRoom activate:self.xmppStream];
  [_xmppRoom addDelegate:self delegateQueue:dispatch_get_main_queue()];
  [_xmppRoom joinRoomUsingNickname:self.nickname history:nil password:self.password];
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
- (void)xmppStream:(XMPPStream *)sender willSecureWithSettings:(NSMutableDictionary *)settings {
	TBLOGMARK;
	
//	if (allowSelfSignedCertificates) {
//		[settings setObject:[NSNumber numberWithBool:YES]
//                 forKey:(NSString *)kCFStreamSSLAllowsAnyRoot];
//	}
	
	//if (allowSSLHostNameMismatch) {
  if (NO) {
		[settings setObject:[NSNull null] forKey:(NSString *)kCFStreamSSLPeerName];
	}
	else {
		// Google does things incorrectly (does not conform to RFC).
		// Because so many people ask questions about this (assume xmpp framework is broken),
		// I've explicitly added code that shows how other xmpp clients "do the right thing"
		// when connecting to a google server (gmail, or google apps for domains).
		
		NSString *expectedCertName = nil;
		
		NSString *serverDomain = self.xmppStream.hostName;
		NSString *virtualDomain = [self.xmppStream.myJID domain];
		
		if ([serverDomain isEqualToString:@"talk.google.com"]) {
			if ([virtualDomain isEqualToString:@"gmail.com"]) {
				expectedCertName = virtualDomain;
			}
			else {
				expectedCertName = serverDomain;
			}
		}
		else if (serverDomain == nil) {
			expectedCertName = virtualDomain;
		}
		else {
			expectedCertName = serverDomain;
		}
		
		if (expectedCertName) {
			[settings setObject:expectedCertName forKey:(NSString *)kCFStreamSSLPeerName];
		}
	}
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
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq {
	TBLOG(@"didReceiveIQ : %@", iq);
	
	return NO;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message {
  if ([self.delegate respondsToSelector:@selector(XMPPManager:didReceiveMessage:myRoomJID:)]) {
    [self.delegate XMPPManager:self didReceiveMessage:message myRoomJID:self.xmppRoom.myRoomJID];
  }

  //[self handleMessage:message];
  
	// A simple example of inbound message handling.
  /*
	if ([message isChatMessageWithBody])
	{
		XMPPUserCoreDataStorageObject *user = [xmppRosterStorage userForJID:[message from]
		                                                         xmppStream:xmppStream
		                                               managedObjectContext:[self managedObjectContext_roster]];
		
		NSString *body = [[message elementForName:@"body"] stringValue];
		NSString *displayName = [user displayName];
    
		if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive)
		{
			UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:displayName
                                                          message:body
                                                         delegate:nil
                                                cancelButtonTitle:@"Ok"
                                                otherButtonTitles:nil];
			[alertView show];
		}
		else
		{
			// We are not active, so use a local notification instead
			UILocalNotification *localNotification = [[UILocalNotification alloc] init];
			localNotification.alertAction = @"Ok";
			localNotification.alertBody = [NSString stringWithFormat:@"From: %@\n\n%@",displayName,body];
      
			[[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
		}
	}
  */
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence {
  NSString *username = presence.from.resource;
  
  // sign out
  if ([presence tb_isUnavailable]) {
    [self.buddies removeObject:username];
    if ([self.delegate respondsToSelector:@selector(XMPPManager:usernameDidSignOut:)]) {
      [self.delegate XMPPManager:self usernameDidSignOut:username];
    }
  }
  
  // sign in
  else if ([presence tb_isAvailable]) {
    [self.buddies addObject:username];
    if ([self.delegate respondsToSelector:@selector(XMPPManager:usernameDidSignIn:)]) {
      [self.delegate XMPPManager:self usernameDidSignIn:presence.from.resource];
    }
  }
  
  // go away
  else if ([presence tb_isAway]) {
    [self.buddies addObject:username];
    if ([self.delegate respondsToSelector:@selector(XMPPManager:usernameDidGoAway:)]) {
      [self.delegate XMPPManager:self usernameDidGoAway:presence.from.resource];
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
- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error {
	TBLOG(@"-- stream did disconnect with error : %@", error);
	
//	if (!isXmppConnected) {
//		DDLogError(@"Unable to connect to server. Check xmppStream.hostName");
//	}
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
