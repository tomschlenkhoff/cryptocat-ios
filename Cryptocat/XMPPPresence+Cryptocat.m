//
//  XMPPPresence+Cryptocat.m
//  Cryptocat
//
//  Created by Thomas Balthazar on 16/10/13.
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

#import "XMPPPresence+Cryptocat.h"
#import "XMPP.h"

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation XMPPPresence (Cryptocat)

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)tb_isNicknameAlreadyInUseError {
  /*
   <presence xmlns="jabber:client" from="cryptocatdev@conference.crypto.cat/thomas" to="hddhc5zrzssl5c46@crypto.cat/7811709081382361623482160" type="error">
    <x xmlns="http://jabber.org/protocol/muc">
      <password>AbC7L62mjbhRKJBH</password>
    </x>
    <error code="409" type="cancel">
      <conflict xmlns="urn:ietf:params:xml:ns:xmpp-stanzas"/>
      <text xmlns="urn:ietf:params:xml:ns:xmpp-stanzas">
        That nickname is already in use by another occupant
      </text>
    </error>
   </presence>
  */
  if (!self.isErrorPresence) return NO;

  NSString *errorCode = [[[[self elementsForName:@"error"]
                           firstObject]
                          attributeForName:@"code"]
                         stringValue];

  return [errorCode isEqualToString:@"409"];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)tb_isAvailable {
  return [self.type isEqualToString:@"available"] && ![self.status isEqualToString:@"away"];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)tb_isAway {
  return [self.type isEqualToString:@"available"] && [self.status isEqualToString:@"away"];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)tb_isUnavailable {
  return [self.type isEqualToString:@"unavailable"];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (XMPPPresence *)tb_availablePresenceForJID:(XMPPJID *)JID {
  XMPPPresence *presence = [XMPPPresence presence];
  [presence addAttributeWithName:@"xmlns" stringValue:@"jabber:client"];
  // don't know why but to send an away presence for a user, I have to set the user name as the
  // "to" field (I thought it would have been the "from" field). also, setting a "from" attribute
  // logs me out.
  [presence addAttributeWithName:@"to" stringValue:JID.full];

  return presence;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (XMPPPresence *)tb_awayPresenceForJID:(XMPPJID *)JID {
  XMPPPresence *presence = [XMPPPresence presence];
  [presence addAttributeWithName:@"xmlns" stringValue:@"jabber:client"];
  // don't know why but to send an away presence for a user, I have to set the user name as the
  // "to" field (I thought it would have been the "from" field). also, setting a "from" attribute
  // logs me out.
  [presence addAttributeWithName:@"to" stringValue:JID.full];
  NSXMLElement *show = [NSXMLElement elementWithName:@"show"];
  [show setStringValue:@"away"];
  [presence addChild:show];
  NSXMLElement *status = [NSXMLElement elementWithName:@"status"];
  [status setStringValue:@"away"];
  [presence addChild:status];

  return presence;
}

@end
