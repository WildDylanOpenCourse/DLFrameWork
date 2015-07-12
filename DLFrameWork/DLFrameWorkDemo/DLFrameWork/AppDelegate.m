//
//  AppDelegate.m
//  DLFrameWork
//
//  Created by XueYulun on 15/6/25.
//  Copyright (c) 2015年 __Dylan. All rights reserved.
//

#import "AppDelegate.h"

@interface DLTestModel : DLModel

@prop_strong(NSString * , name);
@prop_strong(NSDictionary *, info);
@prop_strong(UIColor *, color);

@end

@implementation DLTestModel

+ (DLKeyMapper *)keyMapper {
    
    return [[DLKeyMapper alloc] initWithDictionary:@{
                                                     @"name" : @"server_name",
                                                     @"info" : @"Server_info",
                                                     @"color": @"Server_color"
                                                     }];
}

- (instancetype)initWithDictionary:(NSDictionary *)dict error:(NSError *__autoreleasing *)err {
    
    self = [super initWithDictionary:dict error:err];
    if (self) {
        
    }
    
    return self;
}

@end

@interface AppDelegate () <DLFramePingerDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    DLTestModel * testModel = [[DLTestModel alloc] init];
    
    
    DLBind(self.window, backgroundColor) = DLGun(testModel, color);
    
    testModel.color = [UIColor orangeColor];
    
    
    UILabel * testLabel = [[UILabel alloc] initWithFrame:CGRectMake(100, 100, 100, 100)];
    testLabel.backgroundColor = [UIColor blackColor];
    [self.window addSubview:testLabel];
    
    UITextField * text = [[UITextField alloc] initWithFrame:CGRectMake(100, 300, 100, 30)];
    text.backgroundColor = [UIColor cyanColor];
    [self.window addSubview:text];
    
    DLBind(testLabel, text) = DLGun(text, text);
    
    [testLabel mas_makeConstraints:^(MASConstraintMaker *make) {
       
        make.left.equalTo(self.window.mas_left).with.offset(10);
        make.top.equalTo(self.window.mas_top).with.offset(10);
        make.size.mas_equalTo(CGSizeMake(100, 100));
    }];
    
    [[DLFrameManager sharedInstance] HandleWindowTouch];
    
//    DLTestModel * testModel_1 = [[DLTestModel alloc] init];
    
//    DLBind(testLabel, text) = DLGun(testModel_1, name);
    
//    testModel_1.name = @"Dylan";
    
    
    
//    // DLFramework Test, UI相关的都是简单的扩展以及控件, 没有多写。 这里多测试功能
//    
//    [[DLFrameManager sharedInstance] SetLogEnabled:YES];            // @ 打开调试输出
//    
//    DLogOut(@"DLogTest: - Log Normal");
//    
//    [[DLFrameManager sharedInstance] RegisterRemoteNotification];
//    
//    if ([DLFrameManager sharedInstance].NowFirstLaunch == NO) {
//        
//        DLError * error = [DLError errorWithMessage:@"第一次使用`DLFrameWork`进行软件开发" Code:9999];
//        DLogOut(@"%@", [error descriptions]);
////        [error showErrorAlert];
//        
//        // $ 抛出异常
//        
////        [DLError throwExceptionWithName:@"Exception" reason:@"Reson: First Launch this Application." userInfo:@{@"user_name":"Dylan"}];
//        
//        // $ 做什么...
//        [[DLFrameManager sharedInstance] SetLaunchStatu:YES]; // @ 可以主动设置下次是什么状态
//    }
////    [[DLFrameManager sharedInstance] SetPingWithDelegate:self];
////    [[DLFrameManager sharedInstance] PingWith:@"www.baidu.com"];
//    
//    // $ 播放系统声音
//    
////    [DLSystemSound playSystemSound:AudioIDLock];
//    
//    // $ 调起TouchID
//    
////    [DLTouchID showTouchIDAuthenticationWithReason:@"Dylan想要请求您的TouchID信息" completion:^(TouchIDResult result) {
////        
////    }];
//    
//    // $ 硬件信息
//    
//    DLogOut(@"\n - %@\n - %@(Mac地址)\n - %@(FreeDisk)\n - %@(TotalDisk)\n", [UIDeviceUtil hardwareDescription], [DLExtension macAddress], [DLExtension freeDiskSpace], [DLExtension totalDiskSpace]);
//    
//    // $ 普通网络请求
//    
    @weakify(self);
    [[DLFrameHttpEngin sharedClient] GET:@"" parameters:@{} completion:^(id response, NSHTTPURLResponse *urlResponse, NSError *error) {
    
        @strongify(self);
        self.window.backgroundColor = [UIColor greenColor];
    }];
//
//    // $ 方便处理的网络请求
//    
//    [DLAPI setAPIBaseURLWithString:@"baidu.com"];
//    
////    [DLAPI getWithPath:@"" andParams:@{} completion:^(id json, DLModelError *err) {
////        
////    }];
//    
////    [DLHTTPClient getJSONFromURLWithString:@"" completion:^(id json, DLModelError *err) {
////        
////    }];
//    
////    [DLTestModel getModelFromURLWithString:@"" completion:^(id model, DLModelError *err) {
////        
////    }];
//    
//    // $ 模型需要继承DLModel, 实现KeyMapper
//    
//    DLTestModel * testModel = [[DLTestModel alloc] init];
//    
//    // $ 运行时的一个小用法, 后边有更强大的
//    
//    [testModel getAssociatedObjectForKey:"name"];
//    
//    // $ DLModel 不说了, 关于Model处理的一些东西, 更改了JSONModel, 但用法没有太多的变化
//    
//    // $ DLFrame_Runtime 运行时库
//    
//    // $ DLSignal 信号库 - 玩一下, 让self.window与color绑定, 让Label与name绑定
//    
//    UILabel * nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(100, 100, 200, 20)];
//    nameLabel.textColor = RGB(27, 122, 199);
//    [self.window addSubview:nameLabel];
//    
////    DLBind(self.window, backgroundColor) = DLGun(testModel, color);
////    testModel.color = [UIColor orangeColor];
//    
//    DLTestModel * nameModel = [[DLTestModel alloc] init];
//    
//    DLBind(nameLabel, text) = DLGun(nameModel, name);
//    nameModel.name = @"你好Dylan";
//    
//    // $ 线程
//    
//    dispatch_async_background(^{
//    
//        DLogError(@"走错地方了...");  // @ 在DLFrame_Thread里边, 自己玩吧
//    });
//    
//    // $ 配置
//    
    // $ 获取位置并对位置进行解码
    [[DLLocationManager sharedInstance] UpdateLocationWithAccuracy:kCLLocationAccuracyBestForNavigation Update:DLLocationReques_Always CompleteBlock:^(CLLocation *location, NSError *error) {
    
        if (!error) {
            
            [[DLLocationManager sharedInstance] GeocodeWithLocation:location CompleteBlock:^(NSDictionary *addressInfoDict, NSError *error) {
                
                if (!error) {
                    
                    DLogOut(@"%@", addressInfoDict);
                    
                } else {
                    
                    [[DLError errorWithMessage:[error localizedDescription] Code:9900] showErrorAlert];
                }
            }];
        } else {
            
            [[DLError errorWithMessage:[error localizedDescription] Code:9911] showErrorAlert];
        }
    }];
    
    return YES;
}

// @ 对PushToken做一点操作

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    
    NSString * token = [[DLFrameManager sharedInstance] DeviceToken:deviceToken];
    NSLog(@"%@ \n FrameSaved Your Token: %@", token, [DLFrameManager sharedInstance].DeviceToken);
}

// @ 收到了ping的信息

- (void)pinger:(DLFramePinger *)pinger didUpdateWithAverageSeconds:(NSTimeInterval)seconds {
    
    DLogOut(@"ping, %f", seconds);
}






























- (void)applicationWillTerminate:(UIApplication *)application {
    
    [self saveContext];
}

#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {

    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {

    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"DLFrameWork" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {

    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"DLFrameWork.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];

        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext {

    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {

            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

@end
