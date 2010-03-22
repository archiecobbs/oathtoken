
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

#define MIN_KEY_BYTES 8

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
- (IBAction)typeChanged {
    self.token.timeBased = self.eventTimeSwitch.selectedSegmentIndex == 1;
    [self animateHiddenStuff];
}

- (void)animateHiddenStuff {
	[UIView beginAnimations:@"Foo" context:nil];
	[UIView setAnimationDuration:1.0];
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
    self.lockDown.on = !self.token.editable;
    [self updateHiddenStuff];
}

- (void)updateHiddenStuff {
    self.counterLabel.hidden = self.token.timeBased;
    self.counter.hidden = self.token.timeBased;
    self.intervalLabel1.hidden = !self.token.timeBased;
    self.intervalLabel2.hidden = !self.token.timeBased;
    self.interval.hidden = !self.token.timeBased;
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

- (BOOL)validate:(BOOL *)resetp {

    // Check name
    if ([self.name.text length] == 0) {
        [self alertError:@"Invalid Name" withMessage:@"The token name must not be empty"];
        return NO;
    }
    
    // Check key
    NSString *digits = [self.key.text validateHex];
    if (digits == nil) {
        [self alertError:@"Invalid Key" withMessage:@"The key must contain an even number of hexadecimal digits (0-9 and A-F)"];
        return NO;
    }
    int nbytes = [digits length] / 2;
    if (nbytes < MIN_KEY_BYTES) {
        [self alertError:@"Key Too Short" withMessage:[NSString stringWithFormat:@"The key must contain at least %d bytes", MIN_KEY_BYTES]];
        return NO;
    }
    
    // Check counter
    NSInteger counterValue;
    NSScanner *scanner = [NSScanner scannerWithString:self.counter.text];
    if (![scanner scanInteger:&counterValue] || counterValue < 0) {
        if (self.token.timeBased)
            counterValue = 0;
        else {
            [self alertError:@"Invalid Counter" withMessage:@"The counter must be a non-negative number"];
            return NO;
        }
    }
    
    // Check interval
    NSInteger intervalValue;
    scanner = [NSScanner scannerWithString:self.interval.text];
    if (![scanner scanInteger:&intervalValue] || intervalValue < 1) {
        if (!self.token.timeBased)
            intervalValue = 30;
        else {
            [self alertError:@"Invalid Interval" withMessage:@"The time interval must be a non-negative number"];
            return NO;        
        }
    }
    
    // Check # digits
    NSInteger digitsValue;
    int minDigits = 4;
    int maxDigits = self.displayHex.on ? 8 : 10;
    scanner = [NSScanner scannerWithString:self.numDigits.text];
    if (![scanner scanInteger:&digitsValue] || digitsValue < minDigits || digitsValue > maxDigits) {
        [self alertError:@"Invalid Number of Digits" withMessage:
            [NSString stringWithFormat:@"The number of digits must be a number between %d and %d", minDigits, maxDigits]];
        return NO;        
    }
    
    // Changes are OK
    self.token.name = self.name.text;
    self.token.key = [digits parseHex];
    self.token.counter = counterValue;
    self.token.interval = intervalValue;
    self.token.numDigits = digitsValue;
    self.token.displayHex = self.displayHex.on;
    self.token.editable = !self.lockDown.on;

    // Determine if we should reset 'last event' timestamp
    BOOL reset = ![self.token.key isEqual:self.originalToken.key]
      || self.token.timeBased != self.originalToken.timeBased
      || self.token.counter != self.originalToken.counter
      || self.token.interval != self.originalToken.interval
      || self.token.numDigits != self.originalToken.numDigits
      || self.token.displayHex != self.originalToken.displayHex;
    if (reset)
        self.token.lastEvent = nil;
    *resetp = reset;
    
    // Done
    return YES;
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
    BOOL reset;
    if (![self validate:&reset])
        return;
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
