// Copyright 2025-present 650 Industries. All rights reserved.

#import "WorkletsRuntimeHandle.h"

@implementation WorkletsRuntimeHandle {
  std::weak_ptr<worklets::WorkletRuntime> _weakRuntime;
}

- (nonnull instancetype)initWithWeakWorkletRuntime:(std::weak_ptr<worklets::WorkletRuntime>)weakRuntime
{
  if (self = [super init]) {
    _weakRuntime = std::move(weakRuntime);
  }
  return self;
}

- (std::shared_ptr<worklets::WorkletRuntime>)lockWorkletRuntime
{
  return _weakRuntime.lock();
}

@end
