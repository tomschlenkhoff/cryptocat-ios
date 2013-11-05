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

@property (weak, nonatomic) IBOutlet UITextField *conversationNameField;
@property (weak, nonatomic) IBOutlet UITextField *nicknameField;
@property (weak, nonatomic) IBOutlet UILabel *legendLabel;
@property (weak, nonatomic) IBOutlet TBButtonCell *buttonCell;

- (void)connect;
- (NSError *)errorForConversationName:(NSString *)conversationName nickname:(NSString *)nickname;

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
  
//#if DEBUG
//  self.conversationNameField.text = @"cryptocatdev";
//  self.nicknameField.text = @"iOSTestApp";
//#endif
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
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UITextFieldDelegate

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)textField:(UITextField *)textField
shouldChangeCharactersInRange:(NSRange)range
replacementString:(NSString *)string {
  NSUInteger maxLength = 0;
  if (textField==self.conversationNameField) {
    maxLength = 20;
  }
  else if (textField==self.nicknameField) {
    maxLength = 16;
  }
  
  NSUInteger newLength = textField.text.length + string.length - range.length;
  return (newLength > maxLength) ? NO : YES;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UITableViewDelegate

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  // -- connect button
  if (indexPath.section==1) {
    [self connect];
    
    // deselect the cell
    double delayInSeconds = 0.25;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
      [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    });
  }
}

@end
