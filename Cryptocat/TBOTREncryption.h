//
//  TBOTREncryption.h
//  TBOTRWrapper
//
//  Created by Thomas Balthazar on 25/09/13.
//  Copyright (c) 2013 Thomas Balthazar. All rights reserved.
//

#import <Foundation/Foundation.h>

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TBOTREncryption : NSObject

+ (TBOTREncryption *)sharedOTREncryption;

- (void)requestOTRSessionWithAccount:(NSString *)account;
- (void)encodeMessage:(NSString *)message
            recipient:(NSString *)recipient
          accountName:(NSString *)accountName
             protocol:(NSString *)protocol;
@end
