//
//  XMPPInBandRegistration.m
//  Cryptocat
//
//  Created by Thomas Balthazar on 24/09/13.
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
- (void)registerUsername:(NSString *)username password:(NSString *)password {
  NSXMLElement *iq = [XMPPIQ registrationIQForUsername:username password:password];
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
