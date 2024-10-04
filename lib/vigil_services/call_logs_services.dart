import 'package:call_log/call_log.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CallLogsServiceChild {
  List<CallLogEntry> _callLogs = [];
  String? childId;
  String? childName;
  String? parentId;
  String? parentName;

  // Method to handle call logs
  Future<void> vigilCallLogs() async {
    print('Start Fetching call logs...');

    // Get user data from SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    childId = prefs.getString('childId');
    childName = prefs.getString('childName');
    parentId = prefs.getString('parentId');
    parentName = prefs.getString('parent_name');

    try {
      // Fetch call logs from the device
      Iterable<CallLogEntry> entries = await CallLog.get();
      _callLogs = entries.toList();

      // Convert the entries to a List of Maps
      List<Map<String, dynamic>> callLogsToSend = _callLogs.map((call) {
        return {
          'name': call.name,
          'number': call.number,
          'callType': _getCallStatus(call.callType),
          'duration': call.duration,
          'timestamp': DateTime.fromMillisecondsSinceEpoch(call.timestamp!).toIso8601String(),
          'child_id': '$childId',
          'child_name': '$childName',
          'parent_id': '$parentId',
          'parent_name': '$parentName'
        };
      }).toList();

      // Send the logs to the server
      await _sendCallLogsToServer(callLogsToSend);

      print('Call logs successfully fetched and sent.');
    } catch (e) {
      print('Error fetching call logs: $e');
    }
  }

  // Store call logs to the server
  Future<void> _sendCallLogsToServer(List<Map<String, dynamic>> callLogs) async {
    const String url = 'https://nodeapi-6omc.onrender.com/api/logs/store_calllogs';

    // Send POST request to the server
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'logs': callLogs}),
      );

      if (response.statusCode == 200) {
        print('Call logs sent successfully: ${response.body}');
      } else {
        print('Failed to send call logs: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending call logs: $e');
    }
  }

  // Method to get the call status
  String _getCallStatus(CallType? callType) {
    switch (callType) {
      case CallType.incoming:
        return 'Incoming';
      case CallType.outgoing:
        return 'Outgoing';
      case CallType.missed:
        return 'Missed';
      case CallType.rejected:
        return 'Rejected';
      case CallType.blocked:
        return 'Blocked';
      default:
        return 'Unknown';
    }
  }
}
