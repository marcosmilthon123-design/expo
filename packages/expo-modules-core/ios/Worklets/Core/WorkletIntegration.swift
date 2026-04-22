// Copyright 2025-present 650 Industries. All rights reserved.

import ExpoModulesCore

/// Registers the worklet runtime factory with ExpoModulesCore.
/// This is called automatically via +load in WorkletIntegrationLoader.mm.
@objc(EXWorkletIntegration)
public final class WorkletIntegration: NSObject {
  @objc public static func register() {
    AppContext.uiRuntimeFactory = { _, pointerValue, runtime in
      let provider = ExpoWorkletsDiscovery.requireProvider()
      guard let uiRuntime = provider.createWorkletRuntime(from: pointerValue, runtime: runtime) else {
        throw WorkletRuntimePointerExtractionException()
      }
      return uiRuntime
    }
  }
}

private final class WorkletRuntimePointerExtractionException: Exception, @unchecked Sendable {
  override var reason: String {
    "Cannot extract pointer to UI worklet runtime"
  }
}
