//
//  XMPPIQ+XEP_0077.m
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

// http://xmpp.org/extensions/xep-0077.html

#import "XMPPIQ+XEP_0077.h"
#import "NSXMLElement+XMPP.h"

#define kRegistrationElementID1  @"reg1"
#define kRegistrationElementID2  @"reg2"
#define kInBandRegistrationXMLNS  @"jabber:iq:register"

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface XMPPIQ (XEP_0077_Private)

- (BOOL)hasCorrectXMLNS;
- (NSXMLElement *)query;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation XMPPIQ (XEP_0077_Private)

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)hasCorrectXMLNS {
  return [[self elementsForXmlns:kInBandRegistrationXMLNS] count]!=0;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSXMLElement *)query {
  return [self elementForName:@"query" xmlns:kInBandRegistrationXMLNS];
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation XMPPIQ (XEP_0077)

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)isInBandRegistrationFieldsAnswer {
  /*
   <iq xmlns="jabber:client" from="crypto.cat" id="reg1" type="result">
    <query xmlns="jabber:iq:register">
      <instructions>Choose a username and password to register with this server</instructions>
      <username/>
      <password/>
    </query>
   </iq>
   */
  if (![self isResultIQ] ||
      ![self hasCorrectXMLNS] ||
      ![self.elementID isEqualToString:kRegistrationElementID1]) return NO;

  return YES;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)isInBandRegistrationAnswer {
  /*
  <iq xmlns="jabber:client" from="crypto.cat" id="reg2" type="result">
    <query xmlns="jabber:iq:register">
      <username>foo</username>
      <password>bar</password>
    </query>
  </iq>
  */
  if (![self isResultIQ] ||
      ![self hasCorrectXMLNS] ||
      ![self.elementID isEqualToString:kRegistrationElementID2]) return NO;

  return YES;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)isInBandRegistrationError {
  /*
  <iq xmlns="jabber:client" from="crypto.cat" id="reg2" type="error">
    <query xmlns="jabber:iq:register">
      <username>foo</username>
      <password>bar</password>
    </query>
    <error code="409" type="cancel">
      <conflict xmlns="urn:ietf:params:xml:ns:xmpp-stanzas"/>
    </error>
  </iq>
  */
  
  if (![self isErrorIQ] ||
      ![self hasCorrectXMLNS] ||
      ![self.elementID isEqualToString:kRegistrationElementID2]) return NO;
  
  return YES;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSString *)instructions {
  NSXMLElement *instructionsElt = [[self query] elementForName:@"instructions"];
  
  return [instructionsElt stringValue];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSArray *)registrationFields {
  NSArray *children = [[self query] children];
  
  NSMutableArray *fieldNames = [NSMutableArray array];
  for (NSXMLElement *element in children) {
    NSString *name = [element name];
    if (![name isEqualToString:@"instructions"]) {
      [fieldNames addObject:name];
    }
  }
  
  return fieldNames;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)isRegistered {
  NSArray *children = [[self query] children];
  BOOL registered = NO;
  
  for (NSXMLElement *element in children) {
    if ([[element name] isEqualToString:@"registered"]) {
      registered = YES;
      break;
    }
  }
  
  return registered;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSString *)username {
  NSXMLElement *usernameElt = [[self query] elementForName:@"username"];
  
  return [usernameElt stringValue];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSInteger)errorCode {
  /*
  <iq xmlns="jabber:client" from="crypto.cat" id="reg2" type="error">
    <query xmlns="jabber:iq:register">
      <username>foo</username>
      <password>bar</password>
    </query>
    <error code="409" type="cancel">
      <conflict xmlns="urn:ietf:params:xml:ns:xmpp-stanzas"/>
    </error>
  </iq>
  */

  NSXMLElement *errorElt = [self elementForName:@"error"];
  return [errorElt attributeIntegerValueForName:@"code"];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSString *)errorType {
  NSXMLElement *errorElt = [self elementForName:@"error"];
  return [[errorElt elementForName:@"type"] stringValue];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (NSXMLElement *)registrationFieldsRequestIQForDomain:(NSString *)domain {
  /*
   <iq type='get' id='reg1' to='shakespeare.lit'>
    <query xmlns='jabber:iq:register'/>
   </iq>
  */
  NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:kInBandRegistrationXMLNS];
  
	NSXMLElement *iq = [NSXMLElement elementWithName:@"iq"];
	[iq addAttributeWithName:@"type" stringValue:@"get"];
	[iq addAttributeWithName:@"to" stringValue:domain];
	[iq addAttributeWithName:@"id" stringValue:kRegistrationElementID1];
	[iq addChild:query];
  
  return iq;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (NSXMLElement *)registrationIQForUsername:(NSString *)username password:(NSString *)password {
  /*
  <iq type='set' id='reg2'>
    <query xmlns='jabber:iq:register'>
      <username>bill</username>
      <password>Calliope</password>
    </query>
  </iq>
  */

  NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:kInBandRegistrationXMLNS];
  NSXMLElement *usernameElt = [NSXMLElement elementWithName:@"username" stringValue:username];
  NSXMLElement *passwordElt = [NSXMLElement elementWithName:@"password" stringValue:password];
  [query addChild:usernameElt];
  [query addChild:passwordElt];
  
	NSXMLElement *iq = [NSXMLElement elementWithName:@"iq"];
	[iq addAttributeWithName:@"type" stringValue:@"set"];
	[iq addAttributeWithName:@"id" stringValue:kRegistrationElementID2];
	[iq addChild:query];
  
  return iq;
}

@end

