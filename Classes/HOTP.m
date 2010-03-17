
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

#import "HOTP.h"

@implementation HOTP

@synthesize key;
@synthesize counter;
@synthesize numDigits;
@synthesize dec;
@synthesize hex;

/* Powers of ten */
static const int powers10[] = { 10, 100, 1000, 10000, 100000, 1000000, 10000000, 100000000, 1000000000, 1000000000 };
#define MAX_DIGITS_10   (sizeof(powers10) / sizeof(*powers10))
#define MAX_DIGITS_16   8

+ (HOTP *)hotpWithKey:(NSData *)key counter:(NSUInteger)counter numDigits:(int)digits {
    HOTP *hotp = [[[HOTP alloc] init] autorelease];
    hotp.key = key;
    hotp.counter = counter;
    if (digits < 1)
        digits = 1;
    else if (digits > MAX_DIGITS_10)
        digits = MAX_DIGITS_10;
    hotp.numDigits = digits;
    return hotp;
}

- (void)computePassword {
    uint8_t hash[CC_SHA1_DIGEST_LENGTH];
    uint8_t tosign[8];
    int offset;
    int value;
    int i;
    
    /* Encode counter */
    for (i = sizeof(tosign) - 1; i >= 0; i--) {
        tosign[i] = counter & 0xff;
        counter >>= 8;
    }
    
    /* Compute HMAC */
    CCHmacContext hmacContext;
    CCHmacInit(&hmacContext, kCCHmacAlgSHA1, key.bytes, key.length);
    CCHmacUpdate(&hmacContext, tosign, sizeof(tosign));
    CCHmacFinal(&hmacContext, hash);
    
    /* Extract selected bytes to get 32 bit integer value */
    offset = hash[CC_SHA1_DIGEST_LENGTH - 1] & 0x0f;
    value = ((hash[offset] & 0x7f) << 24)
      | ((hash[offset + 1] & 0xff) << 16)
      | ((hash[offset + 2] & 0xff) << 8)
      | (hash[offset + 3] & 0xff);
    
    /* Generate decimal digits */
    self.dec = [NSString stringWithFormat:@"%0*d",
                  (self.numDigits < MAX_DIGITS_10 ? self.numDigits : MAX_DIGITS_10),
                  (self.numDigits < MAX_DIGITS_10 ? (value % powers10[self.numDigits - 1]) : value)];

    /* Generate hexadecimal digits */
    self.hex = [NSString stringWithFormat:@"%0*X",
                  (self.numDigits < MAX_DIGITS_16 ? self.numDigits : MAX_DIGITS_16),
                  (self.numDigits < MAX_DIGITS_16 ? (value & ((1 << (4 * self.numDigits)) - 1)) : value)];
}

- (void)dealloc {
    [self.key release];
    [self.dec release];
    [self.hex release];
    [super dealloc];
}

@end
