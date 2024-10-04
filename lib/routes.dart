import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vigil_child_app/pages/welcome_page.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/terms_page.dart';
import 'pages/linkparent_page.dart';
import 'pages/addchildprofile_page.dart';
import 'pages/allowpermission_page.dart';
import 'services/disableplayprotect_page.dart';
import 'services/activateaccessibility_page.dart';
import 'services/activateappsupervision_page.dart';
import 'services/activatenotificationaccess_page.dart';
import 'services/activateadministratoraccess_page.dart';
import 'services/activatedataaccess_page.dart';
import 'services/batteryoptimization_page.dart';
import 'services/finalmonitoring_page.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/': (context) => FutureBuilder<Map<String, dynamic>?>(
          future: _checkTokenAndChildId(context),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            } else if (snapshot.hasData && snapshot.data != null) {
              final data = snapshot.data!;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushReplacementNamed(
                  context,
                  '/welcomepage',
                  arguments: {
                    'token': data['token'],
                    'childId': data['childId'],
                  },
                );
              });
              return const SizedBox(); // Empty widget while navigating away
            } else {
              // If token or childId is missing, load HomePage
              return HomePage();
            }
          },
        ),
    '/login': (context) => const LoginPage(),
    '/terms': (context) => const TermsPage(),
    '/otp': (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
      if (args == null) {
        return const Scaffold(
          body: Center(child: Text('No arguments provided')),
        );
      }
      return LinkParentDevicePage(
        email: args['email']!,
        token: args['token']!,
      );
    },
    '/childprofile': (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
      if (args == null) {
        return const Scaffold(
          body: Center(child: Text('No arguments provided')),
        );
      }
      return AddChildProfilePage(
        email: args['email']!,
        token: args['token']!,
        otp: args['otp']!,
      );
    },
    '/allowpermission': (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
      if (args == null) {
        return const Scaffold(
          body: Center(child: Text('No arguments provided')),
        );
      }
      return AllowPermissionsPage(
        childId: args['childId']!,
        token: args['token']!,
      );
    },
    '/disablegoogleplayprotect': (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
      if (args == null) {
        return const Scaffold(
          body: Center(child: Text('No arguments provided')),
        );
      }
      return DisablePlayProtectPage(
        childId: args['childId']!,
        token: args['token']!,
      );
    },
    '/activateaccessibility': (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
      if (args == null) {
        return const Scaffold(
          body: Center(child: Text('No arguments provided')),
        );
      }
      return ActivateAccessibilityPage(
        childId: args['childId']!,
        token: args['token']!,
      );
    },
    '/activatesupervision': (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
      if (args == null) {
        return const Scaffold(
          body: Center(child: Text('No arguments provided')),
        );
      }
      return ActivateAppSuperVisionPage(
        childId: args['childId']!,
        token: args['token']!,
      );
    },
    '/activatenotificationaccess': (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
      if (args == null) {
        return const Scaffold(
          body: Center(child: Text('No arguments provided')),
        );
      }
      return ActivateNotificationAccessPage(
        childId: args['childId']!,
        token: args['token']!,
      );
    },
    '/activateadminstratoraccess': (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
      if (args == null) {
        return const Scaffold(
          body: Center(child: Text('No arguments provided')),
        );
      }
      return ActivateAdministratorAccess(
        childId: args['childId']!,
        token: args['token']!,
      );
    },
    '/activatedataaccess': (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
      if (args == null) {
        return const Scaffold(
          body: Center(child: Text('No arguments provided')),
        );
      }
      return ActivateDataAccess(
        childId: args['childId']!,
        token: args['token']!,
      );
    },
    '/batteryoptimization': (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
      if (args == null) {
        return const Scaffold(
          body: Center(child: Text('No arguments provided')),
        );
      }
      return BatteryOptimization(
        childId: args['childId']!,
        token: args['token']!,
      );
    },
    '/finalmonitoring': (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
      if (args == null) {
        return const Scaffold(
          body: Center(child: Text('No arguments provided')),
        );
      }
      return StartMonitoring(
        childId: args['childId']!,
        token: args['token']!,
      );
    },
    '/welcomepage': (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args == null) {
        return const Scaffold(
          body: Center(child: Text('No arguments provided')),
        );
      }
      return WelcomePage(
        childId: args['childId']!,
        token: args['token']!,
      );
    },
  };

  static Future<Map<String, dynamic>?> _checkTokenAndChildId(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? childId = prefs.getString('childId');

    // Return data if both token and childId exist, otherwise return null
    if (token != null && childId != null) {
      return {'token': token, 'childId': childId};
    }
    return null;
  }
}
