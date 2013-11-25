//
//  TBServerViewController.m
//  Cryptocat
//
//  Created by Thomas Balthazar on 25/11/13.
//  Copyright (c) 2013 Thomas Balthazar. All rights reserved.
//

#import "TBServerViewController.h"
#import "TBTextFieldCell.h"
#import "TBServer.h"
#import "NSString+Cryptocat.h"

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TBServerViewController ()

@property (nonatomic, readonly) BOOL isAddVC;
@property (weak, nonatomic) IBOutlet TBTextFieldCell *nameCell;
@property (weak, nonatomic) IBOutlet TBTextFieldCell *domainCell;
@property (weak, nonatomic) IBOutlet TBTextFieldCell *conferenceServerCell;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TBServerViewController

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
  
  // -- save button
  UIBarButtonItem *saveButton = [[UIBarButtonItem alloc]
                                 initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                 target:self
                                 action:@selector(save)];
  self.navigationItem.rightBarButtonItem = saveButton;
  
  // -- placeholder text
  self.nameCell.textField.placeholder = NSLocalizedString(@"Name", @"Server Name Placeholder");
  self.domainCell.textField.placeholder = NSLocalizedString(@"Domain",
                                                            @"Server Domain Placeholder");
  self.conferenceServerCell.textField.placeholder = NSLocalizedString(@"XMPP Conference Server",
                                                            @"Server XMPP Conference Placeholder");
  
  // -- textfield config
  self.nameCell.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
  self.nameCell.textField.autocorrectionType = UITextAutocorrectionTypeNo;
  self.domainCell.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
  self.domainCell.textField.autocorrectionType = UITextAutocorrectionTypeNo;
  self.conferenceServerCell.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
  self.conferenceServerCell.textField.autocorrectionType = UITextAutocorrectionTypeNo;
  
  NSString *screenTitle;
  if (self.isAddVC) {
    screenTitle = NSLocalizedString(@"New Server", @"New Server Screen Title");
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc]
                                     initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                     target:self
                                     action:@selector(cancel)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    [self.nameCell.textField becomeFirstResponder];
  }
  else {
    screenTitle = self.server.name;
    if (self.server.isReadonly) {
      self.nameCell.enabled = NO;
      self.domainCell.enabled = NO;
      self.conferenceServerCell.enabled = NO;
    }
    
    self.nameCell.textField.text = self.server.name;
    self.domainCell.textField.text = self.server.domain;
    self.conferenceServerCell.textField.text = self.server.conferenceServer;
  }
  
  self.title = screenTitle;
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
#pragma mark Private

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)isAddVC {
  return self.server==nil;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Actions

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)save {
  if (self.isAddVC) {
    if ([self.delegate respondsToSelector:@selector(serverViewController:didCreateServer:)]) {
      TBServer *server = [[TBServer alloc] init];
      server.name = [self.nameCell.textField.text tb_trim];
      server.domain = [self.domainCell.textField.text tb_trim];
      server.conferenceServer = [self.conferenceServerCell.textField.text tb_trim];
      [self.delegate serverViewController:self didCreateServer:server];
    }
  }
  else {
    if ([self.delegate
         respondsToSelector:@selector(serverViewController:didUpdateServer:atIndexPath:)]) {
      self.server.name = [self.nameCell.textField.text tb_trim];
      self.server.domain = [self.domainCell.textField.text tb_trim];
      self.server.conferenceServer = [self.conferenceServerCell.textField.text tb_trim];
      [self.delegate serverViewController:self
                          didUpdateServer:self.server
                                  atIndexPath:self.serverIndexPath];
    }
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)cancel {
  if ([self.delegate respondsToSelector:@selector(serverViewControllerDidCancel:)]) {
    [self.delegate serverViewControllerDidCancel:self];
  }
}

@end
