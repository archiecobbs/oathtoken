
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

#import "NSString+Hex.h"

@implementation NSString (Hex)

- (NSString *)validateHex {

    // Squeeze out whitespace and detect illegal chars
    NSMutableString *string = [NSMutableString stringWithCapacity:[self length]];
    for (int i = 0; i < [self length]; i++) {
        unichar ch = [self characterAtIndex:i];
        if (isspace(ch))
            continue;
        if (!isxdigit(ch))
            return nil;
        [string appendFormat:@"%c", ch];
    }
    
    // Check length
    if ([string length] % 2 != 0)
        return nil;
    
    // Done
    return string;
}

- (NSData *)parseHex {
    NSMutableData *data = [NSMutableData data];
    for (const char *utf8 = [self UTF8String]; *utf8 != '\0'; utf8 += 2) {
        char substr[3] = { utf8[0], utf8[1], '\0' };
        int value;
        uint8_t byte;
        if (sscanf(substr, "%x", &value) != 1)
            return nil;
        byte = (uint8_t)value;
        [data appendBytes:&byte length:1];
    }
    return data;
}

@end
