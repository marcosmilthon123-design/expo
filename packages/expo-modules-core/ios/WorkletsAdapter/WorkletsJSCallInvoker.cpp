// Copyright 2025-present 650 Industries. All rights reserved.

#include "WorkletsJSCallInvoker.h"

namespace expo {

WorkletJSCallInvoker::WorkletJSCallInvoker(
  std::weak_ptr<worklets::WorkletRuntime> workletRuntimeHolder
) : workletRuntimeHolder_(std::move(workletRuntimeHolder)) {}

void WorkletJSCallInvoker::invokeAsync(react::CallFunc &&func) noexcept
{
  auto workletRuntime = workletRuntimeHolder_.lock();
  if (!workletRuntime) {
    return;
  }
  workletRuntime->schedule(std::move(func));
}

void WorkletJSCallInvoker::invokeSync(react::CallFunc &&func)
{
  auto workletRuntime = workletRuntimeHolder_.lock();
  if (!workletRuntime) {
    return;
  }
  workletRuntime->executeSync([func = std::move(func)](jsi::Runtime &rt) -> jsi::Value {
    func(rt);
    return jsi::Value::undefined();
  });
}

} // namespace expo
