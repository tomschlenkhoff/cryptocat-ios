//
//  TBServer.h
//  Cryptocat
//
//  Created by Thomas Balthazar on 22/11/13.
//  Copyright (c) 2013 Thomas Balthazar. All rights reserved.
//

#import <Foundation/Foundation.h>

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TBServer : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *domain;
@property (nonatomic, strong) NSString *conferenceServer;
@property (nonatomic, strong) NSString *boshRelay;
@property (nonatomic, assign, getter=isReadonly) BOOL readonly;

@end
