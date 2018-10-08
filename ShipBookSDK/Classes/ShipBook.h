//
//  ShipBook.h
//  ShipBook
//
//  Created by Elisha Sterngold on 25/10/2017.
//  Copyright © 2018 ShipBook Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for ShipBook.
FOUNDATION_EXPORT double ShipBookVersionNumber;

//! Project version string for ShipBook.
FOUNDATION_EXPORT const unsigned char ShipBookVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <ShipBook/PublicHeader.h>


#define LogE(message) [Log e:message tag:nil function:NSStringFromSelector(_cmd) file:[NSString stringWithUTF8String:__FILE__] line:__LINE__]
#define LogW(message) [Log w:message tag:nil function:NSStringFromSelector(_cmd) file:[NSString stringWithUTF8String:__FILE__] line:__LINE__]
#define LogI(message) [Log i:message tag:nil function:NSStringFromSelector(_cmd) file:[NSString stringWithUTF8String:__FILE__] line:__LINE__]
#define LogD(message) [Log d:message tag:nil function:NSStringFromSelector(_cmd) file:[NSString stringWithUTF8String:__FILE__] line:__LINE__]
#define LogV(message) [Log v:message tag:nil function:NSStringFromSelector(_cmd) file:[NSString stringWithUTF8String:__FILE__] line:__LINE__]

