import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

class home extends StatefulWidget {
  const home({super.key});

  @override
  State<home> createState() => _homeState();
}

class _homeState extends State<home> {
  String currentAddress = 'My Address';
  Position? currentposition;
  bool isFetchingLocation = false;
  XFile? _file;
  ImagePicker _picker = ImagePicker();

  Future<void> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Fluttertoast.showToast(msg: 'Please enable Your Location Service');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Fluttertoast.showToast(msg: 'Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Fluttertoast.showToast(
          msg:
              'Location permissions are permanently denied. Please enable them in app settings.');
      return;
    }
    setState(() {
      isFetchingLocation = true; // Set the flag to true when fetching starts
    });
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        // Access more specific location information
        String thoroughfare = place.thoroughfare ?? ''; // Street name
        String subThoroughfare = place.subThoroughfare ?? ''; // Street number
        String locality = place.locality ?? ''; // City
        String subLocality = place.subLocality ?? ''; // Sub-city area
        String country = place.country ?? ''; // Country

        setState(() {
          currentposition = position;
          currentAddress =
              "$subThoroughfare $thoroughfare, $subLocality $locality, $country";
        });
      }
    } catch (e) {
      print(e);
      Fluttertoast.showToast(msg: 'Error fetching location data');
    } finally {
      setState(() {
        isFetchingLocation = false; // Set the flag to false when fetching ends
      });
    }
  }

  Future<void> getImage() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    setState(() {
      _file = photo;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Photo Track")),
      body: Center(
          child: Column(
        children: [
          Text(currentAddress),
          currentposition != null
              ? Text('Latitude = ' + currentposition!.latitude.toString())
              : Container(),
          currentposition != null
              ? Text('Longitude = ' + currentposition!.longitude.toString())
              : Container(),
          isFetchingLocation
              ? CircularProgressIndicator()
              : TextButton(onPressed: () {}, child: Text('Locate me')),
          SizedBox(height: 16), // Add some spacing
          _file != null
              ? Image.file(
                  File(_file!.path),
                  height: 200,
                  width: 200,
                )
              : Container(),
          SizedBox(height: 16), // Add some spacing
          ElevatedButton(
            onPressed: () async {
              await getImage();
              await determinePosition();
            },
            child: Text('Capture Image'),
          )
        ],
      )),
    );
  }
}
