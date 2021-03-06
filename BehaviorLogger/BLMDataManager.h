//
//  BLMDataManager.h
//  BehaviorLogger
//
//  Created by Steven Byrd on 1/6/16.
//  Copyright © 2016 3Bird. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BLMBehavior.h"
#import "BLMProject.h"
#import "BLMSession.h"
#import "BLMSessionConfiguration.h"


NS_ASSUME_NONNULL_BEGIN


extern NSString *const BLMDataManagerProjectErrorDomain;
extern NSString *const BLMDataManagerBehaviorErrorDomain;


#pragma mark

@interface BLMDataManager : NSObject

@property (nonatomic, assign, readonly, getter=isRestoringArchive) BOOL restoringArchive;

+ (void)initializeWithCompletion:(nullable dispatch_block_t)completion;
+ (instancetype)sharedManager;

@end


#pragma mark

@interface BLMDataManager (BLMProject)

@property (nonatomic, copy, readonly) NSSet<NSString *> *projectNameSet;

- (BLMProject *)projectForUUID:(NSUUID *)UUID;
- (NSEnumerator<BLMProject *> *)projectEnumerator;
- (void)createProjectWithName:(NSString *)name client:(NSString *)client sessionConfigurationUUID:(NSUUID *)sessionConfigurationUUID completion:(nullable void(^)(BLMProject *__nullable project, NSError *__nullable error))completion;
- (void)updateProjectForUUID:(NSUUID *)UUID property:(BLMProjectProperty)property value:(nullable id)value completion:(nullable void(^)(BLMProject *__nullable updatedProject, NSError *__nullable error))completion;
- (void)deleteProjectForUUID:(NSUUID *)UUID completion:(nullable void(^)(NSError *__nullable error))completion;

@end


#pragma mark

@interface BLMDataManager (BLMBehavior)

- (BLMBehavior *)behaviorForUUID:(NSUUID *)UUID;
- (NSEnumerator<BLMBehavior *> *)behaviorEnumerator;
- (void)createBehaviorWithName:(NSString *)name continuous:(BOOL)continuous completion:(nullable void(^)(BLMBehavior *__nullable behavior, NSError *__nullable error))completion;
- (void)updateBehaviorForUUID:(NSUUID *)UUID property:(BLMBehaviorProperty)property value:(nullable id)value completion:(nullable void(^)(BLMBehavior *__nullable updatedBehavior, NSError *__nullable error))completion;
- (void)deleteBehaviorForUUID:(NSUUID *)UUID completion:(void(^__nullable)(NSError *__nullable error))completion;

@end



#pragma mark

@interface BLMDataManager (BLMSession)

- (BLMSession *)sessionForUUID:(NSUUID *)UUID;
- (NSEnumerator<BLMSession *> *)sessionEnumerator;
- (void)createSessionWithName:(NSString *)name configurationUUID:(NSUUID *)configurationUUID completion:(nullable void(^)(BLMSession *__nullable session, NSError *__nullable error))completion;
- (void)updateSessionForUUID:(NSUUID *)UUID property:(BLMSessionProperty)property value:(nullable id)value completion:(nullable void(^)(BLMSession *__nullable updatedSession, NSError *__nullable error))completion;
- (void)deleteSessionForUUID:(NSUUID *)UUID completion:(nullable void(^)(NSError *__nullable error))completion;

@end


#pragma mark

@interface BLMDataManager (BLMSessionConfiguration)

- (BLMSessionConfiguration *)sessionConfigurationForUUID:(NSUUID *)UUID;
- (NSEnumerator<BLMSessionConfiguration *> *)sessionConfigurationEnumerator;
- (void)createSessionConfigurationWithCondition:(nullable NSString *)condition location:(nullable NSString *)location therapist:(nullable NSString *)therapist observer:(nullable NSString *)observer timeLimit:(BLMTimeInterval)timeLimit timeLimitOptions:(BLMTimeLimitOptions)timeLimitOptions behaviorUUIDs:(nullable NSOrderedSet<NSUUID *> *)behaviorUUIDs completion:(nullable void(^)(BLMSessionConfiguration *__nullable sessionConfiguration, NSError *__nullable error))completion;
- (void)updateSessionConfigurationForUUID:(NSUUID *)UUID property:(BLMSessionConfigurationProperty)property value:(nullable id)value completion:(nullable void(^)(BLMSessionConfiguration *__nullable updatedSessionConfiguration, NSError *__nullable error))completion;
- (void)deleteSessionConfigurationForUUID:(NSUUID *)UUID completion:(nullable void(^)(NSError *__nullable error))completion;

@end


#pragma mark

@interface NSEnumerator (BLMModelObjectEnumeration)

+ (NSEnumerator<BLMProject *> *)projectEnumeratorForUUIDs:(NSOrderedSet<NSUUID *> *)UUIDs dataManager:(BLMDataManager *)dataManager;
+ (NSEnumerator<BLMBehavior *> *)behaviorEnumeratorForUUIDs:(NSOrderedSet<NSUUID *> *)UUIDs dataManager:(BLMDataManager *)dataManager;
+ (NSEnumerator<BLMSessionConfiguration *> *)sessionConfigurationEnumeratorForUUIDs:(NSOrderedSet<NSUUID *> *)UUIDs dataManager:(BLMDataManager *)dataManager;

@end


NS_ASSUME_NONNULL_END
