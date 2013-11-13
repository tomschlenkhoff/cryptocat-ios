//
//  TBLoginViewController.m
//  Cryptocat
//
//  Created by Thomas Balthazar on 21/10/13.
//  Copyright (c) 2013 Thomas Balthazar. All rights reserved.
//

#import "TBLoginViewController.h"
#import "TBChatViewController.h"
#import "NSString+Cryptocat.h"
#import "NSError+Cryptocat.h"
#import "UIColor+Cryptocat.h"
#import "TBButtonCell.h"

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TBLoginViewController () <UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextField *conversationNameField;
@property (weak, nonatomic) IBOutlet UITextField *nicknameField;
@property (weak, nonatomic) IBOutlet UILabel *legendLabel;
@property (weak, nonatomic) IBOutlet TBButtonCell *buttonCell;
@property (nonatomic, assign) BOOL shouldPreventTableViewAutoScrolling;

- (void)connect;
- (NSError *)errorForConversationName:(NSString *)conversationName nickname:(NSString *)nickname;
- (BOOL)shouldConnectButtonBeEnabled;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TBLoginViewController

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Lifecycle

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardDidShow:)
                                               name:UIKeyboardDidShowNotification
                                             object:nil];
  self.shouldPreventTableViewAutoScrolling = YES;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:UIKeyboardDidShowNotification
                                                object:nil];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewDidLoad {
  [super viewDidLoad];
  
  // -- colors
  [self.navigationController setNavigationBarHidden:YES animated:NO];
  self.tableView.backgroundColor = [UIColor tb_backgroundColor];
  self.tableView.tableHeaderView.backgroundColor = [UIColor tb_backgroundColor];
  self.legendLabel.textColor = [UIColor tb_tableViewSectionTitleColor];
  self.conversationNameField.textColor = [UIColor tb_tableViewCellTextColor];
  self.nicknameField.textColor = [UIColor tb_tableViewCellTextColor];
  self.buttonCell.titleColor = [UIColor tb_buttonTitleColor];
  
  // -- labels
  self.title = @"Cryptocat";
  self.legendLabel.text = NSLocalizedString(
                @"Enter a name for your conversation.\nShare it with people you'd like to talk to.",
                @"Login Screen Legend");
  self.conversationNameField.placeholder = NSLocalizedString(@"conversation name",
                                                            @"conversation name Field Placeholder");
  self.nicknameField.placeholder = NSLocalizedString(@"your nickname",
                                                     @"your nickname Field Placeholder");
  self.buttonCell.title = NSLocalizedString(@"Connect", @"Connect Button Title");
  
  self.buttonCell.enabled = [self shouldConnectButtonBeEnabled];
  
#if DEBUG
  self.conversationNameField.text = @"cryptocatdev";
  self.nicknameField.text = @"iOSTestApp";
#endif
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Public Methods

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)showError:(NSError *)error {
  NSString *title = NSLocalizedString(@"Error", @"Connection Error Alert Title");
  NSString *cancelTitle = NSLocalizedString(@"Ok", @"Error Alert View Ok Button Title");
  UIAlertView *av = [[UIAlertView alloc] initWithTitle:title
                                               message:[error tb_message]
                                              delegate:self
                                     cancelButtonTitle:cancelTitle
                                     otherButtonTitles:nil];
  [av show];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private Methods

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)connect {
  NSString *conversationName = [self.conversationNameField.text tb_trim];
  NSString *nickname = [self.nicknameField.text tb_trim];
  
  NSError *error = [self errorForConversationName:conversationName nickname:nickname];
  if (error!=nil) {
    [self showError:error];
  }
  else {
    if ([self.delegate
         respondsToSelector:@selector(loginController:didAskToConnectWithRoomName:nickname:)]) {
      [self.delegate loginController:self
         didAskToConnectWithRoomName:conversationName
                            nickname:nickname];
    }
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSError *)errorForConversationName:(NSString *)conversationName nickname:(NSString *)nickname {
  NSCharacterSet *alphaNumericCharSet = [NSCharacterSet alphanumericCharacterSet];

  // -- check that conversationname is not empty
  if ([conversationName isEqualToString:@""]) {
    NSString *message = NSLocalizedString(@"Please enter a conversation name.",
                                          @"Please enter a conversation name. Error Message");
    return [NSError tb_errorWithMessage:message];
  }
  
  // -- check that conversation name is 1..20 alphanumeric
  if (![[conversationName
         stringByTrimmingCharactersInSet:alphaNumericCharSet] isEqualToString:@""]) {
    NSString *message = NSLocalizedString(@"Conversation name must be alphanumeric.",
                                          @"Conversation name must be alphanumeric. Error Message");
    return [NSError tb_errorWithMessage:message];
  }
  
  // -- check that nickname is not empty
  if ([nickname isEqualToString:@""]) {
    NSString *message = NSLocalizedString(@"Please enter a nickname.",
                                          @"Please enter a nickname. Error Message");
    return [NSError tb_errorWithMessage:message];
  }

  // -- check that conversation name is 1..16 alphanumeric
  if (![[nickname
         stringByTrimmingCharactersInSet:alphaNumericCharSet] isEqualToString:@""]) {
    NSString *message = NSLocalizedString(@"Nickname must be alphanumeric.",
                                          @"Nickname must be alphanumeric. Error Message");
    return [NSError tb_errorWithMessage:message];
  }
  
  return nil;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)shouldConnectButtonBeEnabled {
  return ![self.conversationNameField.text isEqualToString:@""] &&
         ![self.nicknameField.text isEqualToString:@""];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UITextFieldDelegate

///////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  if (textField==self.conversationNameField) {
    [self.nicknameField becomeFirstResponder];
    return YES;
  }
  else if (textField==self.nicknameField) {
    if ([self shouldConnectButtonBeEnabled]) {
      [self connect];
      return YES;
    }
    else {
      return NO;
    }
  }
  return YES;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)textField:(UITextField *)textField
shouldChangeCharactersInRange:(NSRange)range
replacementString:(NSString *)string {
  NSUInteger newLength = textField.text.length + string.length - range.length;

  NSUInteger maxLength = 0;
  if (textField==self.conversationNameField) {
    self.buttonCell.enabled = newLength > 0 && self.nicknameField.text.length > 0;
    maxLength = 20;
  }
  else if (textField==self.nicknameField) {
    self.buttonCell.enabled = newLength > 0 && self.conversationNameField.text.length > 0;
    maxLength = 16;
  }
  
  return (newLength > maxLength) ? NO : YES;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UITableViewDelegate

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSIndexPath *)tableView:(UITableView *)tableView
  willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  // -- connect button
  if (indexPath.section==1) {
    return [self shouldConnectButtonBeEnabled] ? indexPath : nil;;
  }
  
  return nil;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  // -- connect button
  if (indexPath.section==1) {
    [self connect];
    
    // deselect the cell
    double delayInSeconds = 0.25;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW,
                                            (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
      [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    });
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UIScrollViewDelegate

////////////////////////////////////////////////////////////////////////////////////////////////////
/*
 * Trick to prevent the tableView from automatically scrolling when a field becomes first responder.
 * The tableView will be manually scrolled when the keyboard is shown to show the whole form.
 */
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  if (self.shouldPreventTableViewAutoScrolling) {
    CGPoint contentOffset = scrollView.contentOffset;
    contentOffset.y = 0;
    self.tableView.contentOffset = contentOffset;
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Observers

////////////////////////////////////////////////////////////////////////////////////////////////////
/*
 * Trick to show the whole login form when a field becomes first responder.
 */
- (void)keyboardDidShow:(NSNotification *)notification {
  double delayInSeconds = 0.01;
  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW,
                                          (int64_t)(delayInSeconds * NSEC_PER_SEC));
  dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
    self.shouldPreventTableViewAutoScrolling = NO;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:1];
    [self.tableView scrollToRowAtIndexPath:indexPath
                          atScrollPosition:UITableViewScrollPositionTop
                                  animated:YES];
  });
}

@end
