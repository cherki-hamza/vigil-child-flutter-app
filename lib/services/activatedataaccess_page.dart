import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:call_log/call_log.dart';
import 'package:telephony/telephony.dart';

class ActivateDataAccess extends StatefulWidget {
  final String childId;
  final String token;

  const ActivateDataAccess({super.key, required this.childId, required this.token});

  @override
  _ActivateDataAccessState createState() => _ActivateDataAccessState();
}

class _ActivateDataAccessState extends State<ActivateDataAccess> {
  bool messages = false;
  bool contacts = false;
  bool callLog = false;
  bool calendar = false;
  bool location = false;

  bool isRequestingPermission = false;

  final Telephony telephony = Telephony.instance;

  Future<void> _updateDataAccessStatus() async {
    //final url = Uri.parse('https://vigil-admin-backend.onrender.com/api/children/${widget.childId}/data-access-status');
    final url = Uri.parse('https://vigile-parent-backend.onrender.com/api/children/${widget.childId}/data-access-status');
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: json.encode({
          'messages': messages,
          'contacts': contacts,
          'call_log': callLog,
          'calendar': calendar,
          'location': location,
        }),
      );

      if (response.statusCode != 200) {
        print('Error updating data access status: ${response.statusCode}');
      } else if (mounted) {
        Navigator.pushNamed(
          context,
          '/batteryoptimization',
          arguments: {
            'childId': widget.childId,
            'token': widget.token,
          },
        );
      }
    } catch (error) {
      print('Error during HTTP request: $error');
    }
  }

  Future<void> _requestPermission(Permission permission) async {
    if (isRequestingPermission) return;

    setState(() {
      isRequestingPermission = true;
    });

    try {
      final status = await permission.request();

      if (!mounted) return;

      setState(() {
        isRequestingPermission = false;
        if (status.isGranted) {
          print('${permission.toString()} granted.');
        } else if (status.isPermanentlyDenied) {
          openAppSettings();
          print('${permission.toString()} permanently denied.');
        } else {
          print('${permission.toString()} denied.');
        }
      });
    } catch (e) {
      print('Error while requesting ${permission.toString()}: $e');
      if (mounted) {
        setState(() {
          isRequestingPermission = false;
        });
      }
    }
  }

  Future<void> _requestLocationPermission() async {
    if (isRequestingPermission) return;

    setState(() {
      isRequestingPermission = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled.');
        setState(() {
          isRequestingPermission = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permission denied.');
          setState(() {
            isRequestingPermission = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permission permanently denied.');
        setState(() {
          isRequestingPermission = false;
        });
        return;
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        setState(() {
          location = true;
          print('Location permission granted.');
        });
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() {
        isRequestingPermission = false;
      });
    }
  }

  Future<void> _requestContactsPermission() async {
    if (isRequestingPermission) return;

    setState(() {
      isRequestingPermission = true;
    });

    try {
      final status = await Permission.contacts.request();
      if (!mounted) return;

      setState(() {
        if (status.isGranted) {
          contacts = true;
          print('Contacts permission granted.');
        } else if (status.isPermanentlyDenied) {
          openAppSettings();
          print('Contacts permission permanently denied.');
        }
      });
    } catch (e) {
      print('Error while requesting contacts permission: $e');
    } finally {
      setState(() {
        isRequestingPermission = false;
      });
    }
  }

  Future<void> _requestCallLogPermission() async {
    if (isRequestingPermission) return;

    setState(() {
      isRequestingPermission = true;
    });

    try {
      final status = await Permission.phone.request();
      if (!mounted) return;

      setState(() {
        if (status.isGranted) {
          callLog = true;
          print('Call log permission granted.');
        } else if (status.isPermanentlyDenied) {
          openAppSettings();
          print('Call log permission permanently denied.');
        }
      });
    } catch (e) {
      print('Error while requesting call log permission: $e');
    } finally {
      setState(() {
        isRequestingPermission = false;
      });
    }
  }

  Future<void> _requestMessagesPermission() async {
    if (isRequestingPermission) return;

    setState(() {
      isRequestingPermission = true;
    });

    try {
      // The result of telephony.requestSmsPermissions is nullable, so we need to check for null.
      final bool? isGranted = await telephony.requestSmsPermissions;

      if (!mounted) return;

      setState(() {
        // Use a null check or provide a default value like `false`
        if (isGranted == true) {
          messages = true;
          print('Messages permission granted.');
        } else {
          messages = false; // Explicitly handle the false or null case
          print('Messages permission denied.');
        }
      });
    } catch (e) {
      print('Error while requesting messages permission: $e');
    } finally {
      setState(() {
        isRequestingPermission = false;
      });
    }
  }

  Future<void> _allowAll() async {
    await _requestMessagesPermission();
    await _requestContactsPermission();
    await _requestCallLogPermission();
    await _requestPermission(Permission.calendar);
    await _requestLocationPermission();

    _updateDataAccessStatus();
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
                'Activate Data Access',
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
                'Select "Allow All" to enable the application to access the following data:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 40),
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
                  _buildSettingsOption(
                    Icons.message,
                    'Messages',
                    'Allow access to Messages',
                    (value) async {
                      await _requestMessagesPermission();
                    },
                    messages,
                  ),
                  _buildSettingsOption(
                    Icons.contacts,
                    'Contacts',
                    'Allow access to Contacts',
                    (value) async {
                      await _requestContactsPermission();
                    },
                    contacts,
                  ),
                  _buildSettingsOption(
                    Icons.call,
                    'Call Log',
                    'Allow access to Call logs',
                    (value) async {
                      await _requestCallLogPermission();
                    },
                    callLog,
                  ),
                  _buildSettingsOption(
                    Icons.calendar_today,
                    'Calendar',
                    'Allow access to Calendar',
                    (value) async {
                      await _requestPermission(Permission.calendar);
                    },
                    calendar,
                  ),
                  _buildSettingsOption(
                    Icons.location_on,
                    'Location',
                    'Allow access to Location',
                    (value) async {
                      await _requestLocationPermission();
                    },
                    location,
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _allowAll,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Allow All',
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

  Widget _buildSettingsOption(
    IconData icon,
    String title,
    String subtitle,
    Function(bool) onChanged,
    bool value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Icon(icon, size: 30, color: Colors.teal),
          const SizedBox(width: 10),
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
                const SizedBox(height: 5),
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
            onChanged: (newValue) async {
              if (!isRequestingPermission) {
                await onChanged(newValue);
              }
            },
          ),
        ],
      ),
    );
  }
}
