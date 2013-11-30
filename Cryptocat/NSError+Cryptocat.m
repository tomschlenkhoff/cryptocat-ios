//
//  NSError+Cryptocat.m
//  Cryptocat
//
//  Created by Thomas Balthazar on 21/10/13.
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

#import "NSError+Cryptocat.h"

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation NSError (Cryptocat)

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (NSError *)tb_errorWithMessage:(NSString *)message {
  return [self tb_errorWithCode:0 message:message];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (NSError *)tb_errorWithCode:(NSInteger)code message:(NSString *)message {
  return [NSError errorWithDomain:@"crypto.cat"
                             code:code
                         userInfo:@{@"message": message}];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSString *)tb_message {
  if (self.userInfo!=nil && [self.userInfo objectForKey:@"message"]!=nil) {
    return [self.userInfo objectForKey:@"message"];
  }
  return nil;
}

@end
