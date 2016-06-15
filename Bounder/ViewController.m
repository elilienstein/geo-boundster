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
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;


@property (strong, nonatomic) NSString *coordinates;
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



self.mapView.mapType = MKMapTypeHybrid;

self.mapView.delegate = self;



static dispatch_once_t centerMapFirstTime;

if
((lats != 0.0) && (longs != 0.0)) {
    
    dispatch_once(&centerMapFirstTime, ^{
        [self.mapView setRegion:myRegion animated:NO];
        
    });
}


self.tapGestureRecognizer = [[UITapGestureRecognizer alloc]
                             initWithTarget:self
                             action:@selector(handleTaps:)];


[self.view addGestureRecognizer:self.tapGestureRecognizer];

}



- (void) handleTaps:(UITapGestureRecognizer*)paramSender{
    
   
    
    CGPoint point = [self.tapGestureRecognizer locationInView:self.mapView];
    
    CLLocationCoordinate2D tapPoint = [self.mapView convertPoint:point toCoordinateFromView:self.view];
    
    
    //To calculate the search bounds...
    //1. Find the corners of the map
    
    //
    CGPoint nePoint = CGPointMake(self.mapView.bounds.origin.x + self.mapView.bounds.size.width, self.mapView.bounds.origin.y);
    CGPoint swPoint = CGPointMake((self.mapView.bounds.origin.x), (self.mapView.bounds.origin.y + self.mapView.bounds.size.height));
    
    //2.Transform corner points into lat,lng values
    CLLocationCoordinate2D neCoord = [self.mapView convertPoint:nePoint toCoordinateFromView:self.mapView];
    
    CLLocationCoordinate2D swCoord = [self.mapView convertPoint:swPoint toCoordinateFromView:self.mapView];
    
    //3. calculate latitude and longitude deltas
    
    latDelta = tapPoint.latitude - swCoord.latitude;
    longDelta = tapPoint.longitude - swCoord.longitude;
    MKCoordinateSpan mySpan = MKCoordinateSpanMake(latDelta, longDelta);
    
    //4. Add the calculated data to a region object
    MKCoordinateRegion region =  {{tapPoint.latitude, tapPoint.longitude}, mySpan};
    
    neCoord.latitude  = tapPoint.latitude  + (region.span.latitudeDelta  / 2.0);
    neCoord.longitude = tapPoint.longitude - (region.span.longitudeDelta / 2.0);
    swCoord.latitude  = tapPoint.latitude  - (region.span.latitudeDelta  / 2.0);
    swCoord.longitude = tapPoint.longitude + (region.span.longitudeDelta / 2.0);
    
    NSString *neLat = [NSString stringWithFormat:@"%.4f", neCoord.latitude];
    NSString *neLong = [NSString stringWithFormat:@"%.4f", neCoord.longitude];
    NSString *swLat = [NSString stringWithFormat:@"%.4f", swCoord.latitude];
    NSString *swLong = [NSString stringWithFormat:@"%.4f", swCoord.longitude];
    
    
    
  
    
    [self setUserDefaultsWithLatitude:tapPoint.latitude longitude:tapPoint.longitude latitudeDelta:latDelta longitudeDelta:longDelta];
    
    NSString *neCoordinate =[neLong stringByAppendingString:@",  " ];
    NSString *firstPointCoordinate =[neCoordinate stringByAppendingString:neLat];

    NSString *formatedFirstPoint =[firstPointCoordinate stringByAppendingString:@",  " ];
    
    NSString *swCoordinate =[swLong stringByAppendingString:@",  "];
    NSString *secondPointCoordinate = [swCoordinate stringByAppendingString:swLat];
    self.coordinates = [formatedFirstPoint stringByAppendingString:secondPointCoordinate];
    

     self.navigationItem.title = self.coordinates;
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

