# ShipBook SDK for iOS

[![Swift Package Manager](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/ShipBook/ShipBookSDK-iOS)

Shipbook SDK for iOS applications. Capture logs, errors, and exceptions from your iOS apps and view them in the [Shipbook console](https://console.shipbook.io/). Learn more at [shipbook.io](https://www.shipbook.io/).

## Installation

Add the package URL in Xcode via Swift Package Manager:

```
https://github.com/ShipBook/ShipBookSDK-iOS.git
```

## Quick Start

```swift
import ShipBookSDK

// Initialize Shipbook in AppDelegate (do this once at app startup)
func application(_ application: UIApplication,
                 didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    ShipBook.start(appId: "YOUR_APP_ID", appKey: "YOUR_APP_KEY")
    return true
}

// Get a logger for your class/component
let log = ShipBook.getLogger("MyViewController")

// Log messages at different severity levels
log.v("Detailed trace information")
log.d("Debug information")
log.i("General information")
log.w("Warning message")
log.e("Error message")
```

## Features

- **Remote Logging** - View all your app logs in the Shipbook console
- **Error Tracking** - Automatically captures uncaught exceptions
- **Session Tracking** - Group logs by user session
- **Offline Support** - Logs are queued and sent when connectivity is restored
- **Dynamic Configuration** - Change log levels remotely without redeploying
- **User Identification** - Associate logs with specific users

## Configuration

### Enable Inner Logging (Debug Mode)

```swift
ShipBook.enableInnerLog(enable: true)
```

### Register User

```swift
ShipBook.registerUser(userId: "user-123",
                      userName: "johndoe",
                      fullName: "John Doe",
                      email: "john@example.com",
                      phoneNumber: "+1234567890",
                      additionalInfo: ["role": "admin"])
```

### Logout

```swift
ShipBook.logout()
```

### Link Sessions with Your Backend

Add the session headers to requests toward your own backend, and the Shipbook console links this app session to the sessions those requests create in your Node.js backend:

```swift
var request = URLRequest(url: URL(string: "https://api.your-backend.com/checkout")!)
for (name, value) in ShipBook.getSessionHeaders() {
  request.setValue(value, forHTTPHeaderField: name)
}
```

It returns an empty dictionary until login completes, so adding it is always safe.

### Screen Tracking

```swift
ShipBook.screen(name: "HomePage")
```

### Static Log Methods

You can also use static methods without creating a logger instance:

```swift
Log.e("Something went wrong")
Log.w("This is a warning")
Log.i("General info")
Log.d("Debug info")
Log.v("Trace info")
```

### Objective-C

The SDK is fully compatible with Objective-C. Convenience macros are provided:

```objective-c
#import <ShipBookSDK/ShipBookSDK-Swift.h>
#import <ShipBookSDK/ShipBook.h>

LogE(@"Something went wrong");
LogW(@"This is a warning");
LogI(@"General info");
LogD(@"Debug info");
LogV(@"Trace info");
```

## Getting Your App ID and Key

1. Sign up at [shipbook.io](https://www.shipbook.io/)
2. Create a new application in the console
3. Copy your App ID and App Key from the application settings

For full setup instructions, see the [iOS documentation](https://www.shipbook.io/docs/ios-log-integration).

## Links

- [Shipbook Website](https://www.shipbook.io/)
- [Shipbook Console](https://console.shipbook.io/)
- [Documentation](https://www.shipbook.io/docs/)
- [GitHub Repository](https://github.com/ShipBook/ShipBookSDK-iOS)

## Author

Elisha Sterngold ([ShipBook Ltd.](https://www.shipbook.io))

## License

ShipBook SDK is available under the MIT license. See the [LICENSE](LICENSE) file for more info.
