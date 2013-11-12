//
//  TBBuddy.h
//  Cryptocat
//
//  Created by Thomas Balthazar on 24/10/13.
//  Copyright (c) 2013 Thomas Balthazar. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XMPPJID;

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TBBuddy : NSObject

@property (nonatomic, readonly) NSString *nickname;
@property (nonatomic, readonly) NSString *fullname;
@property (nonatomic, strong) NSString *roomName;
@property (nonatomic, strong) NSString *chatFingerprint;
@property (nonatomic, strong) NSString *groupChatFingerprint;
@property (nonatomic, readonly) XMPPJID *XMPPJID;

- (id)initWithXMPPJID:(XMPPJID *)XMPPJID;

@end
