// Copyright 2025-present 650 Industries. All rights reserved.

#import "WorkletsSerializableHandle.h"

@implementation WorkletsSerializableHandle {
  std::shared_ptr<worklets::Serializable> _serializable;
}

- (nonnull instancetype)initWithSerializable:(std::shared_ptr<worklets::Serializable>)serializable
{
  if (self = [super init]) {
    _serializable = std::move(serializable);
  }
  return self;
}

- (std::shared_ptr<worklets::Serializable>)serializable
{
  return _serializable;
}

@end
