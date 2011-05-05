
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

@class EditTokenViewController;

#import "Token.h"
#import "TouchableLabel.h"

@interface MainViewController : UIViewController <UITableViewDataSource, UITableViewDelegate> {

    // Token state
    NSString *tokenFile;
    NSMutableArray *tokens;

    // Subviews
    UITableView *tokenTable;
    UIButton *generateButton;
    TouchableLabel *passwordLabel;
    UIProgressView *progressBar;

    // Bar buttons
    UIBarButtonItem *addButton;
    UIBarButtonItem *editButton;
    UIBarButtonItem *doneButton;

    // Timer
    NSTimer *timer;
    u_long lastSequence;
}

// Properties
@property (nonatomic, retain, readonly) NSString *tokenFile;
@property (nonatomic, retain, readonly) NSMutableArray *tokens;
@property (nonatomic, retain) IBOutlet UITableView *tokenTable;
@property (nonatomic, retain) IBOutlet UIButton *generateButton;
@property (nonatomic, retain) IBOutlet UILabel *passwordLabel;
@property (nonatomic, retain) IBOutlet UIProgressView *progressBar;
@property (nonatomic, retain) UIBarButtonItem *addButton;
@property (nonatomic, retain) UIBarButtonItem *editButton;
@property (nonatomic, retain) UIBarButtonItem *doneButton;
@property (nonatomic, retain) NSTimer *timer;
@property (nonatomic, assign) u_long lastSequence;

// Methods
+ (void)prettyUpButton:(UIButton *)button;
- (void)saveTokens;
- (Token *)currentToken;
- (void)startUpdates;
- (void)stopUpdates;
- (void)timerUpdate:(NSTimer *)timer;
- (void)recalculatePassword;
- (void)updatePasswordDisplay;
- (void)clearPasswordDisplay;
- (void)finishedEditing:(Token *)token tokenIndex:(int)tokenIndex commit:(BOOL)commit reset:(BOOL)reset;

// Actions
- (IBAction)generatePassword:(id)sender;
- (IBAction)addToken:(id)sender;
- (IBAction)editTokens:(id)sender;
- (IBAction)doneEditTokens:(id)sender;
- (IBAction)showInfo:(id)sender;

@end
