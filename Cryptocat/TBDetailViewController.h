//
//  TBDetailViewController.h
//  Cryptocat
//
//  Created by Thomas Balthazar on 23/09/13.
//  Copyright (c) 2013 Thomas Balthazar. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TBDetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@end
