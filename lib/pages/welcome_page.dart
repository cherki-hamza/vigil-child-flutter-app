// ignore_for_file: library_private_types_in_public_api, avoid_print

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class WelcomePage extends StatefulWidget {
  final String? childId;
  final String? token;

  const WelcomePage({Key? key, this.childId, this.token}) : super(key: key);

  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {

  static const platform = MethodChannel('vigil _move_to_background/background');

  late String name = '';
  late String email = '';
  late int age = 0;
  bool isLoading = true;
  String? childId;
  String? token;
  String? parentId;
  String? parentName;

  @override
  void initState() {
    super.initState();
    _loadLoginState();
  }

  Future<void> _loadLoginState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    childId = prefs.getString('childId') ?? widget.childId;
    token = prefs.getString('token') ?? widget.token;

    if (childId != null && token != null) {
      _fetchChildDetails();
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchChildDetails() async {
    //final url = Uri.parse('https://vigil-admin-backend.onrender.com/api/children/$childId');

    final url = Uri.parse('https://vigile-parent-backend.onrender.com/api/children/$childId');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(data);
        setState(() {
          name = data['name'];
          age = data['age'];
          isLoading = false;
        });

        // Save the login state
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('childId', childId!);
        await prefs.setString('token', token!);
        await prefs.setString('childName', name);
      } else {
        // Handle error
        print('Error fetching child details');
        setState(() {
          isLoading = false;
        });
      }
    } catch (error) {
      print('Error during HTTP request: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('childId');
    await prefs.remove('token');
    await prefs.remove('childName');

    setState(() {
      childId = null;
      token = null;
      name = '';
      age = 0;
      isLoading = false;
    });

    // Navigate to root '/' and remove all previous routes from the stack
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  

  Future<void> moveAppToBackground() async {
    try {
      await platform.invokeMethod('moveToBackground');
      print('vigil moving to working in background with success');
    } on PlatformException catch (e) {
      print("Failed to move app to background: '${e.message}'.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : childId == null || token == null
                ? const Center(child: Text('Please log in'))
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/logo.png', // replace with your actual logo asset path
                          width: 150,
                          height: 160,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Welcome, $name',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Age: $age',
                          style: const TextStyle(
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 40),
                        const Text(
                          'Vigil1 Kids App',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _logout,
                          child: const Text('Logout'),
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton(
                            onPressed: () {
                              moveAppToBackground();  // This will hide the app
                            },
                          child: const Text('Move Vigil To Work from Background'),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
