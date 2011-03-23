
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

#import "MainViewController.h"
#import "EditTokenViewController.h"
#import "InfoViewController.h"
#import "Token.h"

#define TOKENS_FILE                 @"tokens.plist" // file for stored tokens
#define MAX_EVENT_PASSWORD_DISPLAY  30.0            // display event-based passwords for this long
#define LABEL_FADE_TIME             0.666           // fade-in/fade-out time
#define TIMER_INTERVAL              0.025           // animation timer interval

@implementation MainViewController

// Properties
@synthesize tokenFile;
@synthesize tokens;
@synthesize tokenTable;
@synthesize generateButton;
@synthesize passwordLabel;
@synthesize progressBar;
@synthesize addButton;
@synthesize editButton;
@synthesize doneButton;
@synthesize timer;
@synthesize lastElapsed;

#pragma mark UIViewController methods

+ (void)prettyUpButton:(UIButton *)button {
    UIImage *normal = [UIImage imageNamed:@"whiteButton.png"];
    UIImage *stretchNormal = [normal stretchableImageWithLeftCapWidth:12 topCapHeight:0];
    [button setBackgroundImage:stretchNormal forState:UIControlStateNormal];
    UIImage *pressed = [UIImage imageNamed:@"blueButton.png"];
    UIImage *stretchPressed = [pressed stretchableImageWithLeftCapWidth:12 topCapHeight:0];
    [button setBackgroundImage:stretchPressed forState:UIControlStateHighlighted];    
}

- (void)ensureTokenFileIsEncrypted {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    id attr = [[fileManager attributesOfItemAtPath:self.tokenFile error:nil] valueForKey:NSFileProtectionKey];
    if (![NSFileProtectionComplete isEqual:attr]) {
        [fileManager setAttributes:[NSDictionary dictionaryWithObject:NSFileProtectionComplete forKey:NSFileProtectionKey]
                      ofItemAtPath:self.tokenFile
                             error:nil];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Initialize
    if (self.tokens == nil) {
        
        // Find tokens file
        NSString *dir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        tokenFile = [[dir stringByAppendingPathComponent:TOKENS_FILE] retain];

        // Initialize array
        tokens = [[NSMutableArray arrayWithCapacity:10] retain];

        // Read tokens from the data file (if it exists)
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:self.tokenFile]) {
            
            // Read the file
            NSArray *fileContents = [NSArray arrayWithContentsOfFile:self.tokenFile];
            for (NSDictionary *dict in fileContents)
                [self.tokens addObject:[Token createFromDictionary:dict]];
            
            // Mark it for encryption
            [self ensureTokenFileIsEncrypted];
        }
        
        // Auto-select the first token
        if ([self.tokens count] > 0) {
            [self.tokenTable selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:FALSE scrollPosition:UITableViewScrollPositionTop];
            [self recalculatePassword];
            [self updatePasswordDisplay];
            [self startUpdates];
        }
    }
    
    // Fixup button
    [MainViewController prettyUpButton:self.generateButton];
    
	// Create "+" button
    self.addButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                    target:self
                                                                    action:@selector(addToken:)] autorelease];
	self.navigationItem.rightBarButtonItem = self.addButton;
    
    // Create "Edit" button
    self.editButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                                     target:self
                                                                     action:@selector(editTokens:)] autorelease];
	self.navigationItem.leftBarButtonItem = self.editButton;
    
    // Create "Done" button
    self.doneButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                     target:self
                                                                     action:@selector(doneEditTokens:)] autorelease];
    
    // Update display
    [self updatePasswordDisplay];    
}

- (void)viewWillAppear:(BOOL)animated {
    [self startUpdates];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self stopUpdates];
}

- (void)viewDidUnload {
    [self stopUpdates];
    self.tokenTable = nil;
    self.generateButton = nil;
    self.passwordLabel = nil;
    self.progressBar = nil;
    self.addButton = nil;
    self.editButton = nil;
    self.doneButton = nil;
    [super viewDidUnload];
}

- (void)dealloc {
    [self stopUpdates];
    [tokenFile release];
    [tokens release];
    [tokenTable release];
    [generateButton release];
    [passwordLabel release];
    [progressBar release];
    [addButton release];
    [editButton release];
    [doneButton release];
    [super dealloc];
}

#pragma mark Actions

// Invoked when the "Generate New Password" button is pressed
- (IBAction)generatePassword:(id)sender {
    Token *token = [self currentToken];
    if (token == nil) {
        [self clearPasswordDisplay];
        [self stopUpdates];
        return;
    }
    [token advanceCounter];
    token.lastEvent = [NSDate date];
    [self saveTokens];
    [self recalculatePassword];
    [self updatePasswordDisplay];
    [self startUpdates];
}

// Invoked when the info icon is pressed
- (IBAction)showInfo:(id)sender {
    InfoViewController *info = [[[InfoViewController alloc] initWithNibName:@"InfoView" bundle:nil] autorelease];
    info.mainViewController = self;
    info.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentModalViewController:info animated:YES];    
}

// Invoked when the "+" nav bar button is pressed
- (IBAction)addToken:(id)sender {
    [self doneEditTokens:sender];
    [self stopUpdates];
    EditTokenViewController *add = [[[EditTokenViewController alloc] initWithNibName:@"EditTokenView" bundle:nil] autorelease];
    add.mainViewController = self;
    add.token = [Token createEmpty];
    add.tokenIndex = -1;
    add.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self.navigationController pushViewController:add animated:YES];
    [add.name becomeFirstResponder];
}

// Invoked when the "Edit" nav bar button is pressed
- (IBAction)editTokens:(id)sender {
    [self stopUpdates];
    [self clearPasswordDisplay];
    [self.tokenTable setEditing:TRUE animated:TRUE];
    self.navigationItem.leftBarButtonItem = self.doneButton;
}

// Invoked when the "Done" nav bar button is pressed
- (IBAction)doneEditTokens:(id)sender {
    [self.tokenTable setEditing:FALSE animated:TRUE];
    self.navigationItem.leftBarButtonItem = self.editButton;
}

#pragma mark Helper methods

// Get the currently selected token, if any
- (Token *)currentToken {
    NSIndexPath *indexPath = [self.tokenTable indexPathForSelectedRow];
    if (indexPath == nil)
        return nil;
    NSUInteger row = [indexPath row];
    if (row == [self.tokens count])
        return nil;
    return [self.tokens objectAtIndex:row];
}

// Save tokens to the data file
- (void)saveTokens {
    [self.tokens count];
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (Token *token in self.tokens)
        [array addObject:[token toDictionary]];
    if (![array writeToFile:self.tokenFile atomically:YES]) {
        [[[[UIAlertView alloc] initWithTitle:@"Save Failed"
                                     message:[NSString stringWithFormat:@"Unable to write to %@", self.tokenFile]
                                    delegate:nil
                           cancelButtonTitle:@"Too Bad" otherButtonTitles:nil] autorelease] show];
    }
    [array release];
    [self ensureTokenFileIsEncrypted];
}

// Start update timer
- (void)startUpdates {
    [self stopUpdates];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:TIMER_INTERVAL target:self selector:@selector(timerUpdate:) userInfo:nil repeats:YES];
}

// Stop update timer
- (void)stopUpdates {
    if (self.timer != nil) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

// Invoked periodically by the update timer
- (void)timerUpdate:(NSTimer *)timer {
    [self updatePasswordDisplay];
}

// Update the view to reflect the current token and password
- (void)updatePasswordDisplay {
    Token *token = [self currentToken];
    if (token == nil) {
        [self clearPasswordDisplay];
        return;
    }
    NSDate *now = [NSDate date];
    BOOL showIt = NO;
    double period;
    double elapsed;
    if (token.timeBased) {
        showIt = YES;
        period = token.interval;
        u_long secs = (u_long)[now timeIntervalSince1970];
        double frac = [now timeIntervalSince1970] - secs;
        elapsed = (double)(secs % token.interval) + frac;
        if (elapsed < self.lastElapsed)
            [self recalculatePassword];
        self.lastElapsed = elapsed;
        self.generateButton.hidden = YES;
    } else if (token.lastEvent != nil) {
        elapsed = [now timeIntervalSinceDate:token.lastEvent];
        period = MAX_EVENT_PASSWORD_DISPLAY;
        showIt = elapsed <= period;
        self.generateButton.hidden = showIt;
    } else {
        showIt = NO;
        self.generateButton.hidden = NO;
    }

    // Display password and progress bar as needed
    self.progressBar.hidden = !showIt;
    self.passwordLabel.hidden = !showIt;
    if (showIt) {
        self.progressBar.progress = elapsed / period;
        if (elapsed > period - LABEL_FADE_TIME)
            self.passwordLabel.alpha = (period - elapsed) / LABEL_FADE_TIME;
        else if (elapsed < LABEL_FADE_TIME)
            self.passwordLabel.alpha = elapsed / LABEL_FADE_TIME;
        else
            self.passwordLabel.alpha = 1.0;
    } else
        [self stopUpdates];
}

// (Re)calculate the current password
- (void)recalculatePassword {
    Token *token = [self currentToken];
    if (token == nil)
        return;
    self.passwordLabel.text = [token generatePassword];
}

// Invoked when editing a new or existing token has finished
- (void)finishedEditing:(Token *)token tokenIndex:(int)tokenIndex commit:(BOOL)commit reset:(BOOL)reset {
    if (commit) {
        BOOL added = tokenIndex == -1;
        if (added)
            tokenIndex = [self.tokens count];
        else
            [self.tokens removeObjectAtIndex:tokenIndex];
        [self.tokens insertObject:token atIndex:tokenIndex];
        [self saveTokens];
        NSArray *indexPaths = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:tokenIndex inSection:0]];
        if (added)
            [self.tokenTable insertRowsAtIndexPaths:indexPaths withRowAnimation:NO];
        else
            [self.tokenTable reloadRowsAtIndexPaths:indexPaths withRowAnimation:NO];
        if (reset) {
            [self clearPasswordDisplay];
            [self stopUpdates];
        }
    }
    [self updatePasswordDisplay];
    [self.navigationController popViewControllerAnimated:YES];
    if ([self currentToken] != nil)
        [self startUpdates];
}

// Invoked when a row is moved
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    [self saveTokens];
    NSUInteger srcIndex = [fromIndexPath row];
    NSUInteger dstIndex = [toIndexPath row];
    Token *token = [[[self.tokens objectAtIndex:srcIndex] retain] autorelease];
    [self.tokens removeObjectAtIndex:srcIndex];
    [self.tokens insertObject:token atIndex:dstIndex];
    [self saveTokens];
}
     
#pragma mark UITableViewDataSource methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.tokens count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *ident = @"TokenCell";
    
    // Get token
    NSUInteger row = [indexPath row];
    Token *token = [self.tokens objectAtIndex:row];

    // Create cell
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ident];
    if (cell == nil)
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ident] autorelease];
    cell.textLabel.text = token.name;
    cell.accessoryType = !token.lockdown ? UITableViewCellAccessoryDetailDisclosureButton : UITableViewCellAccessoryNone;
    return cell;
}

// Invoked when a token is deleted
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
    forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSArray *indexPaths = [NSArray arrayWithObject:indexPath];
        [self.tokens removeObjectAtIndex:[indexPath row]];
        [self.tokenTable deleteRowsAtIndexPaths:indexPaths withRowAnimation:TRUE];
        [self saveTokens];
    }
}

// This is here to disable swipe-to-delete
- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.tokenTable.editing ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;
}

- (void)clearPasswordDisplay {
    self.passwordLabel.hidden = YES;
    self.progressBar.hidden = YES;
    self.generateButton.hidden = YES;
}

#pragma mark UITableViewDelegate methods

// Invoked when a token is selected
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self recalculatePassword];
    [self updatePasswordDisplay];
    [self startUpdates];
}

// Invoked when a token's accessory button is selected
- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    [self stopUpdates];
    NSUInteger row = [indexPath row];
    EditTokenViewController *edit = [[[EditTokenViewController alloc] initWithNibName:@"EditTokenView" bundle:nil] autorelease];
    edit.mainViewController = self;
    edit.token = [[[self.tokens objectAtIndex:row] copy] autorelease];
    edit.tokenIndex = row;
    [self.navigationController pushViewController:edit animated:YES];
}

@end
