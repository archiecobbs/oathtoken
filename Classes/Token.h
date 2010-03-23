
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

#import <Foundation/Foundation.h>
#import "NSString+Hex.h"
#import "NSData+Hex.h"

// Token dictionary keys
#define NAME_KEY        @"name"
#define KEY_KEY         @"key"
#define TIME_BASED_KEY  @"timeBased"
#define COUNTER_KEY     @"counter"
#define INTERVAL_KEY    @"interval"
#define NUM_DIGITS_KEY  @"numDigits"
#define DISPLAY_HEX_KEY @"displayHex"
#define LOCKDOWN_KEY    @"lockdown"
#define LAST_EVENT_KEY  @"lastEvent"

// Configuration defaults
#define DEFAULT_TIME_BASED  NO
#define DEFAULT_COUNTER     0
#define DEFAULT_INTERVAL    30
#define DEFAULT_NUM_DIGITS  6
#define DEFAULT_DISPLAY_HEX NO

// Configuration limits
#define MIN_KEY_BYTES       8
#define MIN_DIGITS          4
#define MAX_DIGITS_DECIMAL  10
#define MAX_DIGITS_HEX      8

@interface Token : NSObject <NSCopying> {
    NSString *name;
    NSData *key;
    BOOL timeBased;
    int counter;
    int interval;
    int numDigits;
    BOOL displayHex;
    BOOL lockdown;
    NSDate *lastEvent;
}

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSData *key;
@property (nonatomic) BOOL timeBased;
@property (nonatomic) int counter;
@property (nonatomic) int interval;
@property (nonatomic) int numDigits;
@property (nonatomic) BOOL displayHex;
@property (nonatomic) BOOL lockdown;
@property (nonatomic, retain) NSDate *lastEvent;

+ (Token *)createEmpty;
+ (Token *)createFromDictionary:(NSDictionary *)dict;
- (NSDictionary *)toDictionary;
- (NSString *)generatePassword;
- (void)advanceCounter;
- (BOOL)applyChangesName:(NSString *)name key:(NSString *)key timeBased:(BOOL)timeBased
                    counter:(NSString *)counter interval:(NSString *)interval numDigits:(NSString *)numDigits
                 displayHex:(BOOL)displayHex errhdrp:(NSString **)errhdrp errmsgp:(NSString **)errmsgp;

@end
