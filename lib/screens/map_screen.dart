import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _controller;
  bool isNormal = true;
  Set<Marker> myMarkers = {};
  Set<Polyline> myPolylines = {};
  int counter = 1;
  LatLng? selectedPosition;
  String apiKey = "AIzaSyAsgg8XAEz9Ixd0eTdE2WrUIcKTuclB9Z8";

  void checkLocationPermission() async{
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("No location");
      }
    }
  }

  Future< List<LatLng> > getAllPoints(LatLng start, LatLng end) async{
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      apiKey, 
      PointLatLng(start.latitude, start.longitude),
      PointLatLng(end.latitude, end.longitude),
    );
    List<LatLng> myPoints = [];
    for(var point in result.points){
      myPoints.add( LatLng(point.latitude, point.longitude) );
    }
    return myPoints;
  }

  Future<LatLng?> getDirectionByName(String start, String end) async{ // mall of arab
    String convertedStart = start.toLowerCase().trim().replaceAll(" ", "%20");
    String convertedEnd = end.toLowerCase().trim().replaceAll(" ", "%20");
    Dio dio = Dio();
    var response = await dio.get("https://maps.googleapis.com/maps/api/directions/json?origin=$convertedStart&destination=$convertedEnd&key=$apiKey");
    if(response.statusCode! >= 200 && response.statusCode! < 300){
      Map<String,dynamic> data = response.data;
      double startLat = data["routes"][0]["legs"][0]["start_location"]["lat"];
      double startLng = data["routes"][0]["legs"][0]["start_location"]["lng"];
      double endLat = data["routes"][0]["legs"][0]["end_location"]["lat"];
      double endLng = data["routes"][0]["legs"][0]["end_location"]["lng"];
      List<LatLng> myPoints = await getAllPoints(LatLng(startLat, startLng), LatLng(endLat, endLng));
      Marker startMarker = Marker(
        markerId: MarkerId("start"),
        position: LatLng(startLat, startLng),
      );
      Marker endMarker = Marker(
        markerId: MarkerId("end"),
        position: LatLng(endLat, endLng),
      );
      Polyline directions = Polyline(
        polylineId: PolylineId("direction"),
        width: 3,
        color: Colors.red,
        points: myPoints,
      );
      setState(() {
        //myMarkers.add(startMarker);
        //myMarkers.add(endMarker);
        myMarkers..add(startMarker)..add(endMarker);
        myPolylines.add(directions);
      });
      int middleIndex = myPoints.length ~/ 2;
      return LatLng(myPoints[middleIndex].latitude, myPoints[middleIndex].longitude);
    }
    return null;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkLocationPermission();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onCameraMove: (cameraPosition){
              selectedPosition = cameraPosition.target;
            },
            onCameraIdle: (){
              print("my current position is $selectedPosition");
            },
            onTap: (position) async{
              Marker newMarker = Marker(
                markerId: MarkerId("destination"),
                position: position
              );
              Position myPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
              List<LatLng> myPoints = await getAllPoints(LatLng(myPosition.latitude, myPosition.longitude), position);
              Polyline newPolyline = Polyline(
                polylineId: PolylineId("my route"),
                width: 3,
                color: Colors.black,
                points: myPoints,
              );

              setState(() {
                myMarkers.add(newMarker);
                myPolylines.add(newPolyline);
              });
              counter++;
            },
            markers: myMarkers,
            polylines: myPolylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            mapType: isNormal ? MapType.normal : MapType.satellite,
            initialCameraPosition: CameraPosition(
              target: LatLng(37.62796133580664, -122.285749655962),
              zoom: 14.4746,
            ),
            onMapCreated: (GoogleMapController controller) async{
              _controller = controller;
              Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
              _controller.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: LatLng(position.latitude, position.longitude),
                    zoom: 12,
                  ),
                )
              );
            },
          ),
          Positioned(
            left: 10,
            top: 10,
            child: SafeArea(
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(50),
                child: CircleAvatar(
                  child: IconButton(
                    onPressed: (){
                      setState(() {
                        isNormal = !isNormal;
                      });
                    }, 
                    icon: Icon(Icons.swap_horiz_outlined),
                  ),
                ),
              ),
            ),
          ),
          // Align(
          //   alignment: Alignment.center,
          //   child: Padding(
          //     padding: const EdgeInsets.only(bottom: 30),
          //     child: Icon(Icons.location_on, color: Colors.black, size: 40,),
          //   ),
          // ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async{
          LatLng? point = await getDirectionByName("grand mall", "tahrir");
          if(point != null){
            _controller.animateCamera(CameraUpdate.newCameraPosition(
              CameraPosition(
                target: point,
                zoom: 10,
              )
            ));
          }
        },
        label: const Text('Get direction'),
        icon: const Icon(Icons.directions),
      ),
    );
  }

  Future<void> _goToTheLake() async {
    await _controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        bearing: 192.8334901395799,
        target: LatLng(37.43296265331129, -122.08832357078792),
        tilt: 59.440717697143555,
        zoom: 19.151926040649414)
    ));
  }
}