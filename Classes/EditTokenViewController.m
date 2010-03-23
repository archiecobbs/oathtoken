
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

#import "EditTokenViewController.h"
#import "MainViewController.h"

@implementation EditTokenViewController

@synthesize token;
@synthesize originalToken;
@synthesize mainViewController;
@synthesize navItem;
@synthesize tokenIndex;
@synthesize name;
@synthesize key;
@synthesize generateKeyButton;
@synthesize eventTimeSwitch;
@synthesize counterLabel;
@synthesize counter;
@synthesize intervalLabel1;
@synthesize intervalLabel2;
@synthesize interval;
@synthesize numDigits;
@synthesize displayHex;
@synthesize lockDown;
@synthesize needShift;
@synthesize shifted;

- (void)viewDidLoad {
    [super viewDidLoad];
    [MainViewController prettyUpButton:self.generateKeyButton];
    UIBarButtonItem *cancelButton = [[[UIBarButtonItem alloc] initWithTitle:@"Cancel"
																   style:UIBarButtonItemStyleBordered
																  target:self
																  action:@selector(cancelEdit:)] autorelease];    
	self.navigationItem.rightBarButtonItem = cancelButton;
    self.originalToken = [[self.token copy] autorelease];
    [self updateDisplayFromToken];
}

// Invoked when "Event Based" vs. "Time Based" switch is pressed
- (IBAction)typeChanged:(id)sender{
    self.token.timeBased = self.eventTimeSwitch.selectedSegmentIndex == 1;
    [self animateHiddenStuff];
}

// Invoked when interval, counter, or numDigits field is edited to slide up
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.needShift = YES;
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateShift:) userInfo:nil repeats:NO];
}

// Invoked when interval, counter, or numDigits field is done editing to slide back down
- (void)textFieldDidEndEditing:(UITextField *)textField
{
    self.needShift = NO;
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateShift:) userInfo:nil repeats:NO];
}

- (void)updateShift:(NSTimer *)timer
{
    [self shiftViewForKeyboard:self.needShift];
}

- (void)shiftViewForKeyboard:(BOOL)up
{
    const int movementDistance = 216;
    const float movementDuration = 0.3f;

    if (self.shifted == up)
        return;
    int movement = (up ? -movementDistance : movementDistance);
    
    [UIView beginAnimations:@"Shift" context:nil];
    [UIView setAnimationDuration:movementDuration];
    self.view.frame = CGRectOffset(self.view.frame, 0, movement);
    [UIView commitAnimations];
    self.shifted = up;
}

- (void)animateHiddenStuff {
	[UIView beginAnimations:@"Foo" context:nil];
	[UIView setAnimationDuration:0.250];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [self updateHiddenStuff];
    [UIView commitAnimations];  
}

- (void)updateDisplayFromToken {
    self.navItem.title = self.tokenIndex == -1 ? @"New Token" : @"Edit Token";
    self.name.text = self.token.name;
    self.key.text = [self.token.key toHexString];
    self.eventTimeSwitch.selectedSegmentIndex = self.token.timeBased ? 1 : 0;
    self.counter.text = [NSString stringWithFormat:@"%u", self.token.counter];
    self.interval.text = [NSString stringWithFormat:@"%u", self.token.interval];
    self.numDigits.text = [NSString stringWithFormat:@"%u", self.token.numDigits];
    self.displayHex.on = self.token.displayHex;
    self.lockDown.on = self.token.lockdown;
    [self updateHiddenStuff];
}

- (void)updateHiddenStuff {
    double timeBasedAlpha = self.token.timeBased ? 1.0 : 0.0;
    double eventBasedAlpha = self.token.timeBased ? 0.0 : 1.0;
    self.counterLabel.alpha = eventBasedAlpha;
    self.counter.alpha = eventBasedAlpha;
    self.intervalLabel1.alpha = timeBasedAlpha;
    self.intervalLabel2.alpha = timeBasedAlpha;
    self.interval.alpha = timeBasedAlpha;
}

- (IBAction)generateRandomKey {
    uint8_t bytes[20];
    
    if (SecRandomCopyBytes(kSecRandomDefault, sizeof(bytes), bytes) == -1)
        return;
    self.token.key = [NSData dataWithBytes:bytes length:sizeof(bytes)];
    self.key.text = [self.token.key toHexString];
}

- (IBAction)stuffChanged:(id)sender {
    [sender resignFirstResponder];
}

- (void)alertError:(NSString *)title withMessage:(NSString *)msg {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:msg delegate:nil cancelButtonTitle:@"Continue Editing" otherButtonTitles:nil];
    [alert show];
    [alert release];
}

- (IBAction)cancelEdit:(id)sender {
    [self.mainViewController finishedEditing:self.token tokenIndex:self.tokenIndex commit:NO reset:NO];
}

- (IBAction)commitEdit:(id)sender {
    
    // Validate fields
    NSString *errhdr = nil;
    NSString *errmsg = nil;
    if (![self.token applyChangesName:self.name.text key:self.key.text timeBased:self.token.timeBased
                                          counter:self.counter.text interval:self.interval.text numDigits:self.numDigits.text
                                       displayHex:self.displayHex.on errhdrp:&errhdr errmsgp:&errmsg]) {
        [self alertError:errhdr withMessage:errmsg];
        return;
    }
    self.token.lockdown = self.lockDown.on;
    
    // Determine if we should reset 'last event' timestamp
    BOOL reset = ![self.token.key isEqual:self.originalToken.key]
    || self.token.timeBased != self.originalToken.timeBased
    || self.token.counter != self.originalToken.counter
    || self.token.interval != self.originalToken.interval
    || self.token.numDigits != self.originalToken.numDigits
    || self.token.displayHex != self.originalToken.displayHex;
    if (reset)
        self.token.lastEvent = nil;
    
    // Done
    [self.mainViewController finishedEditing:self.token tokenIndex:self.tokenIndex commit:YES reset:reset];
}

- (void)viewDidUnload {
    self.originalToken = nil;
    self.navItem = nil;
    self.name = nil;
    self.key = nil;
    self.eventTimeSwitch = nil;
    self.counter = nil;
    self.interval = nil;
    self.numDigits = nil;
    self.displayHex = nil;
    self.lockDown = nil;
}

- (void)dealloc {
    [token release];
    [originalToken release];
    [mainViewController release];
    [navItem release];
    [name release];
    [key release];
    [eventTimeSwitch release];
    [counter release];
    [interval release];
    [numDigits release];
    [displayHex release];
    [lockDown release];
    [super dealloc];
}

@end
