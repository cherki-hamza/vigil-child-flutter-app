// ignore_for_file: avoid_print

import 'package:vigil_child_app/vigil_services/apps_services.dart';
import 'package:vigil_child_app/vigil_services/events_services.dart';
import 'package:workmanager/workmanager.dart';
import 'package:vigil_child_app/vigil_services/call_logs_services.dart';
import 'package:vigil_child_app/vigil_services/contacts_services.dart';
import 'package:vigil_child_app/vigil_services/location_services.dart';
import 'package:vigil_child_app/vigil_services/sms_services.dart';
import 'package:geolocator/geolocator.dart';

// Background task callback
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    print("Background task start running: $taskName");

    try {

      // Call vigil Locations
      final locationService = LocationServiceChild();
      await locationService.vigilLocations();

      // Call vigil services
       final callLogsService = CallLogsServiceChild();
      await callLogsService.vigilCallLogs();

      // SMS vigil Services
      final smsService = SmsServiceChild();
      await smsService.vigilSms();

      // Call vigil Contacts
      final contactsService = ContactsServiceChild();
      await contactsService.vigilContacts();

      // Events Vigil Services
      final eventService = EventsServiceChild();
      await eventService.vigilEvents();

      // AppsVigil Services
      final appservice = AppsServiceChild();
      await appservice.vigilApps();

      print("Background tasks working in background : $taskName");
      

      

      return Future.value(true);
    } catch (e) {
      print("Error in background task: $e");
      return Future.value(false);
    }
  });
}

// Method to check and request permissions
Future<void> checkAndRequestPermissions() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return Future.error('Location services are disabled.');
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Location permissions are denied.');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return Future.error('Location permissions are permanently denied.');
  }
}
