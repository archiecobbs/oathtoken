
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

#import <UIKit/UIKit.h>

#import "MainViewController.h"

#define ADD_TOKEN_URL_PATH      @"/addToken"

@interface OATH_TokenAppDelegate : NSObject <UIApplicationDelegate, UIAlertViewDelegate> {
    UIWindow *window;
    UINavigationController *navController;
    MainViewController *mainController;
    Token *addToken;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navController;
@property (nonatomic, retain) IBOutlet MainViewController *mainController;
@property (nonatomic, retain) Token *addToken;

- (Token *)tokenFromURL:(NSURL *)url errmsgp:(NSString **)errmsgp;
- (NSDictionary *)parseURLParams:(NSString *)params;

@end

