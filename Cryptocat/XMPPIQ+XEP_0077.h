//
//  XMPPIQ+XEP_0077.h
//  Cryptocat
//
//  Created by Thomas Balthazar on 24/09/13.
//  Copyright (c) 2013 Thomas Balthazar. All rights reserved.
//

#import "XMPPIQ.h"

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface XMPPIQ (XEP_0077)

- (BOOL)isInBandRegistrationFieldsAnswer;
- (BOOL)isInBandRegistrationAnswer;
- (BOOL)isInBandRegistrationError;

- (NSString *)instructions;
- (NSArray *)registrationFields;
- (BOOL)isRegistered;
- (NSString *)username;
- (NSInteger)errorCode;
- (NSString *)errorType;

+ (NSXMLElement *)registrationFieldsRequestIQForDomain:(NSString *)domain;
+ (NSXMLElement *)registrationIQForUsername:(NSString *)username password:(NSString *)password;

@end
