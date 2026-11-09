# Changelog

## [2.1.1]
- Fixed crash reports from other crash reporters (such as Sentry) when they start before Shipbook. Shipbook called their signal handler with the wrong arguments, so a crash like `abort()` was reported as an `EXC_BAD_ACCESS` inside that reporter and the original crash was lost.
- A signal your app ignores (commonly `SIGPIPE`) now stays ignored. Before, Shipbook recorded it as a crash and then crashed the app.
- Calling `ShipBook.start` a second time no longer reinstalls the crash handlers, which could make a crash loop into Shipbook's own handler.

## [2.1.0]

### Added
- `ShipBook.getSessionHeaders()`. Add its headers to requests toward your own backend, and the Shipbook console links this app session to the sessions those requests create in your Node.js backend. It returns an empty dictionary until login completes, so adding it is always safe.

### Fixed
- Fixed a crash under memory pressure while loading queued logs from disk. Date formatters are now created once and reused instead of on every call.

## [2.0.2]
- Stop retrying `loginSdk` after a 4xx response — broken credentials no longer cause an upload-loop against the server until app restart.
- Fix dead-token-restore loop in `refreshToken`: on a 4xx refresh the SDK now stops retrying instead of restoring the expired token and immediately re-trying.

## [2.0.1]
- Swift 6 compatibility

## [2.0.0]

### Added
- Custom appender support via `ShipBook.registerAppender(type:appenderClass:)`

### Removed
- CocoaPods and Carthage support — SPM is now the only installation method
- tvOS target
