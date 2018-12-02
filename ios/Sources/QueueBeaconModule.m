//
//  QueueBeaconModule.m
//  WeexPluginTemp
//
//  Created by  on 17/3/14.
//  Copyright © 2017年 . All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "QueueBeaconModule.h"
#import <WeexPluginLoader/WeexPluginLoader.h>

@interface QueueBeaconModule()

@property (nonatomic, strong) WXKeepAliveCallback callback;
@property (nonatomic, strong) CLBeaconRegion *beaconRegion;
@property (nonatomic, strong) CLLocationManager *locationManager;

@end

@implementation QueueBeaconModule

WX_PlUGIN_EXPORT_MODULE(queueBeacon, QueueBeaconModule)
WX_EXPORT_METHOD(@selector(start::))
WX_EXPORT_METHOD(@selector(stop:))

- (NSString *)stringFromAuthorizationStatus:(CLAuthorizationStatus)status {
    switch (status) {
        case kCLAuthorizationStatusNotDetermined:
            return @"NotDetermined";
        case kCLAuthorizationStatusRestricted:
            return @"Restricted";
        case kCLAuthorizationStatusDenied:
            return @"Denied";
        case kCLAuthorizationStatusAuthorizedAlways:
            return @"AuthorizedAlways";
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            return @"WhenInUse";
    }
}

- (NSString *)stringFromProximity:(CLProximity)proximity {
    switch (proximity) {
        case CLProximityImmediate:
            return @"Immediate";
        case CLProximityNear:
            return @"Near";
        case CLProximityFar:
            return @"Far";
        case CLProximityUnknown:
            return @"Unknown";
    }
}

- (NSString *)stringFromRegionState:(CLRegionState)state {
    switch (state) {
        case CLRegionStateInside:
            return @"Inside";
        case CLRegionStateOutside:
            return @"Outside";
        case CLRegionStateUnknown:
            return @"Unknown";
    }
}

- (NSNumber *)wrapNumber:(NSNumber *)number {
    if (number) {
        return @(number.integerValue);
    } else {
        return @(-1);
    }
}

- (void)start :(NSDictionary *)params :(WXKeepAliveCallback)callback {
    NSLog(@"[QueueBeacon] module started");
    self.callback = callback;
    NSString *proximityUUID = params[@"proximityUUID"];
    NSString *identifier = params[@"identifier"];
    CLBeaconMajorValue major = [params[@"major"] integerValue];
    CLBeaconMinorValue minor = [params[@"minor"] integerValue];
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:proximityUUID];
    if (major != 0 || minor != 0) {
        self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid major:major minor:minor identifier:identifier];
    } else {
        self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:identifier];
    }
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    [self.locationManager requestAlwaysAuthorization];
    [self.locationManager startMonitoringForRegion:self.beaconRegion];
    [self.locationManager requestStateForRegion:self.beaconRegion];
    NSLog(@"[QueueBeacon] ranging started");
}

- (void)stop: (WXKeepAliveCallback)callback {
    self.callback = callback;
    [self.locationManager stopMonitoringForRegion:self.beaconRegion];
}

//- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
//    NSLog(@"[QueueBeacon] didUpdateLocations");
//    CLLocation *location = [locations lastObject];
//    CLLocationCoordinate2D coordinate = location.coordinate;
//    self.callback(@{
//        @"name": @"didUpdateLocations",
//        @"data": @{
//            @"latitude": @(coordinate.latitude),
//            @"longitude": @(coordinate.longitude),
//            @"speed": @(location.speed),
//            @"vertical_accuracy": @(location.verticalAccuracy),
//            @"horizontal_accuracy": @(location.horizontalAccuracy)
//        }
//    }, YES);
//}

//- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
//    NSLog(@"[QueueBeacon] didUpdateHeading");
//    self.callback(@{
//        @"name": @"didUpdateHeading",
//        @"data": @{
//            @"heading": @(newHeading.trueHeading)
//        }
//    }, YES);
//}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region {
    NSLog(@"[QueueBeacon] didDetermineState");
    switch (state) {
    case CLRegionStateInside:
        if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
            [self.locationManager startRangingBeaconsInRegion:self.beaconRegion];
        }
        break;
    case CLRegionStateOutside:
    case CLRegionStateUnknown:
    default:
        break;
    }
    self.callback(@{
            @"name": @"didDetermineState",
            @"data": @{
                @"identifier": region.identifier,
                @"state": [self stringFromRegionState:state]
            }
        }, YES);
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray<CLBeacon *> *)beacons inRegion:(CLBeaconRegion *)region {
    NSLog(@"[QueueBeacon] didRangeBeacons");
    NSMutableArray *beaconsArray = [NSMutableArray array];
    for (CLBeacon *beacon in beacons) {
        [beaconsArray addObject:@{
            @"proximityUUID": [beacon.proximityUUID UUIDString],
            @"major": [self wrapNumber:beacon.major],
            @"minor": [self wrapNumber:beacon.minor],
            @"proximity": [self stringFromProximity:beacon.proximity],
            @"accuracy": @(beacon.accuracy),
            @"rssi": @(beacon.rssi)
        }];
    }
    self.callback(@{
        @"name": @"didRangeBeacons",
        @"data": @{
            @"identifier": region.identifier,
            @"proximityUUID": [region.proximityUUID UUIDString],
            @"major": [self wrapNumber:region.major],
            @"minor": [self wrapNumber:region.minor],
            @"beacons": [beaconsArray copy]
        }
    }, YES);
}

//- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region
//              withError:(NSError *)error {
//    NSLog(@"[QueueBeacon] rangingBeaconsDidFailForRegion");
//    self.callback(@{
//        @"name": @"rangingBeaconsDidFailForRegion",
//        @"data": @{
//            @"identifier": region.identifier
//        }
//    }, YES);
//}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    NSLog(@"[QueueBeacon] didEnterRegion");
    [self.locationManager startRangingBeaconsInRegion:self.beaconRegion];
    self.callback(@{
        @"name": @"didEnterRegion",
        @"data": @{
            @"identifier": region.identifier
        }
    }, YES);
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    NSLog(@"[QueueBeacon] didExitRegion");
//    [self.locationManager stopRangingBeaconsInRegion:self.beaconRegion];
    self.callback(@{
        @"name": @"didExitRegion",
        @"data": @{
            @"identifier": region.identifier
        }
    }, YES);
}

//- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
//    NSLog(@"[QueueBeacon] didFailWithError");
//    switch (error.code) {
//        case kCLErrorDenied:
//            self.callback(@{
//                @"name": @"didFailWithError",
//                @"data": @{
//                    @"message": @"Denied"
//                }
//            }, YES);
//            break;
//        default:
//            self.callback(@{
//                @"name": @"didFailWithError",
//                @"data": @{
//                    @"message": @"Default"
//                }
//            }, YES);
//            break;
//    }
//}

//- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(nullable CLRegion *)region
//              withError:(NSError *)error {
//    NSLog(@"[QueueBeacon] monitoringDidFailForRegion");
//    self.callback(@{
//        @"name": @"monitoringDidFailForRegion",
//        @"data": @{
//            @"identifier": region.identifier
//        }
//    }, YES);
//}

//- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
//    NSLog(@"[QueueBeacon] didChangeAuthorizationStatus");
//    self.callback(@{
//        @"name": @"didChangeAuthorizationStatus",
//        @"data": @{
//            @"status": [self stringFromAuthorizationStatus:status]
//        }
//    }, YES);
//}

//- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region {
//    NSLog(@"[QueueBeacon] didStartMonitoringForRegion");
//    self.callback(@{
//        @"name": @"didStartMonitoringForRegion",
//        @"data": @{
//            @"identifier": region.identifier
//        }
//    }, YES);
//}

//- (void)locationManagerDidPauseLocationUpdates:(CLLocationManager *)manager {
//    NSLog(@"[QueueBeacon] didPauseLocationUpdates");
//    self.callback(@{
//        @"name": @"didPauseLocationUpdates",
//        @"data": @{}
//    }, YES);
//}

//- (void)locationManagerDidResumeLocationUpdates:(CLLocationManager *)manager {
//    NSLog(@"[QueueBeacon] didResumeLocationUpdates");
//    self.callback(@{
//        @"name": @"didResumeLocationUpdates",
//        @"data": @{}
//    }, YES);
//}

//- (void)locationManager:(CLLocationManager *)manager didFinishDeferredUpdatesWithError:(nullable NSError *)error {
//    NSLog(@"[QueueBeacon] didFinishDeferredUpdatesWithError");
//    self.callback(@{
//        @"name": @"didFinishDeferredUpdatesWithError",
//        @"data": @{}
//    }, YES);
//}

//- (void)locationManager:(CLLocationManager *)manager didVisit:(CLVisit *)visit {
//    NSLog(@"[QueueBeacon] didVisit");
//    CLLocationCoordinate2D coordinate = visit.coordinate;
//    NSDate *arrivalDate = visit.arrivalDate;
//    NSDate *departureDate = visit.departureDate;
//    self.callback(@{
//        @"name": @"didVisit",
//        @"data": @{
//            @"latitude": @(coordinate.latitude),
//            @"longitude": @(coordinate.longitude),
//            @"arrival": @(arrivalDate.timeIntervalSince1970),
//            @"departure": @(departureDate.timeIntervalSince1970)
//        }
//    }, YES);
//}

@end
