//
//  XMPPMessage+Cryptocat.m
//  Cryptocat
//
//  Created by Thomas Balthazar on 26/09/13.
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

#import "XMPPMessage+Cryptocat.h"
#import "XMPP.h"
#import "NSString+Cryptocat.h"
#import "XMPPMessage+XEP_0085.h"

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation XMPPMessage (Cryptocat)

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)tb_isActiveMessage {
  return [self hasActiveChatState] || [[self elementForName:@"x"] elementForName:@"active"]!=nil;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)tb_isPublicKeyMessage {
  NSDictionary *jsonData = [[self body] tb_JSONObject];
  return [[jsonData objectForKey:@"type"] isEqualToString:@"publicKey"];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)tb_isPublicKeyRequestMessage {
  NSDictionary *jsonData = [[self body] tb_JSONObject];
  return [[jsonData objectForKey:@"type"] isEqualToString:@"publicKeyRequest"];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSString *)tb_publicKey {
  /*
  {
    "type":"publicKey",
    "text": {
      "iOSTestApp": {
        "message":"+kzVSOSVe9X3bt/QAH8YtRAgcLERpKZ0CKEpSPRI724="
      }
    }
  }
  */
  
  NSDictionary *jsonData = [[self body] tb_JSONObject];
  return [[[[jsonData objectForKey:@"text"] allValues] lastObject] objectForKey:@"message"];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Chat State

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)tb_isArchiveMessage {
  return [[self elementsForName:@"delay"] count] > 0;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)tb_isComposingMessage {
  return [self hasComposingChatState] ||
          [[self elementForName:@"x"] elementForName:@"composing"]!=nil;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)tb_isPausedMessage {
  return [self hasPausedChatState] || [[self elementForName:@"x"] elementForName:@"paused"]!=nil;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)tb_isChatState {
  return [self hasChatState] || [self tb_isComposingMessage] ||
          [self tb_isActiveMessage] || [self tb_isPausedMessage];
}

@end
