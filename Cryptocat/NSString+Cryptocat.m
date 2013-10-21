//
//  NSString+Cryptocat.m
//  Cryptocat
//
//  Created by Thomas Balthazar on 26/09/13.
//  Copyright (c) 2013 Thomas Balthazar. All rights reserved.
//

#import "NSString+Cryptocat.h"

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation NSString (Cryptocat)

////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)tb_JSONObject {
  NSData *JSONData = [self dataUsingEncoding:NSUTF8StringEncoding];
  return [NSJSONSerialization JSONObjectWithData:JSONData options:0 error:nil];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSString *)tb_trim {
  return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (NSString *)tb_randomStringWithLength:(NSInteger)length {
  NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
  NSMutableString *randomString = [NSMutableString stringWithCapacity:length];
  
  for (NSInteger i=0; i < length; i++) {
    NSUInteger index = arc4random() % [letters length];
    [randomString appendFormat: @"%C", [letters characterAtIndex:index]];
  }
  
  return randomString;
}

@end
