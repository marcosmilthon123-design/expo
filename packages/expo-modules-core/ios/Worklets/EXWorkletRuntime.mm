// Copyright 2025-present 650 Industries. All rights reserved.

#import <ExpoModulesWorklets/EXWorkletRuntime.h>

@implementation EXWorkletRuntime {
  id _opaqueHandle;
}

- (nonnull instancetype)initWithRuntime:(jsi::Runtime &)runtime
                            callInvoker:(std::shared_ptr<react::CallInvoker>)callInvoker
                           opaqueHandle:(nonnull id)opaqueHandle
{
  if (self = [super initWithRuntime:runtime callInvoker:callInvoker]) {
    _opaqueHandle = opaqueHandle;
  }
  return self;
}

- (nonnull id)opaqueHandle
{
  return _opaqueHandle;
}

@end
