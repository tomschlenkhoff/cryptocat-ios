//
//  TBChatViewController.m
//  Cryptocat
//
//  Created by Thomas Balthazar on 16/10/13.
//  Copyright (c) 2013 Thomas Balthazar. All rights reserved.
//

#import "TBChatViewController.h"
#import "TBXMPPMessagesHandler.h"
#import "TBBuddiesViewController.h"
#import "TBMeViewController.h"
#import "TBBuddy.h"

#define kPausedMessageTimer 5.0

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TBChatViewController () <
  UITableViewDataSource,
  UITableViewDelegate,
  TBBuddiesViewControllerDelegate,
  TBMeViewControllerDelegate,
  UITextFieldDelegate
>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *toolbarView;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (nonatomic, strong) NSMutableDictionary *messagesForConversation;
@property (nonatomic, strong) NSString *currentRoomName;
@property (nonatomic, strong) TBBuddy *currentRecipient;
@property (strong, readwrite) NSTimer *composingTimer;
@property (nonatomic, assign, getter=isTyping) BOOL typing;

- (void)startObservingKeyboard;
- (void)stopObservingKeyboard;
- (IBAction)sendMessage:(id)sender;
- (BOOL)isInConversationRoom;
- (void)setupTypingTimer;
- (void)cancelTypingTimer;
- (void)didStartComposing;
- (void)didPauseComposing;
- (void)didEndComposing;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TBChatViewController

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Lifecycle

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewDidLoad {
  [super viewDidLoad];
	 
  self.typing = NO;
  self.messagesForConversation = [NSMutableDictionary dictionary];

  NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
  [defaultCenter addObserver:self
                    selector:@selector(didReceiveGroupMessage:)
                        name:TBDidReceiveGroupChatMessageNotification
                      object:nil];
  [defaultCenter addObserver:self
                    selector:@selector(didReceivePrivateMessage:)
                        name:TBDidReceivePrivateChatMessageNotification
                      object:nil];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];

  // the first time the view appears, after the loginVC is dismissed
  if (self.currentRoomName==nil) {
    self.currentRoomName = self.roomName;
    self.title = self.roomName;
  }
  
  [self startObservingKeyboard];
  TBLOGMARK;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  
  [self stopObservingKeyboard];
  TBLOGMARK;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  // -- buddies
  if ([segue.identifier isEqualToString:@"BuddiesSegueID"]) {
    UINavigationController *nc = segue.destinationViewController;
    TBBuddiesViewController *bvc = (TBBuddiesViewController *)nc.topViewController;
    bvc.delegate = self;
    bvc.roomName = self.roomName;
    bvc.buddies = self.buddies;
  }
  
  // -- me
  else if ([segue.identifier isEqualToString:@"MeSegueID"]) {
    UINavigationController *nc = segue.destinationViewController;
    TBMeViewController *mvc = (TBMeViewController *)nc.topViewController;
    mvc.delegate = self;
    mvc.me = self.me;
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UITableViewDataSource

////////////////////////////////////////////////////////////////////////////////////////////////////
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *cellID = @"cellID";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                  reuseIdentifier:cellID];
  }

  NSMutableArray *messages = [self.messagesForConversation objectForKey:self.currentRoomName];
  cell.textLabel.text = [messages objectAtIndex:indexPath.row];
  
  return cell;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  NSMutableArray *messages = [self.messagesForConversation objectForKey:self.currentRoomName];
  return [messages count];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Observers

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didReceiveGroupMessage:(NSNotification *)notification {
  NSString *roomName = notification.object;
  NSString *message = [notification.userInfo objectForKey:@"message"];
  NSString *sender = [notification.userInfo objectForKey:@"sender"];
  
  NSString *receivedMessage = [NSString stringWithFormat:@"%@ : %@", sender, message];
  
  if ([self.messagesForConversation objectForKey:roomName]==nil) {
    [self.messagesForConversation setObject:[NSMutableArray array] forKey:roomName];
  }

  [[self.messagesForConversation objectForKey:roomName] addObject:receivedMessage];
  [self.tableView reloadData];
  TBLOG(@"-- received message in %@ from %@: %@", roomName, sender, message);
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didReceivePrivateMessage:(NSNotification *)notification {
  NSString *message = [notification.userInfo objectForKey:@"message"];
  if ([message isEqualToString:@""]) return ;
  
  TBBuddy *sender = notification.object;
  NSString *receivedMessage = [NSString stringWithFormat:@"%@ : %@", self.title, message];
  
  if ([self.messagesForConversation objectForKey:sender.fullname]==nil) {
    [self.messagesForConversation setObject:[NSMutableArray array] forKey:sender.fullname];
  }
  
  [[self.messagesForConversation objectForKey:sender.fullname] addObject:receivedMessage];
  [self.tableView reloadData];
  TBLOG(@"-- received private message from %@: %@", sender.fullname, message);
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)keyboardWillShow:(NSNotification *)notification {
  NSDictionary* info = [notification userInfo];
  CGSize keyboardSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
  
  UIEdgeInsets contentInsets = self.tableView.contentInset;
  contentInsets.bottom+=keyboardSize.height;
  
  self.tableView.contentInset = contentInsets;
  self.tableView.scrollIndicatorInsets = contentInsets;
  
  CGRect toolbarFrame = self.toolbarView.frame;
  toolbarFrame.origin.y-=keyboardSize.height;

  double keyboardTransitionDuration;
  [[notification.userInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey]
   getValue:&keyboardTransitionDuration];
  
  UIViewAnimationCurve keyboardTransitionAnimationCurve;
  [[notification.userInfo valueForKey:UIKeyboardAnimationCurveUserInfoKey]
   getValue:&keyboardTransitionAnimationCurve];

  // start animation
  [UIView beginAnimations:nil context:NULL];
  [UIView setAnimationDuration:keyboardTransitionDuration];
  [UIView setAnimationCurve:keyboardTransitionAnimationCurve];
  [UIView setAnimationBeginsFromCurrentState:YES];
  
  self.toolbarView.frame = toolbarFrame;
  
  [UIView commitAnimations];
  // end animation
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)keyboardWillBeHidden:(NSNotification *)notification {
  NSDictionary* info = [notification userInfo];
  CGSize keyboardSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
  
  UIEdgeInsets contentInsets = self.tableView.contentInset;
  contentInsets.bottom-=keyboardSize.height;
  
  self.tableView.contentInset = contentInsets;
  self.tableView.scrollIndicatorInsets = contentInsets;

  CGRect toolbarFrame = self.toolbarView.frame;
  toolbarFrame.origin.y+=keyboardSize.height;
  self.toolbarView.frame = toolbarFrame;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private Methods

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)startObservingKeyboard {
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWillShow:)
                                               name:UIKeyboardWillShowNotification
                                             object:nil];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWillBeHidden:)
                                               name:UIKeyboardWillHideNotification
                                             object:nil];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)stopObservingKeyboard {
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:UIKeyboardWillShowNotification
                                                object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:UIKeyboardWillHideNotification
                                                object:nil];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)isInConversationRoom {
  return [self.roomName isEqualToString:self.currentRoomName];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setupTypingTimer {
  [self cancelTypingTimer];
  TBLOG(@"-- starting the timer");
  self.composingTimer = [NSTimer scheduledTimerWithTimeInterval:kPausedMessageTimer
                                                         target:self
                                                       selector:@selector(typingDidPause)
                                                       userInfo:nil
                                                        repeats:NO];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)cancelTypingTimer {
  if (self.composingTimer) {
    TBLOG(@"-- cancelling the timer");
    [self.composingTimer invalidate];
    self.composingTimer = nil;
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didStartComposing {
  self.typing = YES;
  if ([self.delegate
       respondsToSelector:@selector(chatViewControllerDidStartComposing:forRecipient:)]) {
    [self.delegate chatViewControllerDidStartComposing:self forRecipient:self.currentRecipient];
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didPauseComposing {
  self.typing = NO;
  if ([self.delegate
       respondsToSelector:@selector(chatViewControllerDidPauseComposing:forRecipient:)]) {
    [self.delegate chatViewControllerDidPauseComposing:self forRecipient:self.currentRecipient];
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didEndComposing {
  self.typing = NO;
  if ([self.delegate
       respondsToSelector:@selector(chatViewControllerDidEndComposing:forRecipient:)]) {
    [self.delegate chatViewControllerDidEndComposing:self forRecipient:self.currentRecipient];
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Actions

////////////////////////////////////////////////////////////////////////////////////////////////////
- (IBAction)sendMessage:(id)sender {
  NSString *message = self.textField.text;
  [[self.messagesForConversation objectForKey:self.currentRoomName] addObject:message];
  [self.tableView reloadData];
  self.textField.text = @"";
  
  [self cancelTypingTimer];
  
  // group chat message
  if ([self isInConversationRoom]) {
    if ([self.delegate respondsToSelector:@selector(chatViewController:didAskToSendMessage:)]) {
      [self.delegate chatViewController:self didAskToSendMessage:message];
    }
  }
  // private chat message
  else {
    if ([self.delegate
         respondsToSelector:@selector(chatViewController:didAskToSendMessage:toUser:)]) {
      [self.delegate chatViewController:self
                    didAskToSendMessage:message
                                 toUser:self.currentRecipient];
    }
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)typingDidPause {
  TBLOG(@"-- timer fired");
  [self cancelTypingTimer];
  [self didPauseComposing];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark TBBuddiesViewControllerDelegate

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)buddiesViewControllerHasFinished:(TBBuddiesViewController *)controller {
  [self dismissViewControllerAnimated:YES completion:NULL];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)buddiesViewController:(TBBuddiesViewController *)controller
            didSelectRoomName:(NSString *)roomName {
  self.title = roomName;
  self.currentRoomName = roomName;
  self.currentRecipient = nil;
  [self dismissViewControllerAnimated:YES completion:^{
    [self.tableView reloadData];
  }];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)buddiesViewController:(TBBuddiesViewController *)controller
               didSelectBuddy:(TBBuddy *)buddy {
  self.title = buddy.nickname;
  self.currentRoomName = buddy.fullname;
  self.currentRecipient = buddy;
  [self dismissViewControllerAnimated:YES completion:^{
    [self.tableView reloadData];
  }];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)buddiesViewController:(TBBuddiesViewController *)controller
   didAskFingerprintsForBuddy:(TBBuddy *)buddy {
  if ([self.delegate
       respondsToSelector:@selector(chatViewController:didAskFingerprintsForBuddy:)]) {
    [self.delegate chatViewController:self didAskFingerprintsForBuddy:buddy];
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark TBMeViewControllerDelegate

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)meViewControllerHasFinished:(TBMeViewController *)controller {
  [self dismissViewControllerAnimated:YES completion:NULL];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)meViewControllerDidAskToLogout:(TBMeViewController *)controller {
  if ([self.delegate respondsToSelector:@selector(chatViewControllerDidAskToLogout:)]) {
    [self dismissViewControllerAnimated:NO completion:^{
      [self.delegate chatViewControllerDidAskToLogout:self];
    }];
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UITextFieldDelegate

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)textField:(UITextField *)textField
shouldChangeCharactersInRange:(NSRange)range
replacementString:(NSString *)string {
  NSUInteger oldLength = textField.text.length;
  NSUInteger newLength = textField.text.length + string.length - range.length;
  
  // if there's a string in the input field
  if (newLength > 0) {
    // if there wasn't a string in the input field before or typing had paused
    if (oldLength==0  || !self.isTyping) {
      TBLOG(@"-- composing");
      [self didStartComposing];
    }
    
    // start/restart timer
    [self setupTypingTimer];
  }
  else {
    // all the chars in the input field have been deleted
    TBLOG(@"-- active");
    [self cancelTypingTimer];
    [self didEndComposing];
  }
  
  return YES;
}


@end
