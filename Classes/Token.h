
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

@interface Token : NSObject {
    NSString *name;
    NSData *key;
    BOOL timeBased;
    int counter;
    int interval;
    int numDigits;
    BOOL displayHex;
    BOOL editable;
    NSDate *lastEvent;
}

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSData *key;
@property (nonatomic) BOOL timeBased;
@property (nonatomic) int counter;
@property (nonatomic) int interval;
@property (nonatomic) int numDigits;
@property (nonatomic) BOOL displayHex;
@property (nonatomic) BOOL editable;
@property (nonatomic, retain) NSDate *lastEvent;

+ (Token *)createEmpty;
+ (Token *)createFromDictionary:(NSDictionary *)dict;
+ (Token *)createFromToken:(Token *)token;
- (NSDictionary *)toDictionary;
- (NSString *)generatePassword;
- (void)advanceCounter;

@end
