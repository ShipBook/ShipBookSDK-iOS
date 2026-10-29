# Changelog

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
