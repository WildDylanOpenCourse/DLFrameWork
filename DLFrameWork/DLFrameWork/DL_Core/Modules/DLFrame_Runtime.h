//
//  DLFrame_Runtime.h
//  
//
//  Created by XueYulun on 15/6/25.
//
//

///----------------------------------
///  @name 运行时一些需要的方法
///----------------------------------

@interface NSObject(Runtime)

/*!
 *  所有的子类
 */
+ (NSArray *)subClasses;

/*!
 *  方法数组(方法名称)
 *
 */
+ (NSArray *)methods;
+ (NSArray *)methodsWithPrefix:(NSString *)prefix;

/*!
 *  替换方法
 */
+ (void *)replaceSelector:(SEL)sel1 withSelector:(SEL)sel2;

/*!
 *  属性字典 {"属性名称" : id(属性对象)}
 */
- (NSDictionary *)classAttributes;

@end
