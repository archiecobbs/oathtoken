
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

#import "Token.h"
#import "HOTP.h"

@implementation Token

@synthesize name;
@synthesize key;
@synthesize timeBased;
@synthesize counter;
@synthesize interval;
@synthesize numDigits;
@synthesize displayHex;
@synthesize lockdown;
@synthesize lastEvent;

+ (Token *)createEmpty {
    Token *token = [[[Token alloc] init] autorelease];
    token.name = @"";
    token.key = [NSData data];
    token.timeBased = DEFAULT_TIME_BASED;
    token.counter = DEFAULT_COUNTER;
    token.interval = DEFAULT_INTERVAL;
    token.numDigits = DEFAULT_NUM_DIGITS;
    token.displayHex = DEFAULT_DISPLAY_HEX;
    token.lockdown = NO;
    token.lastEvent = nil;
    return token;
}

+ (Token *)createFromDictionary:(NSDictionary *)dict {
    Token *token = [[[Token alloc] init] autorelease];
    token.name = [dict objectForKey:NAME_KEY];
    token.key = [dict objectForKey:KEY_KEY];
    token.timeBased = [[dict objectForKey:TIME_BASED_KEY] boolValue];
    token.counter = [[dict objectForKey:COUNTER_KEY] intValue];
    token.interval = [[dict objectForKey:INTERVAL_KEY] intValue];
    token.numDigits = [[dict objectForKey:NUM_DIGITS_KEY] intValue];
    token.displayHex = [[dict objectForKey:DISPLAY_HEX_KEY] boolValue];
    token.lockdown = [[dict objectForKey:LOCKDOWN_KEY] boolValue];
    token.lastEvent = [dict objectForKey:LAST_EVENT_KEY];
    return token;
}

// NSCopying
- (id)copyWithZone:(NSZone *)zone {
    Token *copy = [[[self class] allocWithZone: zone] init];
    copy.name = [[self.name copyWithZone:zone] autorelease];
    copy.key = [[self.key copyWithZone:zone] autorelease];
    copy.timeBased = self.timeBased;
    copy.counter = self.counter;
    copy.interval = self.interval;
    copy.numDigits = self.numDigits;
    copy.displayHex = self.displayHex;
    copy.lockdown = self.lockdown;
    copy.lastEvent = self.lastEvent != nil ? [[self.lastEvent copyWithZone:zone] autorelease] : nil;
    return copy;
}

- (NSDictionary *)toDictionary {
    NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:
                          self.name, NAME_KEY,
                          self.key, KEY_KEY,
                          [NSNumber numberWithBool:self.timeBased], TIME_BASED_KEY,
                          [NSNumber numberWithInt:self.counter], COUNTER_KEY,
                          [NSNumber numberWithInt:self.interval], INTERVAL_KEY,
                          [NSNumber numberWithInt:self.numDigits], NUM_DIGITS_KEY,
                          [NSNumber numberWithBool:self.displayHex], DISPLAY_HEX_KEY,
                          [NSNumber numberWithBool:self.lockdown], LOCKDOWN_KEY,
                          self.lastEvent, LAST_EVENT_KEY,
                         nil];
    [dict autorelease];
    return dict;
}

- (NSString *)generatePassword {
    NSUInteger index = self.timeBased ? time(NULL) / self.interval : self.counter;
    HOTP *hotp = [HOTP hotpWithKey:self.key counter:index numDigits:self.numDigits];
    [hotp computePassword];
    return self.displayHex ? hotp.hex : hotp.dec;
}

- (void)advanceCounter {
    if (!self.timeBased)
        self.counter++;
}

- (BOOL)applyChangesName:(NSString *)newName key:(NSString *)newKey timeBased:(BOOL)newTimeBased
                 counter:(NSString *)newCounter interval:(NSString *)newInterval numDigits:(NSString *)newNumDigits
              displayHex:(BOOL)newDisplayHex errhdrp:(NSString **)errhdrp errmsgp:(NSString **)errmsgp {
    
    // Check name
    if ([newName length] == 0) {
        *errhdrp = @"Invalid Name";
        *errmsgp = @"The token name must not be empty";
        return NO;
    }
    
    // Check key
    NSString *keyDigits = [newKey validateHex];
    if (keyDigits == nil) {
        *errhdrp = @"Invalid Key";
        *errmsgp = @"The key must contain an even number of hexadecimal digits (0-9 and A-F)";
        return NO;
    }
    int nbytes = [keyDigits length] / 2;
    if (nbytes < MIN_KEY_BYTES) {
        *errhdrp = @"Key Too Short";
        *errmsgp = [NSString stringWithFormat:@"The key must contain at least %d bytes", MIN_KEY_BYTES];
        return NO;
    }
    
    // Check counter
    NSInteger counterValue;
    NSScanner *scanner = [NSScanner scannerWithString:newCounter];
    if (![scanner scanInteger:&counterValue] || counterValue < 0) {
        if (newTimeBased)
            counterValue = DEFAULT_COUNTER;
        else {
            *errhdrp = @"Invalid Counter";
            *errmsgp = @"The counter must be a non-negative number";
            return NO;
        }
    }
    
    // Check interval
    NSInteger intervalValue;
    scanner = [NSScanner scannerWithString:newInterval];
    if (![scanner scanInteger:&intervalValue] || intervalValue < 1) {
        if (!newTimeBased)
            intervalValue = DEFAULT_INTERVAL;
        else {
            *errhdrp = @"Invalid Interval";
            *errmsgp = @"The time interval must be a non-negative number";
            return NO;        
        }
    }
    
    // Check # digits
    NSInteger digitsValue;
    int minDigits = MIN_DIGITS;
    int maxDigits = newDisplayHex ? MAX_DIGITS_HEX : MAX_DIGITS_DECIMAL;
    scanner = [NSScanner scannerWithString:newNumDigits];
    if (![scanner scanInteger:&digitsValue] || digitsValue < minDigits || digitsValue > maxDigits) {
        *errhdrp = @"Invalid Number of Digits";
        *errmsgp = [NSString stringWithFormat:@"The number of digits must be a number between %d and %d", minDigits, maxDigits];
        return NO;        
    }
    
    // Changes are OK
    self.name = newName;
    self.key = [keyDigits parseHex];
    self.timeBased = newTimeBased;
    self.counter = counterValue;
    self.interval = intervalValue;
    self.numDigits = digitsValue;
    self.displayHex = newDisplayHex;
    return YES;
}

- (void)dealloc {
    [self.name release];
    [self.key release];
    [self.lastEvent release];
    [super dealloc];
}

@end
