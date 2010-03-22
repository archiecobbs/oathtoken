
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

// Token dictionary keys
#define NAME_KEY        @"name"
#define KEY_KEY         @"key"
#define TIME_BASED_KEY  @"timeBased"
#define COUNTER_KEY     @"counter"
#define INTERVAL_KEY    @"interval"
#define NUM_DIGITS_KEY  @"numDigits"
#define DISPLAY_HEX_KEY @"displayHex"
#define EDITABLE_KEY    @"editable"
#define LAST_EVENT_KEY  @"lastEvent"

@implementation Token

@synthesize name;
@synthesize key;
@synthesize timeBased;
@synthesize counter;
@synthesize interval;
@synthesize numDigits;
@synthesize displayHex;
@synthesize editable;
@synthesize lastEvent;

+ (Token *)createEmpty {
    Token *token = [[[Token alloc] init] autorelease];
    token.name = @"";
    token.key = [NSData data];
    token.timeBased = NO;
    token.counter = 0;
    token.interval = 30;
    token.numDigits = 6;
    token.displayHex = NO;
    token.editable = YES;
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
    token.editable = [[dict objectForKey:EDITABLE_KEY] boolValue];
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
    copy.editable = self.editable;
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
                          [NSNumber numberWithBool:self.editable], EDITABLE_KEY,
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

- (void)dealloc {
    [self.name release];
    [self.key release];
    [self.lastEvent release];
    [super dealloc];
}

@end
