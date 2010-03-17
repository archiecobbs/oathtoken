
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

#import "NSData+Hex.h"

@implementation NSData (Hex)

- (NSString *)toHexString {
    const uint8_t *data = [self bytes];
    NSMutableString *string = [NSMutableString stringWithCapacity:[self length] * 2];
    for (int i = 0; i < [self length]; i++)
        [string appendFormat:@"%02x", data[i]];
    return string;
}

@end
