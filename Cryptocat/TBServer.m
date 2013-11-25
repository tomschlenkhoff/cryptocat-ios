//
//  TBServer.m
//  Cryptocat
//
//  Created by Thomas Balthazar on 22/11/13.
//  Copyright (c) 2013 Thomas Balthazar. All rights reserved.
//

#import "TBServer.h"

#define kDefaultsUserSavedServersKey  @"TBUserSavedServers"

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TBServer ()

- (NSDictionary *)serverDic;
+ (NSArray *)defaultServers;
+ (NSInteger)indexForServerName:(NSString *)serverName;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TBServer

////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)init {
  if (self=[super init]) {
    _name = @"";
    _domain = @"";
    _conferenceServer = @"";
    _boshRelay = @"";
    _readonly = NO;
  }
  
  return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Public Methods

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (BOOL)addServer:(TBServer *)server {
  if ([self indexForServerName:server.name]!=-1) return NO; // name already exists
  
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSMutableArray *serverDics = [defaults mutableArrayValueForKey:kDefaultsUserSavedServersKey];
  NSDictionary *serverDic = server.serverDic;
  [serverDics addObject:serverDic];
  [defaults setObject:serverDics forKey:kDefaultsUserSavedServersKey];
  [defaults synchronize];
  
  return YES;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (BOOL)updateServer:(TBServer *)server atIndex:(NSUInteger)index {
  NSUInteger nbDefaultServers = [[self defaultServers] count];
  NSUInteger adjustedIndex = index - nbDefaultServers;
  NSInteger foundIndex = [self indexForServerName:server.name];
  if (foundIndex!=-1 && foundIndex!=adjustedIndex) return NO; // name already exists
  
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSMutableArray *serverDics = [defaults mutableArrayValueForKey:kDefaultsUserSavedServersKey];
  [serverDics replaceObjectAtIndex:adjustedIndex withObject:server.serverDic];
  [defaults setObject:serverDics forKey:kDefaultsUserSavedServersKey];
  [defaults synchronize];

  return YES;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (BOOL)deleteServer:(TBServer *)server {
  NSInteger index = [self indexForServerName:server.name];
  if (index==-1) return NO;
  
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSMutableArray *serverDics = [defaults mutableArrayValueForKey:kDefaultsUserSavedServersKey];
  [serverDics removeObjectAtIndex:index];
  [defaults setObject:serverDics forKey:kDefaultsUserSavedServersKey];
  [defaults synchronize];

  return YES;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (NSArray *)servers {
  NSMutableArray *servers = [NSMutableArray arrayWithArray:[self defaultServers]];
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults synchronize];
  
  NSArray *serverDics = [defaults arrayForKey:kDefaultsUserSavedServersKey];
  for (NSDictionary *serverDic in serverDics) {
    TBServer *server = [[TBServer alloc] init];
    server.name = [serverDic objectForKey:@"name"];
    server.domain = [serverDic objectForKey:@"domain"];
    server.conferenceServer = [serverDic objectForKey:@"conferenceServer"];
    server.boshRelay = [serverDic objectForKey:@"boshRelay"];
    server.readonly = NO;
    [servers addObject:server];
  }
  
  return servers;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private Methods

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSDictionary *)serverDic {
  return @{@"name": self.name,
           @"domain": self.domain,
           @"conferenceServer": self.conferenceServer,
           @"boshRelay": self.boshRelay};
}

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (NSArray *)defaultServers {
  TBServer *server = [[TBServer alloc] init];
  server.name = @"Cryptocat";
  server.domain = @"crypto.cat";
  server.conferenceServer = @"conference.crypto.cat";
  server.readonly = YES;
  
  return @[server];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (NSInteger)indexForServerName:(NSString *)serverName {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults synchronize];
  NSArray *serverDics = [defaults arrayForKey:kDefaultsUserSavedServersKey];
  NSUInteger nbServers = [serverDics count];
  
  for (NSInteger i = 0; i < nbServers; i++) {
    NSDictionary *serverDic = [serverDics objectAtIndex:i];
    if ([[serverDic objectForKey:@"name"] isEqualToString:serverName]) {
      return i;
    }
  }

  return -1; // not found
}

@end
