// ignore_for_file: unused_field, prefer_final_fields, avoid_print, prefer_const_constructors

import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EventsServiceChild {

 final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();
  List<Event> _calendarEvents = [];
  String? childId;
  String? childName;
  String? parentId;
  String? parentName;

  // Method to handle call logs
  Future<void> vigilEvents() async {

    print('Start Fetching Calendar...');

    // Get user data from SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    childId = prefs.getString('childId');
    childName = prefs.getString('childName');
    parentId = prefs.getString('parentId');
    parentName = prefs.getString('parent_name');


    var calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();

    if (calendarsResult.isSuccess && calendarsResult.data != null) {

      print('Calendars found:');
      for (var calendar in calendarsResult.data!) {
        print('Calendar ID: ${calendar.id}, Name: ${calendar.name}');

        // Retrieve events for each calendar
        var eventsResult = await _deviceCalendarPlugin.retrieveEvents(
          calendar.id!,
          RetrieveEventsParams(
            startDate: DateTime.now(),
            endDate: DateTime.now().add(Duration(days: 90)),
          ),
        );

        if (eventsResult.isSuccess && eventsResult.data!.isNotEmpty) {
          
            _calendarEvents.addAll(eventsResult.data!);
         
          await _sendEventsToBackend(eventsResult.data!);
        } else {
          print('No events found in the calendar ${calendar.name}.');
        }
      }
    } else {
      print('Failed to retrieve calendars');
    }


  }

   // Send calendar events to the backend server
  Future<void> _sendEventsToBackend(List<Event> events) async {
    const url = 'https://nodeapi-6omc.onrender.com/api/events/store_events'; // Update with your Node.js API URL
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      'events': events.map((e) => {
        'title': e.title,
        'start': e.start?.toIso8601String(),
        'end': e.end?.toIso8601String(),
        'child_id': childId,
        'child_name': childName,
        'parent_id': '$parentId',
        'parent_name': '$parentName',
        'location': e.location,
        'description': e.description,
        // Remove organizer and attendees if not available
      }).toList(),
    });

    try {
      final response = await http.post(Uri.parse(url), headers: headers, body: body);
      if (response.statusCode == 200) {
        print('Events successfully sent to the backend');
      } else {
        print('Failed to send events: ${response.body}');
      }
    } catch (e) {
      print('Error occurred while sending events: $e');
    }
  }


}
