import 'package:flutter/material.dart';
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
  int counter = 1;

  void checkLocationPermission() async{
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("No location");
      }
    }
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
            onTap: (position){
              Marker newMarker = Marker(
                markerId: MarkerId("destination$counter"),
                position: position
              );
              setState(() {
                myMarkers.add(newMarker);
              });
              counter++;
            },
            markers: myMarkers,
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
          )
        ],
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: _goToTheLake,
      //   label: const Text('To the lake!'),
      //   icon: const Icon(Icons.directions_boat),
      // ),
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