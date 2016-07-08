//
//  ViewController.m
//  GeoBoundster
//
//  Created by Eric Lilienstein on 6/13/16.
//  Copyright © 2016 Eric Lilienstein. All rights reserved.
//

#import "ViewController.h"
#import <MapKit/MapKit.h>



NSString * const kDefaultLatitude = @"savedUserLatitude";
NSString * const kDefaultLongitude = @"savedUserLongitude";
NSString * const kDefaultLatDelta = @"savedUserLatDelta";
NSString * const kDefaultLongDelta = @"savedUserLongDelta";

@interface ViewController () <MKMapViewDelegate>


@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) NSString *coordinates;

@end

@implementation ViewController{
    double lats,longs,latDelta,longDelta;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

   
NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

self.navigationItem.title = @"Select quadrant, then export coordinates";

lats = [defaults doubleForKey:kDefaultLatitude];
longs = [defaults doubleForKey:kDefaultLongitude];
latDelta = [defaults doubleForKey:kDefaultLatDelta];
longDelta = [defaults doubleForKey:kDefaultLongDelta];
    
CLLocationCoordinate2D mycoordinate = CLLocationCoordinate2DMake(lats, longs);
    MKCoordinateSpan mySpan = MKCoordinateSpanMake(latDelta, longDelta);
    
    MKCoordinateRegion myRegion = MKCoordinateRegionMake(mycoordinate, mySpan);

self.mapView.mapType = MKMapTypeHybrid;

self.mapView.delegate = self;



static dispatch_once_t centerMapFirstTime;

if
((lats != 0.0) && (longs != 0.0)) {
    
    dispatch_once(&centerMapFirstTime, ^{
          [self.mapView setRegion:myRegion animated:YES];
        
        
    });
}


}



- (void) mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
   
    

    //1. Find the corners of the map


    CGPoint nePoint = CGPointMake(self.mapView.bounds.origin.x + self.mapView.bounds.size.width, self.mapView.bounds.origin.y);
    CGPoint swPoint = CGPointMake((self.mapView.bounds.origin.x), (self.mapView.bounds.origin.y + self.mapView.bounds.size.height));
    
   
    //2.Transform corner points into lat,lng values
    CLLocationCoordinate2D neCoord = [self.mapView convertPoint:nePoint toCoordinateFromView:self.mapView];
    
    CLLocationCoordinate2D swCoord = [self.mapView convertPoint:swPoint toCoordinateFromView:self.mapView];
    
    NSString *neLat = [[NSString stringWithFormat:@"%.7f", neCoord.latitude]stringByAppendingString:@"N"];
    NSString *neLong = [[NSString stringWithFormat:@"%.7f", neCoord.longitude]stringByAppendingString:@"E / "];
    NSString *swLat = [[NSString stringWithFormat:@"%.7f", swCoord.latitude]stringByAppendingString:@"S"];
    NSString *swLong = [[NSString stringWithFormat:@"%.7f", swCoord.longitude]stringByAppendingString:@"W"];
    
    NSArray *arrayOfNEStrings = @[neLat, neLong];
    NSArray *arrayOfSWStrings = @[swLat, swLong];
    
   CLLocationCoordinate2D centerCoord = self.mapView.centerCoordinate;
    //calculate the span's latitude and longitude deltas
    
    latDelta = centerCoord.latitude - swCoord.latitude;
    longDelta = centerCoord.longitude - swCoord.longitude;
    MKCoordinateSpan mySpan = MKCoordinateSpanMake(latDelta, longDelta);
    
    //Add the calculated data to a region object
    MKCoordinateRegion region =  {{centerCoord.latitude, centerCoord.longitude}, mySpan};
    
    neCoord.latitude  = centerCoord.latitude  + (region.span.latitudeDelta  / 2.0);
    neCoord.longitude = centerCoord.longitude - (region.span.longitudeDelta / 2.0);
    swCoord.latitude  = centerCoord.latitude  - (region.span.latitudeDelta  / 2.0);
    swCoord.longitude = centerCoord.longitude + (region.span.longitudeDelta / 2.0);
     [self setUserDefaultsWithLatitude:centerCoord.latitude longitude:centerCoord.longitude latitudeDelta:latDelta longitudeDelta:longDelta];
    
   NSString *NEcoordinates = [arrayOfNEStrings componentsJoinedByString:@", "];
   NSString *SWcoordinates = [arrayOfSWStrings componentsJoinedByString:@", "];
    self.coordinates = [NEcoordinates stringByAppendingString:SWcoordinates];
    self.navigationItem.title = [NSString stringWithFormat:@"%@", self.coordinates];
    [self showButton];
}

-(void)showButton {
    if (self.coordinates != nil){
        UIBarButtonItem *anotherButton = [[UIBarButtonItem alloc] initWithTitle:@"Export" style:UIBarButtonItemStylePlain target:self action:@selector(export)];
    self.navigationItem.rightBarButtonItem = anotherButton;
    }
}

 -(void)export {
    
 UIActivityViewController *activityViewController =
 [[UIActivityViewController alloc] initWithActivityItems:@[self.coordinates]
 applicationActivities:nil];
 
 if ( [activityViewController respondsToSelector:@selector(popoverPresentationController)] ) {
 // iOS8
 activityViewController.popoverPresentationController.sourceView =
 self.view;
 }
 [self presentViewController:activityViewController
 animated:YES
 completion:^{
 // ...
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

@end

