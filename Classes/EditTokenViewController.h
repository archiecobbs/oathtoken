
/*
 * OATH Token - HOTP/OATH one-time password token for iPhone
 *
 * Copyright 2010 Archie L. Cobbs <archie@dellroad.org>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * $Id$
 */

#import <UIKit/UIKit.h>

@class MainViewController;

#import "Token.h"
#import "MainViewController.h"

@interface EditTokenViewController : UIViewController <UITextFieldDelegate> {
    Token *token;
    Token *originalToken;
    int tokenIndex;
    MainViewController *mainViewController;
    UINavigationItem *navItem;
    UITextField *name;
    UITextField *key;
    UIButton *generateKeyButton;
    UISegmentedControl *eventTimeSwitch;
    UILabel *counterLabel;
    UITextField *counter;
    UILabel *intervalLabel1;
    UILabel *intervalLabel2;
    UITextField *interval;
    UITextField *numDigits;
    UISwitch *displayHex;
    UISwitch *lockDown;
    BOOL needShift;
    BOOL shifted;
}

@property (nonatomic, retain) Token *token;
@property (nonatomic, retain) Token *originalToken;
@property (nonatomic) int tokenIndex;
@property (nonatomic, retain) MainViewController *mainViewController;
@property (nonatomic, retain) IBOutlet UINavigationItem *navItem;
@property (nonatomic, retain) IBOutlet UITextField *name;
@property (nonatomic, retain) IBOutlet UITextField *key;
@property (nonatomic, retain) IBOutlet UIButton *generateKeyButton;
@property (nonatomic, retain) IBOutlet UISegmentedControl *eventTimeSwitch;
@property (nonatomic, retain) IBOutlet UILabel *counterLabel;
@property (nonatomic, retain) IBOutlet UITextField *counter;
@property (nonatomic, retain) IBOutlet UILabel *intervalLabel1;
@property (nonatomic, retain) IBOutlet UILabel *intervalLabel2;
@property (nonatomic, retain) IBOutlet UITextField *interval;
@property (nonatomic, retain) IBOutlet UITextField *numDigits;
@property (nonatomic, retain) IBOutlet UISwitch *displayHex;
@property (nonatomic, retain) IBOutlet UISwitch *lockDown;
@property (nonatomic) BOOL needShift;
@property (nonatomic) BOOL shifted;

- (IBAction)generateRandomKey;
- (IBAction)stuffChanged:(id)sender;
- (IBAction)cancelEdit:(id)sender;
- (IBAction)commitEdit:(id)sender;
- (IBAction)typeChanged:(id)sender;
- (void)shiftViewForKeyboard:(BOOL)up;
- (void)updateHiddenStuff;
- (void)animateHiddenStuff;
- (void)updateDisplayFromToken;
- (void)alertError:(NSString *)title withMessage:(NSString *)msg;

@end
