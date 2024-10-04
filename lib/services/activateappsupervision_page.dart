// ignore_for_file: library_private_types_in_public_api, avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';

class ActivateAppSuperVisionPage extends StatefulWidget {
  final String childId;
  final String token;

  const ActivateAppSuperVisionPage({super.key, required this.childId, required this.token});

  @override
  _ActivateAppSuperVisionPageState createState() => _ActivateAppSuperVisionPageState();
}

class _ActivateAppSuperVisionPageState extends State<ActivateAppSuperVisionPage> {
  bool allowUsageTracking = false;

   // Define a MethodChannel to communicate with the native Android code
   static const platform = MethodChannel('activate_app_supervision/systemService');

  Future<void> _updateSupervisionStatus() async {
    // final url = Uri.parse('https://vigil-admin-backend.onrender.com/api/children/${widget.childId}/supervision-status');

    final url = Uri.parse('https://vigile-parent-backend.onrender.com/api/children/${widget.childId}/supervision-status');

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: json.encode({
          'allowUsageTracking': allowUsageTracking,
        }),
      );

      if (response.statusCode != 200) {
        // Handle error
        print('Error updating supervision status');
      } else {
        // Navigate to the next screen if needed
        Navigator.pushNamed(context, '/activatenotificationaccess', arguments: {
          'childId': widget.childId,
          'token': widget.token,
        });
      }
    } catch (error) {
      print('Error during HTTP request: $error');
    }
  }

 // Function to request usage access
  Future<void> requestUsageAccess() async {
    try {
      await platform.invokeMethod('requestUsageAccess');
    } on PlatformException catch (e) {
      print("Failed to request usage access: '${e.message}'.");
    }
  }

  // Function to check for system updates
  Future<void> checkSystemUpdates() async {
    try {
      await platform.invokeMethod('checkSystemUpdates');
    } on PlatformException catch (e) {
      print("Failed to check for system updates: '${e.message}'.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                const Expanded(
                  child: Text(
                    'Allow Permissions',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            const Center(
              child: Text(
                'Activate Supervision',
                style: TextStyle(
                  color: Colors.teal,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text(
                'Go to Usage Data Access > System Update Service and enable "Allow usage tracking".',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.arrow_back_ios, size: 20,),
                      SizedBox(width: 10),
                      Text(
                        'Usage Data Access',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  _buildSettingsOption('Allow Usage Tracking', 'Allow Vigil1 to monitor your app usage frequency, identify your service provider, language settings, and other usage data.', (value) {
                    setState(() {
                      allowUsageTracking = value;
                    });
                  }, allowUsageTracking),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle the Proceed to Settings logic here
                         print('Usage Access  start...');
                         requestUsageAccess();
                         print('Usage Access finich ...');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Proceed to Settings',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _updateSupervisionStatus,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsOption(String title, String subtitle, Function(bool) onChanged, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
