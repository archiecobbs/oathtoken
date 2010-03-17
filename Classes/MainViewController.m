
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
#import "Token.h"

#define MAX_EVENT_PASSWORD_DISPLAY  60.0        // display event-based passwords for 60 seconds
#define LABEL_FADE_FRACTION         0.025       // fade-in/fade-out fraction

@implementation MainViewController

// Properties
@synthesize tokenFile;
@synthesize tokens;
@synthesize tokenTable;
@synthesize generateButton;
@synthesize passwordLabel;
@synthesize progressBar;
@synthesize timer;
@synthesize lastProgress;

#pragma mark UIViewController methods

+ (void)prettyUpButton:(UIButton *)button {
    UIImage *normal = [UIImage imageNamed:@"whiteButton.png"];
    UIImage *stretchNormal = [normal stretchableImageWithLeftCapWidth:12 topCapHeight:0];
    [button setBackgroundImage:stretchNormal forState:UIControlStateNormal];
    UIImage *pressed = [UIImage imageNamed:@"blueButton.png"];
    UIImage *stretchPressed = [pressed stretchableImageWithLeftCapWidth:12 topCapHeight:0];
    [button setBackgroundImage:stretchPressed forState:UIControlStateHighlighted];    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Tokens";
    [MainViewController prettyUpButton:self.generateButton];
	UIBarButtonItem *addButton = [[[UIBarButtonItem alloc] initWithTitle:@"New"
																   style:UIBarButtonItemStyleBordered
																  target:self
																  action:@selector(addToken:)] autorelease];
	self.navigationItem.rightBarButtonItem = addButton;
    NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *dir = [dirs objectAtIndex:0];
    self.tokenFile = [[[NSString alloc] initWithString:[dir stringByAppendingPathComponent:@"tokens.plist"]] autorelease];
    self.tokens = [NSArray array];
    [self loadTokens];
    [self updatePasswordDisplay];
}

- (void)viewDidUnload {
    [self stopUpdates];
    self.tokenFile = nil;
    self.tokens = nil;
    self.tokenTable = nil;
    self.generateButton = nil;
    self.passwordLabel = nil;
    self.progressBar = nil;
}

- (void)dealloc {
    [self stopUpdates];
    [tokenFile release];
    [tokens release];
    [tokenTable release];
    [generateButton release];
    [passwordLabel release];
    [progressBar release];
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

// Reload tokens from the data file
- (void)loadTokens {
    
    // Find data file
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *file = nil;
    if ([fileManager fileExistsAtPath:self.tokenFile] == YES)
        file = self.tokenFile;

//    if (file == nil)
//        file = [[NSBundle mainBundle] pathForResource:@"sample-tokens" ofType:@"plist"];
    
    // Any file to read?
    if (file == nil) {
        self.tokens = [NSMutableArray array];
        return;
    }
    
    // Read file
    NSArray *fileContents = [NSArray arrayWithContentsOfFile:file];
    self.tokens = [NSMutableArray arrayWithCapacity:[fileContents count]];
    for (NSDictionary *dict in fileContents)
        [tokens addObject:[Token createFromDictionary:dict]];
}

// Save tokens to the data file
- (void)saveTokens {
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
}

// Start update timer
- (void)startUpdates {
    [self stopUpdates];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerUpdate:) userInfo:nil repeats:YES];
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
    self.generateButton.hidden = token.timeBased;
    NSDate *now = [NSDate date];
    BOOL showIt = NO;
    double progress;
    if (token.timeBased) {
        showIt = YES;
        u_long secs = (u_long)[now timeIntervalSince1970];
        double frac = [now timeIntervalSince1970] - secs;
        double period = (double)(secs % token.interval) + frac;
        progress = period / token.interval;
        if (progress < self.lastProgress)
            [self recalculatePassword];
        self.lastProgress = progress;
    } else {
        NSTimeInterval elapsed = [now timeIntervalSinceDate:token.lastEvent];
        if ((showIt = (elapsed <= MAX_EVENT_PASSWORD_DISPLAY)))
            progress = elapsed / MAX_EVENT_PASSWORD_DISPLAY;
        else
            [self stopUpdates];
    }

    // Display password and progress bar as needed
    self.progressBar.hidden = !showIt;
    self.passwordLabel.hidden = !showIt;
    if (showIt) {
        self.progressBar.progress = progress;
        if (progress < LABEL_FADE_FRACTION)
            self.passwordLabel.alpha = progress / LABEL_FADE_FRACTION;
        else if (progress > 1.0 - LABEL_FADE_FRACTION)
            self.passwordLabel.alpha = (1.0 - progress) / LABEL_FADE_FRACTION;
        else
            self.passwordLabel.alpha = 1.0;
    }
}

// (Re)calculate the current password
- (void)recalculatePassword {
    Token *token = [self currentToken];
    if (token == nil)
        return;
    self.passwordLabel.text = [token generatePassword];
}

// Invoked when editing a new or existing token has finished
- (void)finishedEditing:(Token *)token tokenIndex:(int)tokenIndex commit:(BOOL)commit {
    if (commit) {
        if (tokenIndex == -1)
            tokenIndex = [self.tokens count];
        else
            [self.tokens removeObjectAtIndex:tokenIndex];
        [self.tokens insertObject:token atIndex:tokenIndex];
        [self saveTokens];
        [self.tokenTable reloadData];
        [self clearPasswordDisplay];
        [self stopUpdates];
    }
    [self updatePasswordDisplay];
    [self dismissModalViewControllerAnimated:YES];
    if ([self currentToken] != nil)
        [self startUpdates];
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
    cell.accessoryType = token.editable ? UITableViewCellAccessoryDetailDisclosureButton : UITableViewCellAccessoryNone;
    return cell;
}

// Invoked when a token is deleted
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
    forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.tokens removeObjectAtIndex:[indexPath row]];
        [self saveTokens];
        [self.tokenTable reloadData];
        [self clearPasswordDisplay];
        [self stopUpdates];
    }
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
    edit.token = [Token createFromToken:[self.tokens objectAtIndex:row]];
    edit.tokenIndex = row;
    edit.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentModalViewController:edit animated:YES];
}

// Invokded when the "Add" nav bar button is pressed
- (IBAction)addToken:(id)sender {
    [self stopUpdates];
    EditTokenViewController *add = [[[EditTokenViewController alloc] initWithNibName:@"EditTokenView" bundle:nil] autorelease];
    add.mainViewController = self;
    add.token = [Token createEmpty];
    add.tokenIndex = -1;
    add.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentModalViewController:add animated:YES];
}

@end
