//
//  TBMacros.h
//
//  Created by Thomas Balthazar on 30/07/13.
//  Copyright (c) 2013 Thomas Balthazar. All rights reserved.
//

#ifdef DEBUG
  #define TBLOGMARK NSLog(@"== %s:%d(%p)", __PRETTY_FUNCTION__, __LINE__, self)
  #define TBLOG(...) NSLog(@"%s:%d(%p) %@", __PRETTY_FUNCTION__, __LINE__, self, [NSString stringWithFormat:__VA_ARGS__])
  #define TBALOG(...) {NSLog(@"%s:%d(%p) %@", __PRETTY_FUNCTION__, __LINE__, self, [NSString stringWithFormat:__VA_ARGS__]);[[NSAssertionHandler currentHandler] handleFailureInFunction:[NSString stringWithCString:__PRETTY_FUNCTION__ encoding:NSUTF8StringEncoding] file:[NSString stringWithCString:__FILE__ encoding:NSUTF8StringEncoding] lineNumber:__LINE__ description:__VA_ARGS__];}
#else
  #define TBLOGMARK do { } while (0)
  #define TBLOG(...) do { } while (0)
  #define TBALOG(...) NSLog(@"== %s:%d(%p)", __PRETTY_FUNCTION__, __LINE__, self)
#endif

#define TBASSERT(condition, ...) do { if (!(condition)) { TBALOG(__VA_ARGS__); }} while(0)