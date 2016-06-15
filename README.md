# geo-boundster

Tap on a map view to create a boundary area defined by two points with the tap point as the center.
This application uses Apple's MapKit to generate bounding boxes with latitude and longitude value pairs.
Bounding box coordinates are ordered as follows:
neLong, neLat, swLong, swLat. They are displayed in the navigation bar and made accessible via an Export function.
 Also, coordinates are saved to User Defaults so the map opens to the same location on next launch.
