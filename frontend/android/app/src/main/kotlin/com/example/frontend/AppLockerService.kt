package com.example.frontend

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log

class AppLockerService : Service() {
    private val CHANNEL_ID = "AppLockerChannel"
    private var isRunning = false
    private var monitorThread: Thread? = null
    
    companion object {
        val blockedApps = java.util.Collections.synchronizedSet(mutableSetOf<String>())
        
        fun updateBlockedApps(apps: List<String>) {
            blockedApps.clear()
            blockedApps.addAll(apps)
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == "STOP_SERVICE") {
            stopSelf()
            return START_NOT_STICKY
        }
        
        val notification = createNotification()
        startForeground(2, notification)
        
        if (!isRunning) {
            startMonitoring()
        }
        
        return START_STICKY
    }

    private fun startMonitoring() {
        isRunning = true
        monitorThread = Thread {
            Log.d("AppLockerService", "App Locker Service started monitoring.")
            val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager

            while (isRunning && !Thread.currentThread().isInterrupted) {
                try {
                    if (blockedApps.isEmpty()) {
                        Thread.sleep(2000)
                        continue
                    }

                    val endTime = System.currentTimeMillis()
                    val beginTime = endTime - 2000
                    
                    var currentApp: String? = null
                    val usageEvents = usageStatsManager.queryEvents(beginTime, endTime)
                    val event = android.app.usage.UsageEvents.Event()
                    
                    while (usageEvents.hasNextEvent()) {
                        usageEvents.getNextEvent(event)
                        if (event.eventType == android.app.usage.UsageEvents.Event.MOVE_TO_FOREGROUND) {
                            currentApp = event.packageName
                        }
                    }

                    if (currentApp != null
                        && currentApp != packageName
                        && blockedApps.contains(currentApp)) {

                        // Get the human-readable name
                        val appName = try {
                            val appInfo = packageManager.getApplicationInfo(currentApp, 0)
                            packageManager.getApplicationLabel(appInfo).toString()
                        } catch (e: Exception) {
                            currentApp
                        }

                        Log.d("AppLockerService", "Blocking: $currentApp ($appName)")

                        val blockIntent = Intent(this, BlockedAppActivity::class.java).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                            putExtra("blocked_app_name", appName)
                        }
                        startActivity(blockIntent)

                        // Wait a bit before checking again to avoid rapid-fire
                        Thread.sleep(3000)
                    }

                    Thread.sleep(1000)
                } catch (e: InterruptedException) {
                    break
                } catch (e: Exception) {
                    Log.e("AppLockerService", "Error in app locker loop", e)
                    Thread.sleep(2000)
                }
            }
            Log.d("AppLockerService", "App Locker Service stopped.")
        }
        monitorThread?.isDaemon = true
        monitorThread?.start()
    }

    override fun onDestroy() {
        isRunning = false
        monitorThread?.interrupt()
        monitorThread = null
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                "Parental App Locker",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Runs the parental app blocker in the background"
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(serviceChannel)
        }
    }

    private fun createNotification(): Notification {
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        
        return builder
            .setContentTitle("Cyber Mfukoni Guardian")
            .setContentText("Parental App Blocker is actively protecting this device.")
            .setSmallIcon(android.R.drawable.ic_secure)
            .setOngoing(true)
            .build()
    }
}
