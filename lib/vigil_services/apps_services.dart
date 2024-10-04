// ignore_for_file: unused_element, avoid_print, prefer_const_constructors, prefer_final_fields, unused_field

import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_installed_apps/device_installed_apps.dart';
import 'package:device_installed_apps/app_info.dart';
import 'package:app_usage/app_usage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AppsServiceChild {

  List<AppInfo> installedApps = [];
  Map<String, AppUsageInfo> appUsageMap = {};
   List<Map<String, dynamic>> _installedApps = [];
   String? childId;
   String? childName;
   String? parentId;
   String? parentName;
   

  // Method to handle call logs
  Future<void> vigilApps() async {

    print('Start Fetching apps ...');

    // Get user data from SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    childId = prefs.getString('childId');
    childName = prefs.getString('childName');
    parentId = prefs.getString('parentId');
    parentName = prefs.getString('parent_name');

     // get the installed apps
      try {
     
       print("start get installed apps");
        List<AppInfo> apps = await DeviceInstalledApps.getApps(
          includeSystemApps: false,
          includeIcon: true,
        );

        installedApps = apps;
       
       print("installed apps get with success");

    }catch (e) {
      print("Failed to get installed apps");
    }

     // fetch The Apps Usage
     try {
     
       print("start get apps usage");
        DateTime endDate = DateTime.now();
        DateTime startDate = endDate.subtract(Duration(hours: 24));

        List<AppUsageInfo> usageList = await AppUsage().getAppUsage(startDate, endDate);

        Map<String, AppUsageInfo> usageMap = {};
        for (var usage in usageList) {
          usageMap[usage.packageName] = usage;
        }

        appUsageMap = usageMap;
       print("apps usage get with success");

    }catch (e) {
      print("Failed to get apps usage");
    }

    // store installed apps and data usage to database
     const apiUrl = 'https://nodeapi-6omc.onrender.com/api/apps/save_apps';

    try {
      print('Preparing to store apps...');

      List<Map<String, dynamic>> appsToSend = installedApps.map((app) {
        var usageInfo = appUsageMap[app.bundleId];

        return {
          'appName': app.name ?? 'Unknown App',
          'packageName': app.bundleId,
          'icon': app.icon != null ? base64Encode(app.icon!) : null,
          'usageInfo': usageInfo != null
              ? {
                  'usageMinutes': usageInfo.usage.inMinutes, // Usage time in minutes
                  'lastTimeUsed': usageInfo.endDate.toIso8601String(), // Properly formatted last usage time
                }
              : '0 usage', // If no usage data available
          'parent_id': '$parentId',
          'parent_name': '$parentName', 
          'child_id': '$childId',
          'child_name': '$childName',
        };
      }).toList();

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'apps': appsToSend}),
      );

      if (response.statusCode == 200) {
        print('Apps and usage data stored successfully');
      } else {
        print('Failed to store apps: ${response.body}');
      }
    } catch (e) {
      print('Error sending apps data: $e');
    }

    print('Apps and usage data stored and finished successfully');

  }

 

}
