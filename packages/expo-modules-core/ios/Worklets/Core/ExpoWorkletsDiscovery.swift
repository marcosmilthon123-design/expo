// Copyright 2025-present 650 Industries. All rights reserved.

import Foundation

/**
 Locates the optional `ExpoWorkletsProvider` at runtime. Mirrors the
 `NSClassFromString` pattern used by `ExpoCamera`'s
 `BarcodeScanner.discoverProvider()` — when `ExpoModulesWorkletsAdapter`
 isn't linked (because `react-native-worklets` isn't installed), the
 lookup returns `nil` and every worklets-consuming selector raises the
 `"Worklets integration is disabled"` `NSException`.
 */
@objc(EXWorkletsDiscovery)
public final class ExpoWorkletsDiscovery: NSObject {
  private static let providerClassName = "ExpoWorkletsBridgeProvider"

  // Matches the concurrency annotation used by `AppContext.uiRuntimeFactory`
  // in `ios/Core/AppContext.swift`. Initialized exactly once at first
  // access and never mutated afterwards, so the `unsafe` mark is accurate.
  @objc public static nonisolated(unsafe) let sharedProvider: ExpoWorkletsProvider? = {
    guard
      let cls = NSClassFromString(providerClassName) as? NSObject.Type,
      let instance = cls.init() as? ExpoWorkletsProvider
    else {
      return nil
    }
    return instance
  }()

  /// Returns the registered provider or raises an `NSException` that
  /// matches the behavior of the removed `#if WORKLETS_ENABLED` `#else`
  /// stubs. Callers in Swift should prefer `sharedProvider`.
  @objc public static func requireProvider() -> ExpoWorkletsProvider {
    guard let provider = sharedProvider else {
      NSException(
        name: NSExceptionName(rawValue: "WorkletException"),
        reason: "Worklets integration is disabled",
        userInfo: nil
      ).raise()
      fatalError("unreachable")
    }
    return provider
  }
}
