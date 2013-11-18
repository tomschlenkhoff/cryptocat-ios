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
#import "TBMessage.h"
#import "TBBuddy.h"
#import "TBChateStateNotification.h"
#import "TBMessageCell.h"
#import "TBChatToolbarView.h"
#import "UIColor+Cryptocat.h"

#define kPausedMessageTimer   5.0
#define kTableViewPaddingTop  17.0

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TBChatViewController () <
  UITableViewDataSource,
  UITableViewDelegate,
  TBBuddiesViewControllerDelegate,
  TBMeViewControllerDelegate,
  UITextViewDelegate
>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet TBChatToolbarView *toolbarView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *toolbarViewBottomConstraint;
@property (nonatomic, strong) NSMutableDictionary *messagesForConversation;
@property (nonatomic, strong) NSString *currentRoomName;
@property (nonatomic, strong) TBBuddy *currentRecipient;
@property (strong, readwrite) NSTimer *composingTimer;
@property (nonatomic, assign, getter=isTyping) BOOL typing;
@property (nonatomic, assign) NSUInteger nbUnreadMessagesInRoom;
@property (nonatomic, strong) NSMutableDictionary *nbUnreadMessagesForBuddy;
@property (nonatomic, strong) NSString *defaultNavLeftItemTitle;
@property (nonatomic, readonly) NSMutableArray *messages;

- (void)startObservingKeyboard;
- (void)stopObservingKeyboard;
- (IBAction)sendMessage:(id)sender;
- (BOOL)isInConversationRoom;
- (void)setupTypingTimer;
- (void)cancelTypingTimer;
- (void)didStartComposing;
- (void)didPauseComposing;
- (void)didEndComposing;
- (void)updateUnreadMessagesCounter;
- (void)scrollToLatestMessage;
- (void)addMessage:(id)message forKey:(NSString *)key;

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
- (void)dealloc {
  NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
  [defaultCenter removeObserver:self name:TBDidReceiveGroupChatMessageNotification object:nil];
  [defaultCenter removeObserver:self name:TBDidReceivePrivateChatMessageNotification object:nil];
  [defaultCenter removeObserver:self name:TBDidReceiveGroupChatStateNotification object:nil];
  [defaultCenter removeObserver:self name:TBDidReceivePrivateChatStateNotification object:nil];
  [defaultCenter removeObserver:self name:TBBuddyDidSignInNotification object:nil];
  [defaultCenter removeObserver:self name:TBBuddyDidSignOutNotification object:nil];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
	 
  self.defaultNavLeftItemTitle = NSLocalizedString(@"Buddies",
                                                   @"Buddies Button Title on Chat Screen");
  self.navigationItem.leftBarButtonItem.title = self.defaultNavLeftItemTitle;
  self.navigationItem.rightBarButtonItem.title = NSLocalizedString(@"Me",
                                                                @"Me Button Title on Chat Screen");
  
  
  self.typing = NO;
  self.messagesForConversation = [NSMutableDictionary dictionary];
  self.nbUnreadMessagesInRoom = 0;
  self.nbUnreadMessagesForBuddy = [NSMutableDictionary dictionary];
  
  self.view.backgroundColor = [UIColor tb_backgroundColor];
  self.tableView.backgroundColor = self.view.backgroundColor;
  self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  self.tableView.contentInset = UIEdgeInsetsMake(kTableViewPaddingTop, 0.0, 0.0, 0.0);

  self.toolbarView.textView.delegate = self;
  [self.toolbarView.sendButton addTarget:self
                                  action:@selector(sendMessage:)
                        forControlEvents:UIControlEventTouchUpInside];

  NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
  [defaultCenter addObserver:self
                    selector:@selector(didReceiveGroupMessage:)
                        name:TBDidReceiveGroupChatMessageNotification
                      object:nil];
  [defaultCenter addObserver:self
                    selector:@selector(didReceivePrivateMessage:)
                        name:TBDidReceivePrivateChatMessageNotification
                      object:nil];
  [defaultCenter addObserver:self
                    selector:@selector(didReceiveGroupStateNotification:)
                        name:TBDidReceiveGroupChatStateNotification
                      object:nil];
  [defaultCenter addObserver:self
                    selector:@selector(didReceivePrivateStateNotification:)
                        name:TBDidReceivePrivateChatStateNotification
                      object:nil];
  [defaultCenter addObserver:self
                    selector:@selector(buddyDidChangeState:)
                        name:TBBuddyDidSignInNotification
                      object:nil];
  [defaultCenter addObserver:self
                    selector:@selector(buddyDidChangeState:)
                        name:TBBuddyDidSignOutNotification
                      object:nil];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [self setNeedsStatusBarAppearanceUpdate];

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
    bvc.nbUnreadMessagesInRoom = self.nbUnreadMessagesInRoom;
    bvc.nbUnreadMessagesForBuddy = self.nbUnreadMessagesForBuddy;
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
  static NSString *cellID = @"MessageCellID";
  TBMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
  if (cell == nil) {
    [tableView registerClass:[TBMessageCell class] forCellReuseIdentifier:cellID];
    cell = [[TBMessageCell alloc] initWithStyle:UITableViewCellStyleDefault
                                reuseIdentifier:cellID];
  }

  NSMutableArray *messages = self.messages;
  id message = [messages objectAtIndex:indexPath.row];
  
  NSString *senderName = nil;
  BOOL meSpeaking = NO;
  NSString *text = nil;

  if ([message isKindOfClass:[TBMessage class]]) {
    senderName = ((TBMessage *)message).sender.nickname;
    meSpeaking = [((TBMessage *)message).sender isEqual:self.me];
    text = ((TBMessage *)message).text;
  }
  else if ([message isKindOfClass:[TBChateStateNotification class]]) {
    senderName = ((TBChateStateNotification *)message).sender.nickname;
    meSpeaking = NO;
    text = @"is composing ...";
  }
  
  cell.senderName = senderName;
  cell.meSpeaking = meSpeaking;
  cell.message = text;
  cell.backgroundColor = self.tableView.backgroundColor;

  return cell;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  NSMutableArray *messages = self.messages;
  return [messages count];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  id message = [self.messages objectAtIndex:indexPath.row];
  NSString *text = nil;
  
  if ([message isKindOfClass:[TBMessage class]]) {
    text = ((TBMessage *)message).text;
  }
  else if ([message isKindOfClass:[TBChateStateNotification class]]) {
    text = @"is composing ...";
  }
  
  return [TBMessageCell heightForCellWithText:text];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UITableViewDelegate

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSIndexPath *)tableView:(UITableView *)tableView
  willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  return nil;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
  return NO;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Observers

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didReceiveGroupMessage:(NSNotification *)notification {
  TBMessage *message = notification.object;
  NSString *roomName = message.sender.roomName;
  
  [self addMessage:message forKey:roomName];
  
  if ([self isInConversationRoom]) {
    [self.tableView reloadData];
    [self scrollToLatestMessage];
  }
  else {
    self.nbUnreadMessagesInRoom+=1;
    [self updateUnreadMessagesCounter];
  }
  TBLOG(@"-- received message in %@ from %@: %@", roomName, message.sender.fullname, message.text);
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didReceivePrivateMessage:(NSNotification *)notification {
  TBMessage *message = notification.object;
  
  if ([message.text isEqualToString:@""]) return ;
  
  [self addMessage:message forKey:message.sender.fullname];
  
  if (![self isInConversationRoom] && [self.currentRecipient isEqual:message.sender]) {
    [self.tableView reloadData];
    [self scrollToLatestMessage];
  }
  else {
    NSString *buddyName = message.sender.fullname;
    NSInteger nbUnreadMessages = [[self.nbUnreadMessagesForBuddy objectForKey:buddyName]
                                  integerValue];
    nbUnreadMessages+=1;
    [self.nbUnreadMessagesForBuddy setObject:[NSNumber numberWithInteger:nbUnreadMessages]
                                      forKey:buddyName];
    [self updateUnreadMessagesCounter];
  }
  
  TBLOG(@"-- received private message from %@: %@", message.sender.fullname, message.text);
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didReceiveGroupStateNotification:(NSNotification *)notification {
  TBChateStateNotification *csn = notification.object;
  NSString *roomName = csn.sender.roomName;
  
  if ([csn isComposingNotification]) {
    [self addMessage:csn forKey:roomName];
  }
  else {
    [self removeChatStateNotification:csn forKey:roomName];
  }
  
  [self.tableView reloadData];
  [self scrollToLatestMessage];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didReceivePrivateStateNotification:(NSNotification *)notification {
  TBChateStateNotification *csn = notification.object;
  
  if ([csn isComposingNotification]) {
    [self addMessage:csn forKey:csn.sender.fullname];
  }
  else {
    [self removeChatStateNotification:csn forKey:csn.sender.fullname];
  }
  
  [self.tableView reloadData];
  [self scrollToLatestMessage];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)buddyDidChangeState:(NSNotification *)notification {
  TBBuddy *buddy = notification.object;
  
  if ([self.currentRecipient isEqual:buddy]) {
    BOOL isSignIn = [notification.name isEqualToString:TBBuddyDidSignInNotification];
    self.toolbarView.textView.backgroundColor = isSignIn ?
                                                  [UIColor whiteColor] : [UIColor redColor];
    self.toolbarView.textView.editable = isSignIn;
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)keyboardWillShow:(NSNotification *)notification {
  NSDictionary* info = [notification userInfo];
  CGSize keyboardSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

  // get the keyboard height depending on the device orientation
  UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
  BOOL isPortrait = orientation==UIInterfaceOrientationPortrait;
  CGFloat keyboardHeight = isPortrait ? keyboardSize.height : keyboardSize.width;
  
  // get the animation info
  double keyboardTransitionDuration;
  [[notification.userInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey]
   getValue:&keyboardTransitionDuration];
  UIViewAnimationCurve keyboardTransitionAnimationCurve;
  [[notification.userInfo valueForKey:UIKeyboardAnimationCurveUserInfoKey]
   getValue:&keyboardTransitionAnimationCurve];
  
  // update the toolbarView constraints
  self.toolbarViewBottomConstraint.constant = keyboardHeight;
  
  // start animation
  [UIView beginAnimations:nil context:NULL];
  [UIView setAnimationDuration:keyboardTransitionDuration];
  [UIView setAnimationCurve:keyboardTransitionAnimationCurve];
  [UIView setAnimationBeginsFromCurrentState:YES];
  
  [self.view layoutIfNeeded];
  
  [UIView commitAnimations];
  // end animation

  [self scrollToLatestMessage];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)keyboardWillBeHidden:(NSNotification *)notification {
  // update the toolbarView constraints
  self.toolbarViewBottomConstraint.constant = 0; //keyboardHeight;
  
  [self.view layoutIfNeeded];
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
- (void)updateUnreadMessagesCounter {
  NSInteger totalUnreadMSGCount = self.nbUnreadMessagesInRoom;
  TBLOG(@"-- self.nbUnreadMessagesInRoom : %d", self.nbUnreadMessagesInRoom);
  for (NSString *buddyName in self.nbUnreadMessagesForBuddy) {
    NSNumber *nbUnreadMessages = [self.nbUnreadMessagesForBuddy objectForKey:buddyName];
    totalUnreadMSGCount+=[nbUnreadMessages integerValue];
    TBLOG(@"-- nb unread msgs for %@ : %d", buddyName, [nbUnreadMessages integerValue]);
  }
  
  if (totalUnreadMSGCount==0) {
    self.navigationItem.leftBarButtonItem.title = self.defaultNavLeftItemTitle;
  }
  else {
    self.navigationItem.leftBarButtonItem.title = [NSString stringWithFormat:@"%@ (%d)",
                                                   self.defaultNavLeftItemTitle,
                                                   totalUnreadMSGCount];
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)scrollToLatestMessage {
  NSUInteger nbMessages = [self.messages count];
  if (nbMessages==0) return;
  
  NSIndexPath *indexPath = [NSIndexPath indexPathForRow:nbMessages-1 inSection:0];
  [self.tableView scrollToRowAtIndexPath:indexPath
                        atScrollPosition:UITableViewScrollPositionBottom
                                animated:YES];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSMutableArray *)messages {
  return [self.messagesForConversation objectForKey:self.currentRoomName];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)addMessage:(id)message forKey:(NSString *)key {
  if ([self.messagesForConversation objectForKey:key]==nil) {
    [self.messagesForConversation setObject:[NSMutableArray array] forKey:key];
  }
  
  [[self.messagesForConversation objectForKey:key] addObject:message];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)removeChatStateNotification:(TBChateStateNotification *)chatStateNotification
                             forKey:(NSString *)key {
  NSMutableArray *messages = [self.messagesForConversation objectForKey:key];
  id messageToRemove = nil;
  
  for (id message in messages) {
    if ([message isKindOfClass:[TBChateStateNotification class]] &&
        [((TBChateStateNotification *)message).sender isEqual:chatStateNotification.sender]) {
      messageToRemove = message;
      break;
    }
  }
  
  [messages removeObject:messageToRemove];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Actions

////////////////////////////////////////////////////////////////////////////////////////////////////
- (IBAction)sendMessage:(id)sender {
  TBMessage *message = [[TBMessage alloc] init];
  message.text = self.toolbarView.textView.text;
  message.sender = self.me;
  
  if (self.messages==nil) {
    [self.messagesForConversation setObject:[NSMutableArray array] forKey:self.currentRoomName];
  }

  [self.messages addObject:message];
  [self.tableView reloadData];
  [self scrollToLatestMessage];
  self.toolbarView.textView.text = @"";
  
  [self cancelTypingTimer];
  
  // group chat message
  if ([self isInConversationRoom]) {
    if ([self.delegate respondsToSelector:@selector(chatViewController:didAskToSendMessage:)]) {
      [self.delegate chatViewController:self didAskToSendMessage:message.text];
    }
  }
  // private chat message
  else {
    if ([self.delegate
         respondsToSelector:@selector(chatViewController:didAskToSendMessage:toUser:)]) {
      [self.delegate chatViewController:self
                    didAskToSendMessage:message.text
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
  self.nbUnreadMessagesInRoom = 0;
  [self dismissViewControllerAnimated:YES completion:^{
    [self.tableView reloadData];
    [self updateUnreadMessagesCounter];
  }];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)buddiesViewController:(TBBuddiesViewController *)controller
               didSelectBuddy:(TBBuddy *)buddy {
  self.title = buddy.nickname;
  self.currentRoomName = buddy.fullname;
  self.currentRecipient = buddy;
  [self.nbUnreadMessagesForBuddy setObject:[NSNumber numberWithInt:0] forKey:buddy.fullname];
  [self dismissViewControllerAnimated:YES completion:^{
    [self.tableView reloadData];
    [self updateUnreadMessagesCounter];
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
  self.messagesForConversation = [NSMutableDictionary dictionary];
  [self.tableView reloadData];
  if ([self.delegate respondsToSelector:@selector(chatViewControllerDidAskToLogout:)]) {
    [self dismissViewControllerAnimated:NO completion:^{
      [self.delegate chatViewControllerDidAskToLogout:self];
    }];
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UITextViewDelegate

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)textView:(UITextView *)textView
shouldChangeTextInRange:(NSRange)range
 replacementText:(NSString *)text {
  NSUInteger oldLength = textView.text.length;
  NSUInteger newLength = textView.text.length + text.length - range.length;
  
  self.toolbarView.sendButton.enabled = newLength > 0;
  
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
