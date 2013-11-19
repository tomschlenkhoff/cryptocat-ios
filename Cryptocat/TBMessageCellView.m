//
//  TBMessageCellView.m
//  ChatView
//
//  Created by Thomas Balthazar on 07/11/13.
//  Copyright (c) 2013 Thomas Balthazar. All rights reserved.
//

#import "TBMessageCellView.h"

#define kMaxWidthPortrait       	296.0
#define kMaxWidthLandscape      	437.0
#define kSenderLabelPaddingLeft   7.0
#define kSenderLabelPaddingRight  7.0

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TBMessageCellView () <UITextViewDelegate>

@property (nonatomic, strong) UITextView *textView;

+ (CGSize)textViewSizeForText:(NSString *)text;
+ (NSDictionary *)textAttributes;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TBMessageCellView

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Lifecycle

////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    // -- text view
    _textView = [[UITextView alloc] init];
    _textView.editable = NO;
    _textView.scrollEnabled = NO;
    _textView.backgroundColor = [UIColor whiteColor];
    _textView.font = [[self class] font];
    _textView.textContainerInset = UIEdgeInsetsMake(-0.5, 0.0, 0.0, 0.0);
    _textView.textContainer.lineFragmentPadding = 0.0;
    _textView.dataDetectorTypes = UIDataDetectorTypeLink;
    _textView.delegate = self;
    [self addSubview:_textView];
  }
  
  return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Public Methods

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setMessage:(NSString *)message {
  self.textView.attributedText = [[NSAttributedString alloc] initWithString:message
                                                          attributes:[[self class] textAttributes]];
  [self setNeedsLayout];
  [self.bubbleView setNeedsDisplay];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSString *)message {
  return self.textView.text;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (CGSize)sizeForText:(NSString *)text {
  CGSize textViewSize = [self textViewSizeForText:text];
  CGSize bubbleSize = [TBBubbleView sizeForContentSize:textViewSize];
  
  return bubbleSize;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private Methods

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (CGSize)textViewSizeForText:(NSString *)text {
  // get the keyboard height depending on the device orientation
  UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
  BOOL isPortrait = orientation==UIInterfaceOrientationPortrait;
  CGFloat maxWidth = isPortrait ? kMaxWidthPortrait : kMaxWidthLandscape;
  
	CGSize maxSize = CGSizeMake(maxWidth, CGFLOAT_MAX);
  
  CGRect boundingRect = [text boundingRectWithSize:maxSize
                                           options:
                         (NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                        attributes:[self textAttributes]
                                           context:nil];
  CGFloat width = ceilf(boundingRect.size.width);
  CGFloat height = ceilf(boundingRect.size.height);

  return CGSizeMake(width, height);
}

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (NSDictionary *)textAttributes {
  NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
  [paragraphStyle setLineBreakMode:NSLineBreakByWordWrapping];
  return @{ NSFontAttributeName: [self font],
            NSParagraphStyleAttributeName: paragraphStyle};
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UIView

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)layoutSubviews {
  [super layoutSubviews];
  
  CGRect textViewFrame = self.bubbleView.contentFrame;

  // adapt for 1 line bubble sender label background
  CGRect senderLabelBackgroundFrame = self.senderLabelBackground.frame;
  BOOL textIsOnOneLine = textViewFrame.size.height < senderLabelBackgroundFrame.size.height;
  if (textIsOnOneLine) {
    senderLabelBackgroundFrame.size.height+=1.0;
    self.senderLabelBackground.frame = senderLabelBackgroundFrame;
  }
  
  // textView
  CGRect exclustionFrame = self.senderLabel.frame;
  exclustionFrame.origin = CGPointZero;
  exclustionFrame.size.width+=kSenderLabelPaddingLeft+kSenderLabelPaddingRight;
  exclustionFrame.size.height-=4.0;
  UIBezierPath *exclusionPath = [UIBezierPath bezierPathWithRect:exclustionFrame];
  self.textView.textContainer.exclusionPaths = @[exclusionPath];
  self.textView.frame = textViewFrame;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UITextViewDelegate

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)textView:(UITextView *)textView
shouldInteractWithURL:(NSURL *)URL
         inRange:(NSRange)characterRange {
  if ([self.delegate
       respondsToSelector:@selector(messageCellView:shouldInteractWithURL:inRange:)]) {
    return [self.delegate messageCellView:self shouldInteractWithURL:URL inRange:characterRange];
  }
  
  return NO;
}

@end
