//
//  XMPPInBandRegistration.m
//  Cryptocat
//
//  Created by Thomas Balthazar on 24/09/13.
//  Copyright (c) 2013 Thomas Balthazar. All rights reserved.
//

#import "XMPPInBandRegistration.h"
#import "XMPPIQ+XEP_0077.h"

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation XMPPInBandRegistration

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)requestRegistrationFields {
  NSXMLElement *iq = [XMPPIQ registrationFieldsRequestIQForDomain:self.xmppStream.hostName];
	[self.xmppStream sendElement:iq];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)registerUser {
  NSXMLElement *iq = [XMPPIQ registrationIQForUsername:@"foo2" password:@"bar"];
  [self.xmppStream sendElement:iq];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark XMPPStreamDelegate

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq {
  // -- answer to fields request
  if ([iq isInBandRegistrationFieldsAnswer]) {
    [multicastDelegate xmppInBandRegistration:self didReceiveRegistrationFieldsAnswer:iq];
  }
  
  // -- answer to user registration request
  else if ([iq isInBandRegistrationAnswer]) {
    NSString *username = [iq username];
    [multicastDelegate xmppInBandRegistration:self didRegisterUsername:username];
  }
  
  // -- user registration error
  else if ([iq isInBandRegistrationError]) {
    NSString *username = [iq username];
    NSInteger errorCode = [iq errorCode];
    [multicastDelegate xmppInBandRegistration:self
                    didFailToRegisterUsername:username
                                withErrorCode:errorCode];
  }
	
	return NO;
}

@end
