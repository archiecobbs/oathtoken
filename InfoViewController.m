
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

#import "InfoViewController.h"
#import "MainViewController.h"

@implementation InfoViewController

@synthesize mainViewController;
@synthesize versionLabel;
@synthesize doneButton;

- (void)viewDidLoad {
    [super viewDidLoad];
    [MainViewController prettyUpButton:self.doneButton];
    NSBundle *bundle = [NSBundle mainBundle];
    self.versionLabel.text = [NSString stringWithFormat:@"version %@ (r%@)",
                              [bundle objectForInfoDictionaryKey:@"CFBundleVersion"],
                              [bundle objectForInfoDictionaryKey:@"SVNRevision"]];
}

- (void)viewDidUnload {
    self.versionLabel = nil;
    self.doneButton = nil;
    [super viewDidUnload];
}

- (IBAction)infoDone:(id)sender {
    [self dismissModalViewControllerAnimated:YES];    
}

- (void)dealloc {
    [mainViewController release];
    [versionLabel release];
    [doneButton release];
    [super dealloc];
}

@end
