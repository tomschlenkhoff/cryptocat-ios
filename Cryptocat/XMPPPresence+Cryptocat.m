//
//  XMPPPresence+Cryptocat.m
//  Cryptocat
//
//  Created by Thomas Balthazar on 16/10/13.
//  Copyright (c) 2013 Thomas Balthazar. All rights reserved.
//

#import "XMPPPresence+Cryptocat.h"

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

@end
