package com.example.vigil_child_app;

import android.app.admin.DevicePolicyManager;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.provider.Settings;
import android.widget.Toast;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.content.pm.PackageManager.NameNotFoundException;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.util.Base64;
import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugins.GeneratedPluginRegistrant;
import io.flutter.plugin.common.MethodChannel;
import java.io.ByteArrayOutputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.GoogleApiAvailability;

public class MainActivity extends FlutterActivity {

    private static final String CHANNEL_SETTINGS = "play_protect/settings";
    private static final String CHANNEL_ACCESSIBILITY = "accessibility/settings";
    private static final String CHANNEL_USAGE_ACCESS = "activate_app_supervision/systemService";
    private static final String CHANNEL_NOTIFICATIONS_ACCESS = "notification_access/notifications";
    private static final String CHANNEL_ADMINISTRATOR_ACCESS = "administrator_access/device_admin";
    private static final int REQUEST_CODE_ENABLE_ADMIN = 1;
    private static final String CHANNEL_DISABLE_BATTERY_OPTIMIZATION = "disable_battery_optimization/disable_battery";
    private static final String CHANNEL_INSTALLED_APPS = "get_installed_apps/installed_apps";
    private static final String CHANNEL_MOVE_TO_BACKGROUND = "vigil_move_to_background/background";

    // To keep track of the method channel result for requestAdminAccess
    private MethodChannel.Result adminAccessResult;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        // method for hide the vigil app to working in background
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL_MOVE_TO_BACKGROUND)
            .setMethodCallHandler((call, result) -> {
                if (call.method.equals("moveToBackground")) {
                    moveTaskToBack(true);
                    result.success(null);
                } else {
                    result.notImplemented();
                }
            }
        );

        // Method Channel for open Play Protect
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL_SETTINGS).setMethodCallHandler(
            (call, result) -> {
                if (call.method.equals("openPlayProtect")) {
                    if (checkGooglePlayServices()) {
                        openGooglePlayServices();
                        result.success("Google Play Services is available, Play Protect check successful.");
                    } else {
                        if (result != null) {
                            result.error("UNAVAILABLE", "Google Play Services is not available on this device.", null);
                        }
                    }
                } else {
                    result.notImplemented();
                }
            }
        );

        // Method Channel for the Accessibility Settings
        new MethodChannel(getFlutterEngine().getDartExecutor().getBinaryMessenger(), CHANNEL_ACCESSIBILITY)
            .setMethodCallHandler((call, result) -> {
                if (call.method.equals("openAccessibilitySettings")) {
                    openAccessibilitySettings();
                    result.success(null);
                } else {
                    result.notImplemented();
                }
            }
        );

        // Method Channel for the request Usage Access
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL_USAGE_ACCESS)
            .setMethodCallHandler((call, result) -> {
                if (call.method.equals("requestUsageAccess")) {
                    requestUsageAccess();
                    result.success(null);
                } else if (call.method.equals("checkSystemUpdates")) {
                    openSystemUpdateSettings();
                    result.success(null);
                } else {
                    result.notImplemented();
                }
            }
        );

        // Method Channel for the notification permissions
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL_NOTIFICATIONS_ACCESS)
            .setMethodCallHandler((call, result) -> {
                if (call.method.equals("requestNotificationAccess")) {
                    boolean isAccessGranted = requestNotificationListenerPermission();
                    if (result != null) {
                        result.success(isAccessGranted);
                    }
                } else {
                    result.notImplemented();
                }
            }
        );

        // Method Channel for Activate Administrator Access
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL_ADMINISTRATOR_ACCESS)
            .setMethodCallHandler((call, result) -> {
                if (call.method.equals("requestAdminAccess")) {
                    // Store the result and use it after the onActivityResult
                    adminAccessResult = result;
                    requestDeviceAdminAccess();
                } else {
                    result.notImplemented();
                }
            }
        );

        // Method Channel for Allow battery Optimization
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL_DISABLE_BATTERY_OPTIMIZATION)
            .setMethodCallHandler((call, result) -> {
                if (call.method.equals("disableBatteryOptimization")) {
                    boolean isDisabled = disableBatteryOptimization();
                    if (result != null) {
                        result.success(isDisabled);
                    }
                } else {
                    result.notImplemented();
                }
            }
        );

        // Method for get the installed apps
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL_INSTALLED_APPS)
            .setMethodCallHandler((call, result) -> {
                if (call.method.equals("getInstalledApps")) {
                    Map<String, Object> response = new HashMap<>();
                    List<Map<String, Object>> installedApps = getInstalledApps();
                    response.put("apps", installedApps);  // Wrap installed apps in "apps" key
                    if (result != null) {
                        result.success(response);
                    }
                } else {
                    result.notImplemented();
                }
            }
        );
    }

    // 1 Method to check if Google Play Services is available
    private boolean checkGooglePlayServices() {
        GoogleApiAvailability googleApiAvailability = GoogleApiAvailability.getInstance();
        int resultCode = googleApiAvailability.isGooglePlayServicesAvailable(this);
        
        if (resultCode == ConnectionResult.SUCCESS) {
            return true;  // Google Play Services is available
        } else {
            if (googleApiAvailability.isUserResolvableError(resultCode)) {
                googleApiAvailability.getErrorDialog(this, resultCode, 2404).show();
            } else {
                Toast.makeText(this, "Google Play Services is not available on this device", Toast.LENGTH_LONG).show();
            }
            return false;
        }
    }

    // Method to open Google Play Services in the Play Store
    private void openGooglePlayServices() {
        Intent intent = new Intent(Intent.ACTION_VIEW);
        intent.setData(Uri.parse("market://details?id=com.google.android.gms"));
        intent.setPackage("com.android.vending");

        if (intent.resolveActivity(getPackageManager()) != null) {
            startActivity(intent);
        } else {
            Toast.makeText(this, "Google Play Store is not available on this device", Toast.LENGTH_LONG).show();
        }
    }

    // Method to open the Accessibility Settings
    public void openAccessibilitySettings() {
        Intent intent = new Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS);
        startActivity(intent);
    }

    // Request Usage Access
    private void requestUsageAccess() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            Intent intent = new Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS);
            startActivity(intent);
        }
    }

    // Check for System Updates (just opens system update settings)
    private void openSystemUpdateSettings() {
        try {
            Intent intent = new Intent();
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                intent.setAction(Settings.ACTION_DEVICE_INFO_SETTINGS);
            } else {
                intent.setAction(Settings.ACTION_SETTINGS);
            }
            startActivity(intent);
        } catch (Exception e) {
            Intent fallbackIntent = new Intent(Settings.ACTION_SETTINGS);
            startActivity(fallbackIntent);
        }
    }

    // Method for notification permissions
    private boolean requestNotificationListenerPermission() {
        Context context = getApplicationContext();
        String enabledListeners = Settings.Secure.getString(context.getContentResolver(), "enabled_notification_listeners");
        String packageName = context.getPackageName();

        if (enabledListeners == null || !enabledListeners.contains(packageName)) {
            Intent intent = new Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            context.startActivity(intent);

            Toast.makeText(context, "Enable notification access for the app.", Toast.LENGTH_LONG).show();
            return false;
        } else {
            Toast.makeText(context, "Notification access is already granted.", Toast.LENGTH_LONG).show();
            return true;
        }
    }

    // Method for Activate the Administrator Access
    private void requestDeviceAdminAccess() {
        DevicePolicyManager devicePolicyManager = (DevicePolicyManager) getSystemService(Context.DEVICE_POLICY_SERVICE);
        ComponentName adminComponent = new ComponentName(this, MyDeviceAdminReceiver.class);

        Intent intent = new Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN);
        intent.putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, adminComponent);
        startActivityForResult(intent, REQUEST_CODE_ENABLE_ADMIN);
    }

    // Method for disable battery optimization
    private boolean disableBatteryOptimization() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Intent intent = new Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS);
            intent.setData(Uri.parse("package:" + getPackageName()));
            startActivity(intent);
            return true;
        }
        return false;
    }

    // Handling result from activities
    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        
        if (requestCode == REQUEST_CODE_ENABLE_ADMIN) {
            if (adminAccessResult != null) {
                if (resultCode == RESULT_OK) {
                    adminAccessResult.success(true);
                } else {
                    adminAccessResult.success(false);
                }
                adminAccessResult = null; // Clear the result to avoid double-calling
            }
        }
    }

    // Get installed apps with additional information
    private List<Map<String, Object>> getInstalledApps() {
        PackageManager packageManager = getPackageManager();
        List<ApplicationInfo> apps = packageManager.getInstalledApplications(PackageManager.GET_META_DATA);
        List<Map<String, Object>> installedApps = new ArrayList<>();

        for (ApplicationInfo app : apps) {
            Map<String, Object> appInfo = new HashMap<>();
            appInfo.put("appName", packageManager.getApplicationLabel(app).toString());
            appInfo.put("packageName", app.packageName);

            // Example of hardcoded child and parent information
            appInfo.put("child_id", 22); // You can modify this logic as needed
            appInfo.put("child_name", "rekson");
            appInfo.put("parent_id", 2);
            appInfo.put("parent_name", "charokhan");

            try {
                Drawable iconDrawable = packageManager.getApplicationIcon(app.packageName);
                Bitmap iconBitmap = drawableToBitmap(iconDrawable);
                ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
                iconBitmap.compress(Bitmap.CompressFormat.PNG, 100, byteArrayOutputStream);
                byte[] iconBytes = byteArrayOutputStream.toByteArray();
                String iconBase64 = Base64.encodeToString(iconBytes, Base64.NO_WRAP);
                appInfo.put("icon", iconBase64);
            } catch (NameNotFoundException e) {
                e.printStackTrace();
            }

            installedApps.add(appInfo);
        }

        return installedApps;
    }

    // Convert Drawable to Bitmap
    private Bitmap drawableToBitmap(Drawable drawable) {
        if (drawable instanceof BitmapDrawable) {
            return ((BitmapDrawable) drawable).getBitmap();
        } else {
            Bitmap bitmap = Bitmap.createBitmap(drawable.getIntrinsicWidth(), drawable.getIntrinsicHeight(), Bitmap.Config.ARGB_8888);
            Canvas canvas = new Canvas(bitmap);
            drawable.setBounds(0, 0, canvas.getWidth(), canvas.getHeight());
            drawable.draw(canvas);
            return bitmap;
        }
    }
}
