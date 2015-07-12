//
//  DLLocationManager.h
//  
//
//  Created by XueYulun on 15/7/10.
//
//

///----------------------------------
///  @name 位置管理
///----------------------------------

/*
 1. NSLocationAlwaysUsageDescription
 2. NSLocationWhenInUseUsageDescription
 */

//! @name 参考文献: http://blog.csdn.net/weisubao/article/details/43205229 大头针的自定义, 划线.

typedef NS_ENUM(NSInteger, DLLocationReques) {
    
    DLLocationReques_Always = 1UL << 0,
    DLLocationReques_WhenUse = 2UL << 1
};

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

typedef void(^didUpdateLocation)(CLLocation * location, NSError * error);
typedef void(^didGeocodeLocation)(NSDictionary * addressInfoDict, NSError * error);
typedef void(^didGeocodeAddress)(CLPlacemark * placeMark, NSError * error);

@interface DLLocationManager : NSObject <CLLocationManagerDelegate>

@prop_strong(CLLocationManager *, locationManager); // 定位器
@prop_strong(CLGeocoder *, geocoder);               // 解码器
@prop_strong(CLPlacemark *, placemark);             // 最近的一次解码结果

@singleton(DLLocationManager);

- (void)UpdateLocationWithAccuracy: (CLLocationAccuracy)accuracy Update:(DLLocationReques)requestType CompleteBlock: (didUpdateLocation)locationBlock;

// CLLocation对象 - 具体定位信息字典
- (void)GeocodeWithLocation: (CLLocation *)Location CompleteBlock: (didGeocodeLocation)geocodeBlock;

// NSString位置 - CLPlacemark, 可用于添加大头针, 计算线路, 划线等. 一次只能对一个位置进行编码。
- (void)GeocodeAddressString: (NSString *)Place CompleteBlock: (didGeocodeAddress)geocodeBlock;
- (void)GeocodeAddressString:(NSString *)Place WithRegion:(CLRegion *)region CompleteBlock:(didGeocodeAddress)geocodeBlock;

// 2点之间的线路, 并且划线
- (void)MapView: (MKMapView *)mapView AddLineFrom: (CLPlacemark *)From to: (CLPlacemark *)To;

@end
