# ShipBook SDK for iOS

## About Shipbook
[ShipBook](https://www.shipbook.io) gives you the power to remotely gather, search and analyze your user logs and exceptions in the cloud, on a per-user & session basis.

---

## Requirements
ShipBook works with SWIFT 4.2 (min. version 3), Objective-C and from iOS 10. 

---
## Installation via CocoaPods

ShipBookSDK is only available through [CocoaPods](http://cocoapods.org). Once you have installed CocoaPods, add the following line to your Podfile and run `pod install`:

```ruby
pod 'ShipBookSDK'
```
---
##  Integrating ShipBook into your code

In your AppDelegate file, add the following:
```objc
@import ShipBookSDK;
```

Then, add the following to `- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions`:

```objc
[ShipBook startWithAppId:@"YOUR_APP_ID" appKey:@"YOUR_APP_KEY"];
```

To have a log on each class you need to create a logger. 
For Example, in MainViewController:
```objc
@import ShipBookSDK;
```

The usage of the log:

```objc
LogE(@"the log message"); // Error log
LogW(@"the log message"); // Warning log
LogI(@"the log message"); // Info log
LogD(@"the log message"); // Debug log
LogV(@"the log message"); // Verbose log
```

## Linking ShipBook to a user’s information
The SDK allows the option to associate each session with specific user information.

### Register user:
The best practice is to set registerUser before ShipBook.start. It will also work after this point however, it will require an additional api request.
```objc
[ShipBook registerUserWithUserId: @"USER_ID",
                        userName: @"USER_NAME",
                        fullName: @"USER NAME",
                           email: @"USER_EMAIL",
                     phoneNumber: @"USER_PHONE_NUMBER",
                  additionalInfo: @"STRING DICTIONARY OF KEY VALUE"];
```
The only required parameter is `userId`.

### Logout
To logout the user, add the following code to your app’s logout function.
```objc
[ShipBook logout];
```
---

## Screen
To log the user’s screen information, add the following code
```objc
[ShipBook screenWithName: @"SCREEN_NAME"];
```
The best practice is to add this code to viewWillAppear in the view controller.

---

# Author

Elisha Sterngold ([ShipBook Ltd.](https://www.shipbook.io))

# License

ShipBookSDK is available under the MIT license. See the LICENSE file for more info.
