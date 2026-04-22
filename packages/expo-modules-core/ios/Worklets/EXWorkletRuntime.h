// Copyright 2025-present 650 Industries. All rights reserved.

#import <ExpoModulesJSI/EXJavaScriptRuntime.h>
#import <ExpoModulesJSI/EXJavaScriptObject.h>

/**
 Marker subclass of `EXJavaScriptRuntime` used to carry a
 `worklets::WorkletRuntime` across the Swift/ObjC boundary. No
 `worklets::*` type appears in this header so the class can live in a
 precompilable xcframework. `ExpoModulesWorkletsAdapter` is the only
 code that constructs instances and the only code that interprets
 `opaqueHandle` — which it uses to stash a weak pointer back to the
 underlying `worklets::WorkletRuntime` so scheduling doesn't have to
 look it up via JSI every call.
 */
NS_SWIFT_NAME(WorkletRuntime)
@interface EXWorkletRuntime : EXJavaScriptRuntime

@property (nonatomic, readonly, nonnull) id opaqueHandle;

#ifdef __cplusplus
- (nonnull instancetype)initWithRuntime:(jsi::Runtime &)runtime
                            callInvoker:(std::shared_ptr<react::CallInvoker>)callInvoker
                           opaqueHandle:(nonnull id)opaqueHandle;
#endif

@end
