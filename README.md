# ShipBook SDK for iOS

ShipBook is a cloud service to collect mobile application logs. It also logs UI events and crashes. By having all this information together it is possible to analyze problems easily.

All logs go by default also to the console.

The SDK has very special emphasis on being very fast in the case that the log is closed. Therefore feel free to put as many logs as needed, it won't impact the performance of the app (when logs are closed)

---
## Requirements
ShipBook works with SWIFT 4 and from iOS 10

---
## Installation

ShipBookSDK is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'ShipBookSDK'
```
---
##  Using ShipBook

In your AppDelegate file:
```swift
import ShipBookSDK
```

And add the following to `application(_:didFinishLaunchingWithOptions:)`:

```swift
ShipBook.start(appId:"YOUR_APP_ID", appKey:"YOUR_APP_KEY")
```

For to have a log on each class you should create a logger for Example for MainViewController:
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

If you want to have your own tag that isn't the name of the class that you're using then you can put a tag that you want:
```swift
import ShipBookSDK

fileprivate let log = ShipBook.getLogger("CUSTOM_TAG")
```

### Making that you don't need to import in each file `import ShipBookSDK`
Add the following code in the AppDelegate file:
```swift
import ShipBookSDK
public typealias ShipBook = ShipBookSDK.ShipBook
```

### Calling log without `getLogger`
There are also static functions that implement the logger. In this case the tag will be the filename.

Working with the static logger isn't ideal:
* The implementation is much slower especially in cases that it the log is closed.
* There is less granularity of the log information. Ideally you should create a logger for each class.
* The Log name can have a name collision with a local Log class.

The usage of the log:
```swift
Log.e("the log message") // Error log
Log.w("the log message") // Warning log
Log.i("the log message") // Info log
Log.d("the log message") // Debug log
Log.v("the log message") // Verbose log
```


#### Making that you don't need to import in each file `import ShipBookSDK` for `Log`
```swift
import ShipBookSDK
public typealias Log = ShipBookSDK.Log
```

---

## User associated data
The SDK enables the option to associate the session with specific user information

### Register user:
```swift
ShipBook.registerUser(userId: "USER_ID",
userName: "USER_NAME",
email: "USER_EMAIL",
phoneNumber: "USER_PHONE_NUMBER",
additionalInfo: "STRING DICTIONARY OF KEY VALUE")
```
The only parameter that must be entered is the `userId`.

### Logout
When a user logs out of the system then a new session is created.
```swift
ShipBook.logout()
```

---

## Wrapper on ShipBook
If you want to create a wrapper on the logs you will need to implement all the parameters of each log.

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

If you want you can also implement the function that is getting all the messages: `message()`:

```swift
func e(_ msg:String,
tag:String? = nil,
function: String = #function,
file: String = #file,
line: Int = #line) {
log.e(msg: msg, severity: .Error, tag: tag, function: function,file: file,line: line)
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

## Author

Elisha Sterngold (ShipBook Ltd.)

## License

ShipBookSDK is available under the MIT license. See the LICENSE file for more info.
