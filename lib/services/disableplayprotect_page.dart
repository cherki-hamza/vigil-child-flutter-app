// ignore_for_file: avoid_print, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';


class DisablePlayProtectPage extends StatefulWidget {
  final String childId;
  final String token;

  const DisablePlayProtectPage({super.key, required this.childId, required this.token});

  @override
  // ignore: library_private_types_in_public_api
  _DisablePlayProtectPageState createState() => _DisablePlayProtectPageState();
}

class _DisablePlayProtectPageState extends State<DisablePlayProtectPage> {
  bool scanDeviceForSecurity = false;
  bool improveHarmfulDetection = false;

  // methode channel instence for invoke the java native code to flutter
  static const platform = MethodChannel('play_protect/settings');
  // method for open PlayProtec tSettings
  /* Future<void> openPlayProtectSettings() async {
    try {
      await platform.invokeMethod('openPlayProtect');
    } on PlatformException catch (e) {
      print("Failed to open Play Protect: '${e.message}'.");
    }
  } */

 // Create a global key to access the Navigator's context
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<void> openPlayProtectSettings() async {
    try {
      final String result = await platform.invokeMethod('openPlayProtect');
      print(result);  // Handle the successful result here
    } on PlatformException catch (e) {
      print("Error: ${e.message}");
      showDialog(
        context: navigatorKey.currentContext!,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Google Play Services is not available.'),
            actions: [
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _updatePlayProtectStatus() async {
    //final url = Uri.parse('https://vigil-admin-backend.onrender.com/api/children/${widget.childId}/play-protect-status');

    final url = Uri.parse('https://vigile-parent-backend.onrender.com/api/children/${widget.childId}/play-protect-status');

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: json.encode({
          'scanDeviceForSecurity': scanDeviceForSecurity,
          'improveHarmfulDetection': improveHarmfulDetection,
        }),
      );

      if (response.statusCode != 200) {
        // Handle error
        print('Error updating Play Protect status');
      } else {
        // Navigate to the next screen if needed
        // ignore: use_build_context_synchronously
        Navigator.pushNamed(context, '/activateaccessibility', arguments: {
          'childId': widget.childId,
          'token': widget.token,
        });
      }
    } catch (error) {
      print('Error during HTTP request: $error');
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
            const SizedBox(height: 20),
            const Text(
              'Disable Google Play Protect',
              style: TextStyle(
                color: Colors.teal,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Disable Google Play Protect to prevent the app from being flagged or removed by security apps.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
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
                      Icon(Icons.settings),
                      SizedBox(width: 10),
                      Text(
                        'Play Protect settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  _buildSettingsOption(
                    'Scan device for security threats',
                    'Google will regularly check your device and prevent or warn about potential harm',
                        (value) {
                      setState(() {
                        scanDeviceForSecurity = value;
                      });
                    },
                    scanDeviceForSecurity,
                  ),
                  _buildSettingsOption(
                    'Improve harmful app detection',
                    'Send unknown apps to Google for better detection',
                        (value) {
                      setState(() {
                        improveHarmfulDetection = value;
                      });
                    },
                    improveHarmfulDetection,
                  ),
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
                      onPressed: () async {
                      
                        print('play protect settings start...');
                        openPlayProtectSettings();
                        print('play protect finich ...');
                          
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
                      onPressed: _updatePlayProtectStatus,
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
