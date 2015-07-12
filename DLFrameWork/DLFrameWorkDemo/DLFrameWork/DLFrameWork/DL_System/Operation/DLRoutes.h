
///----------------------------------
///  @name 应用路由
///----------------------------------

// @ 使用

/*
 在应用1中添加用于响应OpenUrl的Route
 [DLRoutes addRoute:@"/:object/:action/:primaryKey" handler:^BOOL(NSDictionary *parameters) {
 
    NSString *object = parameters[@"object"];
    NSString *action = parameters[@"action"];
    NSString *primaryKey = parameters[@"primaryKey"];
    return YES;
 }];
 
 在应用2中OpenUrl方式请求并传输数据
 NSURL * editPost = [NSURL URLWithString:@"appScheme://post/edit/123?debug=true&foo=bar"];
 [[UIApplication sharedApplication] openURL:editPost];
 
 这样在应用1中接收到的数据应该是
 
 {
    "object": "post",
    "action": "edit",
    "primaryKey": "123",
    "debug": "true",
    "foo": "bar",
    "JLRouteURL": "myapp://post/edit/123?debug=true&foo=bar",
    "JLRoutePattern": "/:object/:action/:primaryKey",
    "JLRouteNamespace": "JLRoutesGlobalNamespace"
 }
 
 进而得到我们需要在应用之间传输的数据
 
 何处使用:
 - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
 // ...
 [DLRoutes addRoute:@"/user/view/:userID" handler:^BOOL(NSDictionary *parameters) {
 
    NSString *userID = parameters[@"userID"];
 
    // present UI for viewing user with ID 'userID'
    return YES; // return YES to say we have handled the route
 }];
 
 // ...
    return YES;
 }
 
 - (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
 
    return [DLRoutes routeURL:url];
 }
 */

#import <Foundation/Foundation.h>

static NSString *const kDLRoutePatternKey = @"DLRoutePattern";
static NSString *const kDLRouteURLKey = @"DLRouteURL";
static NSString *const kDLRouteNamespaceKey = @"DLRouteNamespace";
static NSString *const kDLRouteWildcardComponentsKey = @"DLRouteWildcardComponents";
static NSString *const kDLRoutesGlobalNamespaceKey = @"DLRoutesGlobalNamespace";


@interface DLRoutes : NSObject

/** @class DLRoutes
 DLRoutes is a way to manage URL routes and invoke them from a URL.
 */

/// Returns the global routing namespace (this is used by the +addRoute methods by default)
+ (instancetype)globalRoutes;

/// Returns a routing namespace for the given scheme
+ (instancetype)routesForScheme:(NSString *)scheme;

/// Tells DLRoutes that it should manually replace '+' in parsed values to ' '. Defaults to YES.
+ (void)setShouldDecodePlusSymbols:(BOOL)shouldDeecode;
+ (BOOL)shouldDecodePlusSymbols;

/// Registers a routePattern with default priority (0) in the receiving scheme namespace.
+ (void)addRoute:(NSString *)routePattern handler:(BOOL (^)(NSDictionary *parameters))handlerBlock;
- (void)addRoute:(NSString *)routePattern handler:(BOOL (^)(NSDictionary *parameters))handlerBlock; // instance method

/// Removes a routePattern from the receiving scheme namespace.
+ (void)removeRoute:(NSString *)routePattern;
- (void)removeRoute:(NSString *)routePattern; // instance method

/// Removes all routes from the receiving scheme namespace.
+ (void)removeAllRoutes;
- (void)removeAllRoutes; // instance method

/// Unregister and delete an entire scheme namespace
+ (void)unregisterRouteScheme:(NSString *)scheme;

/// Registers a routePattern with default priority (0) using dictionary-style subscripting.
- (void)setObject:(id)handlerBlock forKeyedSubscript:(NSString *)routePatten;

/// Registers a routePattern in the global scheme namespace with a handlerBlock to call when the route pattern is matched by a URL.
/// The block returns a BOOL representing if the handlerBlock actually handled the route or not. If
/// a block returns NO, DLRoutes will continue trying to find a matching route.
+ (void)addRoute:(NSString *)routePattern priority:(NSUInteger)priority handler:(BOOL (^)(NSDictionary *parameters))handlerBlock;
- (void)addRoute:(NSString *)routePattern priority:(NSUInteger)priority handler:(BOOL (^)(NSDictionary *parameters))handlerBlock; // instance method

/// Routes a URL, calling handler blocks (for patterns that match URL) until one returns YES, optionally specifying add'l parameters
+ (BOOL)routeURL:(NSURL *)URL;
+ (BOOL)routeURL:(NSURL *)URL withParameters:(NSDictionary *)parameters;

- (BOOL)routeURL:(NSURL *)URL; // instance method
- (BOOL)routeURL:(NSURL *)URL withParameters:(NSDictionary *)parameters; // instance method

/// Returns whether a route exists for a URL
+ (BOOL)canRouteURL:(NSURL *)URL;
+ (BOOL)canRouteURL:(NSURL *)URL withParameters:(NSDictionary *)parameters;

- (BOOL)canRouteURL:(NSURL *)URL; // instance method
- (BOOL)canRouteURL:(NSURL *)URL withParameters:(NSDictionary *)parameters; // instance method

/// Prints the entire routing table
+ (NSString *)description;

/// Allows configuration of verbose logging. Default is NO. This is mostly just helpful with debugging.
+ (void)setVerboseLoggingEnabled:(BOOL)loggingEnabled;
+ (BOOL)isVerboseLoggingEnabled;

/// Controls whether or not this routes controller will try to match a URL with global routes if it can't be matched in the current namespace. Default is NO.
@property (nonatomic, assign) BOOL shouldFallbackToGlobalRoutes;

/// Called any time routeURL returns NO. Respects shouldFallbackToGlobalRoutes.
@property (nonatomic, copy) void (^unmatchedURLHandler)(DLRoutes *routes, NSURL *URL, NSDictionary *parameters);

@end
