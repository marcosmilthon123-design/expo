// Copyright 2025-present 650 Industries. All rights reserved.

#import <Foundation/Foundation.h>

#ifdef __cplusplus
#include <worklets/WorkletRuntime/WorkletRuntime.h>
#include <memory>
#endif

/**
 Internal ObjC container that holds a
 `std::weak_ptr<worklets::WorkletRuntime>` behind an `NSObject` façade.
 Attached as the `opaqueHandle` on `EXWorkletRuntime` so scheduling and
 execution can look up the underlying runtime without going through JSI
 on every call.
 */
@interface WorkletsRuntimeHandle : NSObject

#ifdef __cplusplus
- (nonnull instancetype)initWithWeakWorkletRuntime:(std::weak_ptr<worklets::WorkletRuntime>)weakRuntime NS_DESIGNATED_INITIALIZER;
- (std::shared_ptr<worklets::WorkletRuntime>)lockWorkletRuntime;
#endif

- (nonnull instancetype)init NS_UNAVAILABLE;

@end
