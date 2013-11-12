//
//  TBChatToolbarView.m
//  ChatView
//
//  Created by Thomas Balthazar on 06/11/13.
//  Copyright (c) 2013 Thomas Balthazar. All rights reserved.
//

#import "TBChatToolbarView.h"

#define kBackgroundColor  [UIColor colorWithRed:0.969 green:0.969 blue:0.980 alpha:1.000]

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TBChatToolbarView () <UITextViewDelegate>

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TBChatToolbarView

////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithCoder:(NSCoder *)aDecoder {
  NSLog(@"-- initWithCoder");
  if (self=[super initWithCoder:aDecoder]) {
    self.backgroundColor = kBackgroundColor;
    //self.translatesAutoresizingMaskIntoConstraints = NO;
    
    // -- textView
    _textView = [[UITextView alloc] initWithFrame:CGRectZero];
    _textView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    
    _textView.font = [UIFont systemFontOfSize:14.0f];
    _textView.delegate = self;
    _textView.backgroundColor = [UIColor whiteColor];
    _textView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_textView];
    
    // -- button
    _sendButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_sendButton setTitle:@"Send" forState:UIControlStateNormal];
    [_sendButton sizeToFit];
    _sendButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_sendButton];
  }
  
  return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)awakeFromNib {
  [super awakeFromNib];
  NSLog(@"-- awakeFromNib");
  
  NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(_textView, _sendButton);
  
  [self addConstraints:
   [NSLayoutConstraint constraintsWithVisualFormat:@"|-[_textView]-[_sendButton]-|"
                                           options:0
                                           metrics:0
                                             views:viewsDictionary]];

  [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-7-[_textView(30)]-7-|"
                                                               options:0
                                                               metrics:0
                                                                 views:viewsDictionary]];

  [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-7-[_sendButton]-7-|"
                                                               options:0
                                                               metrics:0
                                                                 views:viewsDictionary]];

}

@end
