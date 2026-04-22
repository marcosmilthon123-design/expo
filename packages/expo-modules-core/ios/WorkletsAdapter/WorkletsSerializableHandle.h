// Copyright 2025-present 650 Industries. All rights reserved.

#import <Foundation/Foundation.h>

#ifdef __cplusplus
#include <worklets/SharedItems/Serializable.h>
#include <memory>
#endif

/**
 Internal ObjC container that holds a `std::shared_ptr<worklets::Serializable>`
 behind an `NSObject` façade. Passed around as the `opaqueHandle` on
 `EXJavaScriptSerializable` so the main xcframework never has to know
 about `worklets::*` types.
 */
@interface WorkletsSerializableHandle : NSObject

#ifdef __cplusplus
- (nonnull instancetype)initWithSerializable:(std::shared_ptr<worklets::Serializable>)serializable NS_DESIGNATED_INITIALIZER;
- (std::shared_ptr<worklets::Serializable>)serializable;
#endif

- (nonnull instancetype)init NS_UNAVAILABLE;

@end
