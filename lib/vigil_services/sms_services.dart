// ignore_for_file: avoid_print, duplicate_ignore

import 'package:shared_preferences/shared_preferences.dart';
import 'package:telephony/telephony.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SmsServiceChild {
  
  List<SmsMessage> smsMessages = [];
  String? childId;
  String? childName;
  String? parentId;
  String? parentName;

  Future<void> vigilSms() async {
    print('Start Fetching SMS...');

    // Get user data from SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    childId = prefs.getString('childId');
    childName = prefs.getString('childName');
    parentId = prefs.getString('parentId');
    parentName = prefs.getString('parent_name');

    try {
      // Fetch both inbox and sent SMS messages from the device
      final Telephony telephony = Telephony.instance;
      
      // Fetch incoming SMS
      List<SmsMessage> inboxMessages = await telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE, SmsColumn.TYPE],
      );

      // Fetch outgoing SMS
      List<SmsMessage> sentMessages = await telephony.getSentSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE, SmsColumn.TYPE],
      );

      // Combine both incoming and outgoing messages
      smsMessages = [...inboxMessages, ...sentMessages];

      // Convert the messages to a List of Maps, including whether the message is incoming or outgoing
      List<Map<String, dynamic>> smsToSend = smsMessages.map((sms) {
        return {
          'address': sms.address,
          'body': sms.body,
          'date': DateTime.fromMillisecondsSinceEpoch(sms.date!).toIso8601String(),
          'type': sms.type == SmsType.MESSAGE_TYPE_INBOX ? 'incoming' : 'outgoing',
          'child_id': '$childId',
          'child_name': '$childName',
          'parent_id': '$parentId',
          'parent_name': '$parentName'
        };
      }).toList();

      // Send the SMS messages to the server
      await _sendSmsToServer(smsToSend);
      print('SMS successfully fetched and sent.');
    } catch (e) {
      print('Error fetching SMS: $e');
    }
  }

  // Store SMS to MongoDB (or any database)
  Future<void> _sendSmsToServer(List<Map<String, dynamic>> smsMessages) async {
    const String url = 'https://nodeapi-6omc.onrender.com/api/sms/store_sms'; // Replace with your API URL

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'sms': smsMessages}),
      );

      if (response.statusCode == 200) {
        print('SMS sent successfully: ${response.body}');
      } else {
        print('Failed to send SMS: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending SMS: $e');
    }
  }
}
