
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

#import "OATH_TokenAppDelegate.h"
#import "EditTokenViewController.h"
#import "Token.h"

@implementation OATH_TokenAppDelegate

@synthesize window;
@synthesize mainViewController;
@synthesize addToken;

- (void)applicationDidFinishLaunching:(UIApplication *)application {
    [self.window addSubview:[self.mainViewController view]];
    [self.window makeKeyAndVisible];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    
    // Parse URL into a token
    NSString *errmsg = nil;
    Token *token = [self tokenFromURL:url errmsgp:&errmsg];
    if (token == nil) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unable to Add Token" message:errmsg
                                                       delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [alert release];
        return YES;
    }
    self.addToken = token;

    // Get confirmation
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Confirm New Token"
                                                    message:[NSString stringWithFormat:@"Do you want to add the token `%@'?", token.name]
                                                   delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    [alert show];
    [alert release];
    return YES;
}

// Invoked from 'Confirm New Token' confirmation
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (self.addToken == nil)
        return;
    if (buttonIndex != alertView.cancelButtonIndex)
        [self.mainViewController finishedEditing:self.addToken tokenIndex:-1 commit:YES reset:YES];
    self.addToken = nil;
}

// Convert an URL into a token to be added
- (Token *)tokenFromURL:(NSURL *)url errmsgp:(NSString **)errmsgp {

    // Check overall URL format
    if (url == nil || [url host] != nil || [url query] == nil) {
        *errmsgp = @"Invalid URL format";
        return nil;
    }
    NSString *path = [url path];
    if (path == nil || ![path isEqual:ADD_TOKEN_URL_PATH]) {
        *errmsgp = [NSString stringWithFormat:@"Unrecognized URL path `%@'", path];
        return nil;
    }

    // Parse values and apply defaults for missing parameters
    NSDictionary *params = [self parseURLParams:[url query]];
    NSString *name = [params valueForKey:NAME_KEY];
    if (name == nil)
        name = @"";
    NSString *key = [params valueForKey:KEY_KEY];
    if (key == nil)
        key = @"";
    NSString *timeBasedStr = [params valueForKey:TIME_BASED_KEY];
    if (timeBasedStr == nil)
        timeBasedStr = [NSString stringWithFormat:@"%s", DEFAULT_TIME_BASED ? "true" : "false"];
    NSString *counter = [params valueForKey:COUNTER_KEY];
    if (counter == nil)
        counter = [NSString stringWithFormat:@"%d", DEFAULT_COUNTER];
    NSString *interval = [params valueForKey:INTERVAL_KEY];
    if (interval == nil)
        interval = [NSString stringWithFormat:@"%d", DEFAULT_INTERVAL];
    NSString *numDigits = [params valueForKey:NUM_DIGITS_KEY];
    if (numDigits == nil)
        numDigits = [NSString stringWithFormat:@"%d", DEFAULT_NUM_DIGITS];
    NSString *displayHexStr = [params valueForKey:DISPLAY_HEX_KEY];
    if (displayHexStr == nil)
        displayHexStr = [NSString stringWithFormat:@"%s", DEFAULT_DISPLAY_HEX ? "true" : "false"];
    NSString *lockdownStr = [params valueForKey:LOCKDOWN_KEY];
    if (lockdownStr == nil)
        lockdownStr = @"NO";
    
    // Configure new token
    Token *token = [Token createEmpty];
    NSString *errhdr = nil;
    if (![token applyChangesName:name key:key timeBased:[timeBasedStr boolValue]
                         counter:counter interval:interval numDigits:numDigits
                      displayHex:[displayHexStr boolValue] errhdrp:&errhdr errmsgp:errmsgp])
        return nil;
    token.lockdown = [lockdownStr boolValue];
    
    // Success
    *errmsgp = nil;
    return token;
}

- (NSDictionary *)parseURLParams:(NSString *)params {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    for (NSString *pair in [params componentsSeparatedByString:@"&"]) {
        NSArray *nameValue = [pair componentsSeparatedByString:@"="];
        if ([nameValue count] != 2)
            continue;
        NSString *key = [[nameValue objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *value = [[nameValue objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [dict setValue:value forKey:key];
    }
    return dict;
}

- (void)dealloc {
    [self.addToken release];
    [self.mainViewController release];
    [self.window release];
    [super dealloc];
}

@end
