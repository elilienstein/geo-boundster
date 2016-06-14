//
//  ViewController.m
//  Bounder
//
//  Created by Eric Lilienstein on 6/13/16.
//  Copyright © 2016 Eric Lilienstein. All rights reserved.
//

#import "ViewController.h"
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import <AddressBookUI/AddressBookUI.h>

#define STREET_MAX_SPAN .2
#define CITY_MAX_SPAN 10
#define STATE_MAX_SPAN 50
#define COUNTRY_MAX_SPAN 100

NSString * const kDefaultLatitude = @"savedUserLatitude";
NSString * const kDefaultLongitude = @"savedUserLongitude";
NSString * const kDefaultLatDelta = @"savedUserLatDelta";
NSString * const kDefaultLongDelta = @"savedUserLongDelta";


@interface ViewController () <MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet UITextField *coordinateDisplay;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;

@property (strong, nonatomic) NSArray *bounds;
@property (strong, nonatomic) NSString *addressString;
@property (nonatomic) MKCoordinateRegion myRegion;

@end

@implementation ViewController{
    double lats,longs,latDelta,longDelta;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];



lats = [defaults doubleForKey:kDefaultLatitude];
longs = [defaults doubleForKey:kDefaultLongitude];
latDelta = [defaults doubleForKey:kDefaultLatDelta];
longDelta = [defaults doubleForKey:kDefaultLongDelta];
CLLocationCoordinate2D mycoordinate = CLLocationCoordinate2DMake(lats, longs);
MKCoordinateSpan mySpan = MKCoordinateSpanMake(latDelta, longDelta);

MKCoordinateRegion myRegion = MKCoordinateRegionMake(mycoordinate, mySpan);

self.tapGestureRecognizer = [[UITapGestureRecognizer alloc]
                             initWithTarget:self
                             action:@selector(handleTaps:)];

//    self.tapGestureRecognizer.numberOfTapsRequired = 1;

[self.view addGestureRecognizer:self.tapGestureRecognizer];


self.mapView.mapType = MKMapTypeHybrid;

self.mapView.delegate = self;



static dispatch_once_t centerMapFirstTime;

if
((lats != 0.0) && (longs != 0.0)) {
    
    dispatch_once(&centerMapFirstTime, ^{
        [self.mapView setRegion:myRegion animated:NO];
        
    });
}

[self.view addSubview:self.mapView];

}



- (void) handleTaps:(UITapGestureRecognizer*)paramSender{
    
    CGPoint point = [self.tapGestureRecognizer locationInView:self.mapView];
    
    CLLocationCoordinate2D tapPoint = [self.mapView convertPoint:point toCoordinateFromView:self.view];
    
    
    //To calculate the search bounds...
    //First we need to calculate the corners of the map so we get the points
    
    //
    CGPoint nePoint = CGPointMake(self.mapView.bounds.origin.x + self.mapView.bounds.size.width, self.mapView.bounds.origin.y);
    CGPoint swPoint = CGPointMake((self.mapView.bounds.origin.x), (self.mapView.bounds.origin.y + self.mapView.bounds.size.height));
    
    //Then transform those points into lat,lng values
    CLLocationCoordinate2D neCoord;
    neCoord = [self.mapView convertPoint:nePoint toCoordinateFromView:self.mapView];
    
    CLLocationCoordinate2D swCoord;
    swCoord = [self.mapView convertPoint:swPoint toCoordinateFromView:self.mapView];
    
    //calculate the span's latitude and longitude deltas
    
    latDelta = tapPoint.latitude - swCoord.latitude;
    longDelta = tapPoint.longitude - swCoord.longitude;
    MKCoordinateSpan mySpan = MKCoordinateSpanMake(latDelta, longDelta);
    
    //Add the calculated data to a region object
    MKCoordinateRegion region =  {{tapPoint.latitude, tapPoint.longitude}, mySpan};
    
    neCoord.latitude  = tapPoint.latitude  + (region.span.latitudeDelta  / 2.0);
    neCoord.longitude = tapPoint.longitude - (region.span.longitudeDelta / 2.0);
    swCoord.latitude  = tapPoint.latitude  - (region.span.latitudeDelta  / 2.0);
    swCoord.longitude = tapPoint.longitude + (region.span.longitudeDelta / 2.0);
    
    NSString *neLat = [NSString stringWithFormat:@"%.8f", neCoord.latitude];
    NSString *neLong = [NSString stringWithFormat:@"%.8f", neCoord.longitude];
    NSString *swLat = [NSString stringWithFormat:@"%.8f", swCoord.latitude];
    NSString *swLong = [NSString stringWithFormat:@"%.8f", swCoord.longitude];
    
    
    _bounds = @[neLong, swLat, swLong, neLat];
    NSLog(@"%@",_bounds);
    
    [self setUserDefaultsWithLatitude:tapPoint.latitude longitude:tapPoint.longitude latitudeDelta:latDelta longitudeDelta:longDelta];
    
    
    
    CLLocation *location =   [[CLLocation alloc]initWithLatitude:tapPoint.latitude longitude:tapPoint.longitude];
    
    
    CLGeocoder *myGeoCoder = [[CLGeocoder alloc]init];
    
    [myGeoCoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        if (placemarks.count > 0 && error == nil){
            
            CLPlacemark *firstPlacemark = placemarks[0];
            
            NSString *address = [self makeAddressStringWithPlacemark:firstPlacemark andSpan:mySpan];
            
            //            if (mySpan.latitudeDelta < STREET_MAX_SPAN) {
            //                address = [addressDictionary objectForKey: (NSString *) kABPersonAddressStreetKey];
            //            }
            //
            //            else if (mySpan.latitudeDelta > STREET_MAX_SPAN && mySpan.latitudeDelta < CITY_MAX_SPAN)  {
            //                address = [addressDictionary objectForKey: (NSString *) kABPersonAddressCityKey];
            //            }
            //            else if (mySpan.latitudeDelta > CITY_MAX_SPAN && mySpan.latitudeDelta < STATE_MAX_SPAN) {
            //                address = [addressDictionary objectForKey: (NSString *) kABPersonAddressStateKey];
            //            }
            //            else {
            //                address = [addressDictionary objectForKey: (NSString *) kABPersonAddressCountryKey];
            //            }
            
            [self navigateToDetailVCWithBounds:_bounds address:address];
        }
        
        
    }];
    
    
}




-(void)setUserDefaultsWithLatitude:(double)latitude longitude:(double)longitude latitudeDelta:(double)dLatitude longitudeDelta:(double)dLongitude {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithDouble:latitude] forKey:kDefaultLatitude];
    [defaults setObject:[NSNumber numberWithDouble:longitude] forKey:kDefaultLongitude];
    [defaults setObject:[NSNumber numberWithDouble:dLatitude] forKey:kDefaultLatDelta];
    [defaults setObject:[NSNumber numberWithDouble:dLongitude] forKey:kDefaultLongDelta];
    
    [defaults synchronize];
}




- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSString *)makeAddressStringWithPlacemark:(CLPlacemark *)placemark andSpan:(MKCoordinateSpan)theSpan {
    NSString *address;
    NSDictionary *addressDictionary = placemark.addressDictionary;
    
    if (theSpan.latitudeDelta < STREET_MAX_SPAN) {
        address = [addressDictionary objectForKey: (NSString *) kABPersonAddressStreetKey];
    }
    else if (theSpan.latitudeDelta > STREET_MAX_SPAN && theSpan.latitudeDelta < CITY_MAX_SPAN)  {
        address = [addressDictionary objectForKey: (NSString *) kABPersonAddressCityKey];
    }
    else if (theSpan.latitudeDelta > CITY_MAX_SPAN && theSpan.latitudeDelta < STATE_MAX_SPAN) {
        address = [addressDictionary objectForKey: (NSString *) kABPersonAddressStateKey];
    }
    else {
        address = [addressDictionary objectForKey: (NSString *) kABPersonAddressCountryKey];
    }
    
    return address;
}

@end

@end
