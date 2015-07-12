//
//  DLLocationManager.m
//  
//
//  Created by XueYulun on 15/7/10.
//
//

#import "DLLocationManager.h"

@interface DLLocationManager ()

@prop_copy(didUpdateLocation, locationBlock);

@end

@implementation DLLocationManager

@def_singleton(DLLocationManager);

- (void)UpdateLocationWithAccuracy: (CLLocationAccuracy)accuracy Update:(DLLocationReques)requestType CompleteBlock: (didUpdateLocation)locationBlock {
    
    self.locationBlock = locationBlock;
    self.locationManager.desiredAccuracy = accuracy;
    // iOS 8.0
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        
        BOOL hasAlwaysKey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationAlwaysUsageDescription"] != nil;
        BOOL hasWhenInUseKey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationWhenInUseUsageDescription"] != nil;
        requestType == DLLocationReques_Always ? [self.locationManager requestAlwaysAuthorization] : [self.locationManager requestWhenInUseAuthorization];
        
        if (!hasAlwaysKey && !hasWhenInUseKey) {
            
            NSAssert(hasAlwaysKey || hasWhenInUseKey, @"在iOS 8.0 之后使用定位, 首先在INFO.plist文件中加入下面2项中的一项 NSLocationWhenInUseUsageDescription, NSLocationAlwaysUsageDescription.");
        }
    }
    [self.locationManager startUpdatingLocation];
}

- (void)GeocodeWithLocation: (CLLocation *)Location CompleteBlock: (didGeocodeLocation)geocodeBlock {
    
    @weakify(self);
    [self.geocoder reverseGeocodeLocation:Location completionHandler:^(NSArray *placemarks, NSError *error) {
     
        @strongify(self);
        
        if (!error) {
            
            self.placemark = [placemarks firstObject];
            geocodeBlock(((CLPlacemark *)[placemarks firstObject]).addressDictionary, nil);
        } else {
            
            geocodeBlock(nil, error);
        }
    }];
}

- (void)GeocodeAddressString: (NSString *)Place CompleteBlock: (didGeocodeAddress)geocodeBlock {
    
    @weakify(self);
    [self.geocoder geocodeAddressString:Place completionHandler:^(NSArray *placemarks, NSError *error) {
       
        @strongify(self);
        self.placemark = [placemarks firstObject];
        geocodeBlock([placemarks firstObject], error);
    }];
}

- (void)GeocodeAddressString:(NSString *)Place WithRegion:(CLRegion *)region CompleteBlock:(didGeocodeAddress)geocodeBlock {
    
    @weakify(self);
    [self.geocoder geocodeAddressString:Place inRegion:region completionHandler:^(NSArray *placemarks, NSError *error) {
        
        @strongify(self);
        self.placemark = [placemarks firstObject];
        geocodeBlock([placemarks firstObject], error);
    }];
}

- (void)MapView: (MKMapView *)mapView AddLineFrom: (CLPlacemark *)From to: (CLPlacemark *)To {
    
    // 设置方向请求
    MKDirectionsRequest * request = [[MKDirectionsRequest alloc] init];
    // 设置起点终点
    
    MKPlacemark * sourcePm = [[MKPlacemark alloc] initWithPlacemark:From];
    request.source = [[MKMapItem alloc] initWithPlacemark:sourcePm];
    MKPlacemark * destiPm = [[MKPlacemark alloc] initWithPlacemark:To];
    request.destination = [[MKMapItem alloc] initWithPlacemark:destiPm];
    
    //定义方向对象
    MKDirections * dirs = [[MKDirections alloc] initWithRequest:request];
    
    //计算路线
    [dirs calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
        
        DLogOut(@"总共有%lu条线路",(unsigned long)response.routes.count);
        
        for (MKRoute *route in response.routes) {
            
            [mapView addOverlay:route.polyline];
        }
    }];
    
    /* 划线以及颜色
     -(MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay{
     
        MKPolylineRenderer * renderer = [[MKPolylineRenderer alloc] initWithOverlay:overlay];
        renderer.strokeColor = [UIColor redColor];
        return renderer;
     }
     */
}

- (CLLocationManager *)locationManager {
    
    if (!_locationManager) {
        
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationManager.distanceFilter = 10; // 默认的定位服务更新频率, 米
    }
    
    return _locationManager;
}

- (CLGeocoder *)geocoder {
    
    if (!_geocoder) {
        
        _geocoder = [[CLGeocoder alloc] init];
    }
    
    return _geocoder;
}

#pragma mark - 
#pragma mark Location Did Update

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    
    CLLocation * currentLocation = [locations lastObject];
    if (self.locationBlock) {
        
        self.locationBlock(currentLocation, nil);
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    
    if (self.locationBlock) {
        
        self.locationBlock(nil, error);
    }
}

@end
