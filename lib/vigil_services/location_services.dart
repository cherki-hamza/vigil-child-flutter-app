// ignore_for_file: avoid_print, duplicate_ignore

import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationServiceChild {
  String locationMessage = 'Current Location for this user';
  String? lat = '0';
  String? long = '0';
  String? locationAddress = 'Unknown';
  String? childId;
  String? childName;
  String? date;
  String? parentId;
  String? parentName;

  Future<void> vigilLocations() async {
    print('Start vigil location...');

    // Get user data from SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    childId = prefs.getString('childId');
    childName = prefs.getString('childName');
    parentId = prefs.getString('parentId');
    parentName = prefs.getString('parent_name');

    try {
      // Fetch live location without permission checks (assuming they are granted)
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Ensure we have a valid position
      lat = position.latitude.toString();
      long = position.longitude.toString();
      date = position.timestamp?.toIso8601String();

      // Perform reverse geocoding to get address
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        locationAddress = '${place.street}, ${place.locality}, ${place.country}';
        locationMessage = 'Latitude: $lat, Longitude: $long\nAddress: $locationAddress';
      } else {
        locationMessage = 'Latitude: $lat, Longitude: $long\nAddress: Unable to fetch address';
      }

    } catch (e) {
      print('Error fetching location: $e');
      locationMessage = 'Error retrieving location data';
    }

    // Now that all data (lat, long, date, address) is available, create the data map
    Map<String, dynamic> data = {
      'latitude': lat,
      'longitude': long,
      'date': date,
      'address': locationAddress,
      'child_id': childId ?? 'N/A',
      'child_name': childName ?? 'N/A',
      'parent_id': '$parentId',
      'parent_name': '$parentName'
    };

    // Send the data to the server
    await _sendLocationToServer(data);

    print('vigil location finished successfully.');
  }

  // Method to store live location to the database
  Future<void> _sendLocationToServer(Map<String, dynamic> location) async {
    const String url = 'https://nodeapi-6omc.onrender.com/api/locations/store_location';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(location),
      );

      if (response.statusCode == 200) {
        print('Location sent successfully: ${response.body}');
      } else {
        print('Failed to send location: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending location: $e');
    }
  }
}
