package com.example.frontend

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED || 
            intent.action == Intent.ACTION_LOCKED_BOOT_COMPLETED || 
            intent.action == "android.intent.action.QUICKBOOT_POWERON") {
            
            // Check if AppLocker is enabled (we can store this in SharedPreferences, but for now we always try to start it and let the service decide if there are apps to block)
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val blockedAppsString = prefs.getString("flutter.parental_blocked_apps", "")
            
            if (!blockedAppsString.isNullOrEmpty() && blockedAppsString != "[]") {
                val serviceIntent = Intent(context, AppLockerService::class.java)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(serviceIntent)
                } else {
                    context.startService(serviceIntent)
                }
            }
        }
    }
}
