# ShipBook SDK for iOS

## About Shipbook
[ShipBook](https://www.shipbook.io) gives you the power to remotely gather, search and analyze your user logs and exceptions in the cloud, on a per-user & session basis.

---

## Requirements
ShipBook works from SWIFT 4.2 (min. version 3), Objective-C and from iOS 10.  
Documentation for [Objective-C](README_ObjC.md)

---
## Installation 

ShipBookSDK is  available through:
1. [Swift Package Manager](https://swift.org/package-manager/)
2. [CocoaPods](http://cocoapods.org).   
3. [Carthage](https://github.com/Carthage/Carthage)

### Using Swift Package Manager
Select File > Swift Packages > Add Package Dependency and enter `https://github.com/ShipBook/ShipBookSDK-iOS.git`.

### Using CocoaPods
Once you have installed CocoaPods, add the following line to your Podfile and run `pod install`:
```ruby
pod 'ShipBookSDK'
```

### Using Carthage
Add the following line to your Cartfile:
```
github "ShipBook/ShipBookSDK-iOS"
```

If you use Carthage to build your dependencies, make sure you have added ShipBookSDK.framework to the "Linked Frameworks and Libraries" section of your target, and have included them in your Carthage framework copying build phase.

---
##  Integrating ShipBook into your code

In your AppDelegate file, add the following:
```swift
import ShipBookSDK
```

Then, add the following to `application(_:didFinishLaunchingWithOptions:)`:

```swift
ShipBook.start(appId:"YOUR_APP_ID", appKey:"YOUR_APP_KEY")
```

To have a log on each class you need to create a logger.  
For Example, in MainViewController:
```swift
import ShipBookSDK

fileprivate let log = ShipBook.getLogger(MainViewController.self)
```

The usage of the log:

```swift
log.e("the log message") // Error log
log.w("the log message") // Warning log
log.i("the log message") // Info log
log.d("the log message") // Debug log
log.v("the log message") // Verbose log
```

If you’d like to add a tag that isn't the name of the class you're using then you can add a custom tag:
```swift
import ShipBookSDK

fileprivate let log = ShipBook.getLogger("CUSTOM_TAG")
```

## Enable Shipbook debug logging
If your logs weren't uploaded to Shipbook, or you're experiencing some other issue with Shipbook, you can enable Shipbook debug logging to track down the problem.

```swift
ShipBook.enableInnerLog(enable: true)
```

## Linking ShipBook to a user’s information
The SDK allows the option to associate each session with specific user information.

### Register user:
The best practice is to set registerUser before ShipBook.start. It will also work after this point however, it will require an additional api request.
```swift
ShipBook.registerUser(userId: "USER_ID",
                      userName: "USER_NAME",
                      fullName: "USER NAME",
                      email: "USER_EMAIL",
                      phoneNumber: "USER_PHONE_NUMBER",
                      additionalInfo: "STRING DICTIONARY OF KEY VALUE")
```
The only required parameter is `userId`.

### Logout
To logout the user, add the following code to your app’s logout function.
```swift
ShipBook.logout()
```
---

## Screen
To log the user’s screen information, add the following code
```swift
ShipBook.screen(name: "SCREEN_NAME")
```
The best practice is to add this code to viewWillAppear in the view controller.

---

# Upload Dsym

## Create an authentication key
1. Open [shipbook console](https://console.shipbook.io).
2. Open **Preferences**.
3. Open the **Authentication Keys**.
4. Create key with type **Symbols**.
5. Copy the key.

## Add upload script

1. Open Xcode, select your project from the **Project Navigator**.
2. Click on the application target.
3. Select the **Build Phase** tab.
4. Click the + icon in the upper left corner of the main panel.
5. Select **New Run Script Phase** Phase from the dropdown.
6. In the script box, add the following lines: (Don't forget to change the `SHIPBOOK_APPID` and `SHIPBOOK_SYMBOLS_KEY` )

```sh
export SHIPBOOK_APPID="YOUR_APP_ID"
export SHIPBOOK_SYMBOLS_KEY="YOUR_SYMBOLS_KEY"

SCRIPT=${PODS_ROOT}/ShipBookSDK/shipbook_build_dsym_upload.sh

if [ "${CONFIGURATION}" = "Release" ]; then
/bin/sh "${SCRIPT}"
fi
```

## Troubleshooting

More often than not, dSYM files go missing because Xcode simply isn't producing them. Check that Xcode is producing the correct dSYM for every build:

1. Open Xcode, select your project from the **Project Navigator**.
2. Click on the application target.
3. Select the **Build Settings** tab, then click All.
4. Search for "debug information format".
5. Set **Debug Information Format** to `DWARF with dSYM File` for all your build types.
6. Rebuild your app.


# Additional Information
## Automatically Importing ShipBookSDK
If you don’t want to manually add `import ShipBookSDK` to each source file, you may insert the following code to the AppDelegate file:

```swift
import ShipBookSDK
public typealias ShipBook = ShipBookSDK.ShipBook
```

## Static Function Alternative to getLogger
You may use a static function in place of getLogger. This is not recommended and the caveats are listed below. When a static function activates the logger, the tag will become the filename.
The usage of the log:

The usage of the log:
```swift
Log.e("the log message") // Error log
Log.w("the log message") // Warning log
Log.i("the log message") // Info log
Log.d("the log message") // Debug log
Log.v("the log message") // Verbose log
```
As mentioned, working with this static logger isn't ideal:
* Performance is slower, especially in cases where the log is closed
* The log’s information is less detailed. Ideally, you should create a logger for each class.
* The Log name can have a name collision with a local Log class.

---

## Using Wrappers with ShipBook
If you are already using some kind of a logging system, you may want to write wrappers to send the logs to both systems.

When creating the wrapper on the logs, you will need to implement all the parameters of each log.

For example a wrapper for `log.e()`:
```swift
func e(_ msg:String,
       tag:String? = nil,
       function: String = #function,
       file: String = #file,
       line: Int = #line) {
  log.e(msg: msg, tag: tag, function: function,file: file,line: line)
}
```

You can also implement the function that is receiving all the messages:  `message()`:

```swift
func e(_ msg:String,
       tag:String? = nil,
       function: String = #function,
       file: String = #file,
       line: Int = #line) {
  log.message(msg: msg, severity: .Error, tag: tag, function: function,file: file,line: line)
}
```
The severity is an enum:
```swift
enum Severity : Int {
  case Off = 0
  case Error
  case Warning
  case Info
  case Debug
  case Verbose
}
```

## Integrating Shipbook with Crashlytics
To integrate Shipbook with crashlytics just implement the completion callback of `ShipBook.start` as following:

```swift
ShipBook.start("YOUR_APP_ID", appKey:"YOUR_APP_KEY") { (sessionUrl: String) -> () in
  Crashlytics.sharedInstance().setObjectValue(sessionUrl, forKey: "ShipbookSession")
}
```

Now you'll have in crashlytics a link to the logs of the specific session. The link is in the Keys tab of the a specific crash under the key `ShipbookSession`.   

# Author

Elisha Sterngold ([ShipBook Ltd.](https://www.shipbook.io))

# License

ShipBookSDK is available under the MIT license. See the LICENSE file for more info.
