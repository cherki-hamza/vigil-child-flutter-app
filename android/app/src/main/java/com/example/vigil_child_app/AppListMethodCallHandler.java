package com.example.vigil_child_app;

import android.app.usage.UsageStats;
import android.app.usage.UsageStatsManager;
import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.drawable.BitmapDrawable;

import java.io.ByteArrayOutputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class AppListMethodCallHandler implements MethodChannel.MethodCallHandler {

    private final Context context;

    public AppListMethodCallHandler(Context context) {
        this.context = context;
    }

    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        if (call.method.equals("getInstalledApps")) {
            List<Map<String, Object>> apps = getInstalledApps();
            result.success(apps);
        } else {
            result.notImplemented();
        }
    }

    private List<Map<String, Object>> getInstalledApps() {
        List<Map<String, Object>> apps = new ArrayList<>();
        PackageManager packageManager = context.getPackageManager();
        UsageStatsManager usageStatsManager = (UsageStatsManager) context.getSystemService(Context.USAGE_STATS_SERVICE);
        long time = System.currentTimeMillis();
        List<UsageStats> appList = usageStatsManager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, time - 1000 * 3600 * 24, time);

        for (UsageStats usageStats : appList) {
            try {
                ApplicationInfo appInfo = packageManager.getApplicationInfo(usageStats.getPackageName(), 0);
                String appName = packageManager.getApplicationLabel(appInfo).toString();
                BitmapDrawable icon = (BitmapDrawable) packageManager.getApplicationIcon(appInfo);

                ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
                Bitmap bitmap = icon.getBitmap();
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, byteArrayOutputStream);
                byte[] iconBytes = byteArrayOutputStream.toByteArray();

                Map<String, Object> app = new HashMap<>();
                app.put("name", appName);
                app.put("icon", iconBytes);
                app.put("lastTimeUsed", String.valueOf(usageStats.getLastTimeUsed()));

                apps.add(app);
            } catch (PackageManager.NameNotFoundException e) {
                e.printStackTrace();
            }
        }

        return apps;
    }
}
