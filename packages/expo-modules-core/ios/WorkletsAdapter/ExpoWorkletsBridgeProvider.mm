// Copyright 2025-present 650 Industries. All rights reserved.

#import <Foundation/Foundation.h>

#import <ExpoModulesJSI/EXJavaScriptValue.h>
#import <ExpoModulesJSI/EXJavaScriptRuntime.h>
#import <ExpoModulesJSI/EXJSIConversions.h>

#import <ExpoModulesWorklets/EXJavaScriptSerializable.h>
#import <ExpoModulesWorklets/EXWorkletRuntime.h>
#import <ExpoModulesWorklets/EXWorkletsProvider.h>

#include <worklets/SharedItems/Serializable.h>
#include <worklets/WorkletRuntime/WorkletRuntime.h>

#import "WorkletsSerializableHandle.h"
#import "WorkletsRuntimeHandle.h"
#import "WorkletsJSCallInvoker.h"

static EXSerializableValueType EXSerializableValueTypeFromWorklets(worklets::Serializable::ValueType type)
{
  switch (type) {
    case worklets::Serializable::ValueType::UndefinedType:       return EXSerializableValueTypeUndefined;
    case worklets::Serializable::ValueType::NullType:            return EXSerializableValueTypeNull;
    case worklets::Serializable::ValueType::BooleanType:         return EXSerializableValueTypeBoolean;
    case worklets::Serializable::ValueType::NumberType:          return EXSerializableValueTypeNumber;
    case worklets::Serializable::ValueType::BigIntType:          return EXSerializableValueTypeBigInt;
    case worklets::Serializable::ValueType::StringType:          return EXSerializableValueTypeString;
    case worklets::Serializable::ValueType::ObjectType:          return EXSerializableValueTypeObject;
    case worklets::Serializable::ValueType::ArrayType:           return EXSerializableValueTypeArray;
    case worklets::Serializable::ValueType::MapType:             return EXSerializableValueTypeMap;
    case worklets::Serializable::ValueType::SetType:             return EXSerializableValueTypeSet;
    case worklets::Serializable::ValueType::WorkletType:         return EXSerializableValueTypeWorklet;
    case worklets::Serializable::ValueType::RemoteFunctionType:  return EXSerializableValueTypeRemoteFunction;
    case worklets::Serializable::ValueType::HandleType:          return EXSerializableValueTypeHandle;
    case worklets::Serializable::ValueType::HostObjectType:      return EXSerializableValueTypeHostObject;
    case worklets::Serializable::ValueType::HostFunctionType:    return EXSerializableValueTypeHostFunction;
    case worklets::Serializable::ValueType::ArrayBufferType:     return EXSerializableValueTypeArrayBuffer;
    case worklets::Serializable::ValueType::TurboModuleLikeType: return EXSerializableValueTypeTurboModuleLike;
    case worklets::Serializable::ValueType::ImportType:          return EXSerializableValueTypeImport;
    case worklets::Serializable::ValueType::SynchronizableType:  return EXSerializableValueTypeSynchronizable;
    case worklets::Serializable::ValueType::CustomType:          return EXSerializableValueTypeCustom;
    default:                                                      return EXSerializableValueTypeUndefined;
  }
}

@interface ExpoWorkletsBridgeProvider : NSObject <EXWorkletsProvider>
@end

@implementation ExpoWorkletsBridgeProvider

#pragma mark - Serializable discovery

- (BOOL)isSerializable:(nonnull EXJavaScriptValue *)value
               runtime:(nonnull EXJavaScriptRuntime *)runtime
{
  jsi::Value jsValue = [value get];
  jsi::Runtime *rt = [runtime get];

  if (!jsValue.isObject()) {
    return NO;
  }

  jsi::Object obj = jsValue.getObject(*rt);
  return obj.hasProperty(*rt, "__serializableRef") && obj.hasNativeState(*rt);
}

- (nullable EXJavaScriptSerializable *)extractSerializableFrom:(nonnull EXJavaScriptValue *)value
                                                        runtime:(nonnull EXJavaScriptRuntime *)runtime
{
  if (![self isSerializable:value runtime:runtime]) {
    return nil;
  }

  jsi::Value jsValue = [value get];
  jsi::Runtime *rt = [runtime get];

  auto serializable = worklets::extractSerializableOrThrow(*rt, jsValue);
  WorkletsSerializableHandle *handle = [[WorkletsSerializableHandle alloc] initWithSerializable:serializable];
  EXSerializableValueType valueType = EXSerializableValueTypeFromWorklets(serializable->valueType());

  return [[EXJavaScriptSerializable alloc] initWithOpaqueHandle:handle valueType:valueType];
}

#pragma mark - Worklet runtime construction

- (nullable EXWorkletRuntime *)createWorkletRuntimeFromValue:(nonnull EXJavaScriptValue *)jsValue
                                                     runtime:(nonnull EXJavaScriptRuntime *)runtime
{
  jsi::Value rawValue = [jsValue get];
  jsi::Runtime *rawRuntime = [runtime get];

  if (!rawValue.isObject()) {
    return nil;
  }

  jsi::Object workletRuntimeObject = rawValue.getObject(*rawRuntime);
  if (!workletRuntimeObject.isArrayBuffer(*rawRuntime)) {
    return nil;
  }

  size_t pointerSize = sizeof(uintptr_t *);
  jsi::ArrayBuffer workletRuntimeArrayBuffer = workletRuntimeObject.getArrayBuffer(*rawRuntime);
  if (workletRuntimeArrayBuffer.size(*rawRuntime) != pointerSize) {
    return nil;
  }

  jsi::Runtime *jsRuntime = reinterpret_cast<jsi::Runtime *>(
    *reinterpret_cast<uintptr_t **>(workletRuntimeArrayBuffer.data(*rawRuntime))
  );
  if (jsRuntime == nullptr) {
    return nil;
  }

  auto weakWorkletRuntime = worklets::WorkletRuntime::getWeakRuntimeFromJSIRuntime(*jsRuntime);
  auto workletRuntime = weakWorkletRuntime.lock();
  if (!workletRuntime) {
    return nil;
  }

  WorkletsRuntimeHandle *handle = [[WorkletsRuntimeHandle alloc] initWithWeakWorkletRuntime:weakWorkletRuntime];
  auto callInvoker = std::make_shared<expo::WorkletJSCallInvoker>(weakWorkletRuntime);

  return [[EXWorkletRuntime alloc] initWithRuntime:workletRuntime->getJSIRuntime()
                                       callInvoker:callInvoker
                                      opaqueHandle:handle];
}

#pragma mark - Worklet execution

static std::shared_ptr<worklets::SerializableWorklet> extractWorklet(EXJavaScriptSerializable *serializable)
{
  id opaqueHandle = serializable.opaqueHandle;
  if (![opaqueHandle isKindOfClass:[WorkletsSerializableHandle class]]) {
    return nullptr;
  }
  auto raw = [(WorkletsSerializableHandle *)opaqueHandle serializable];
  return std::dynamic_pointer_cast<worklets::SerializableWorklet>(raw);
}

static std::shared_ptr<worklets::WorkletRuntime> lockWorkletRuntime(EXWorkletRuntime *runtime)
{
  id opaqueHandle = runtime.opaqueHandle;
  if (![opaqueHandle isKindOfClass:[WorkletsRuntimeHandle class]]) {
    return nullptr;
  }
  return [(WorkletsRuntimeHandle *)opaqueHandle lockWorkletRuntime];
}

- (void)schedule:(nonnull EXJavaScriptSerializable *)serializable
         runtime:(nonnull EXWorkletRuntime *)runtime
{
  auto workletRuntime = lockWorkletRuntime(runtime);
  if (!workletRuntime) {
    return;
  }
  auto worklet = extractWorklet(serializable);
  if (!worklet) {
    return;
  }
  workletRuntime->schedule(worklet);
}

- (void)execute:(nonnull EXJavaScriptSerializable *)serializable
        runtime:(nonnull EXWorkletRuntime *)runtime
{
  auto workletRuntime = lockWorkletRuntime(runtime);
  if (!workletRuntime) {
    return;
  }
  auto worklet = extractWorklet(serializable);
  if (!worklet) {
    return;
  }
  workletRuntime->runSync(worklet);
}

- (void)schedule:(nonnull EXJavaScriptSerializable *)serializable
         runtime:(nonnull EXWorkletRuntime *)runtime
       arguments:(nonnull NSArray *)arguments
{
  auto workletRuntime = lockWorkletRuntime(runtime);
  if (!workletRuntime) {
    return;
  }
  auto worklet = extractWorklet(serializable);
  if (!worklet) {
    return;
  }

  workletRuntime->schedule([worklet, arguments](jsi::Runtime &rt) {
    std::vector<jsi::Value> convertedArgs = expo::convertNSArrayToStdVector(rt, arguments);
    auto func = worklet->toJSValue(rt).asObject(rt).asFunction(rt);
    func.call(rt, (const jsi::Value *)convertedArgs.data(), convertedArgs.size());
  });
}

- (void)execute:(nonnull EXJavaScriptSerializable *)serializable
        runtime:(nonnull EXWorkletRuntime *)runtime
      arguments:(nonnull NSArray *)arguments
{
  auto workletRuntime = lockWorkletRuntime(runtime);
  if (!workletRuntime) {
    return;
  }
  auto worklet = extractWorklet(serializable);
  if (!worklet) {
    return;
  }

  workletRuntime->executeSync([worklet, arguments](jsi::Runtime &rt) -> jsi::Value {
    std::vector<jsi::Value> convertedArgs = expo::convertNSArrayToStdVector(rt, arguments);
    auto func = worklet->toJSValue(rt).asObject(rt).asFunction(rt);
    func.call(rt, (const jsi::Value *)convertedArgs.data(), convertedArgs.size());
    return jsi::Value::undefined();
  });
}

@end
