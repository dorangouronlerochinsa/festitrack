import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapWidget extends StatefulWidget {
  final String? eventId;

  MapWidget({this.eventId});

  @override
  _MapWidgetState createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  GoogleMapController? _controller;
  Position? _currentPosition;
  bool _locationPermissionDenied = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Vérifie si le service de localisation est activé
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _locationPermissionDenied = true;
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _locationPermissionDenied = true;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _locationPermissionDenied = true;
      });
      return;
    }

    _currentPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: widget.eventId != null
          ? FirebaseFirestore.instance
              .collection('events')
              .doc(widget.eventId)
              .get()
          : Future.value(null),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error loading event data"));
        } else if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(child: Text("Event not found"));
        } else {
          var event = snapshot.data!.data() as Map<String, dynamic>;
          //var eventLocation = LatLng(event['latitude'], event['longitude']);
          var eventLocation = LatLng(12, 34);

          return _currentPosition == null && !_locationPermissionDenied
              ? Center(child: CircularProgressIndicator())
              : GoogleMap(
                  onMapCreated: (controller) => _controller = controller,
                  initialCameraPosition:
                      _locationPermissionDenied || _currentPosition == null
                          ? CameraPosition(
                              target: eventLocation,
                              zoom: 15,
                            )
                          : CameraPosition(
                              target: LatLng(_currentPosition!.latitude,
                                  _currentPosition!.longitude),
                              zoom: 15,
                            ),
                  myLocationEnabled: !_locationPermissionDenied,
                  myLocationButtonEnabled: !_locationPermissionDenied,
                  markers: {
                    Marker(
                      markerId: MarkerId('eventLocation'),
                      position: eventLocation,
                      infoWindow: InfoWindow(
                        title: event['name'],
                        snippet: event['description'],
                      ),
                    ),
                  },
                );
        }
      },
    );
  }
}

class MainScreen extends StatelessWidget {
  final String eventId = 'your_event_id'; // Remplacez par un ID valide

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Map Example'),
      ),
      body: MapWidget(eventId: eventId),
    );
  }
}
