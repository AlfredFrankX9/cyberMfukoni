package com.example.frontend

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.pm.PackageManager
import android.content.pm.PackageInfo
import android.content.pm.ApplicationInfo
import java.util.HashMap
import java.util.ArrayList

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Environment
import android.provider.Settings
import android.util.Log
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.util.Base64
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.RandomAccessFile
import java.security.SecureRandom

class MainActivity : FlutterFragmentActivity() {
    private val PERM_CHANNEL = "com.example.frontend/permissions"
    private val VPN_CHANNEL = "com.example.frontend/vpn"
    private val SHREDDER_CHANNEL = "com.example.frontend/shredder"
    private val PARENTAL_CHANNEL = "com.example.frontend/parental"
    private val VPN_REQUEST_CODE = 0x0F

    // App Locker state
    private val blockedApps = java.util.Collections.synchronizedSet(mutableSetOf<String>())
    private var appLockerThread: Thread? = null
    private var appLockerRunning = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERM_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getInstalledAppsWithPermissions") {
                val appsList = getInstalledAppsWithPermissions()
                result.success(appsList)
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VPN_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startVpn" -> {
                    val intent = android.net.VpnService.prepare(this)
                    if (intent != null) {
                        startActivityForResult(intent, VPN_REQUEST_CODE)
                        result.success(true)
                    } else {
                        onActivityResult(VPN_REQUEST_CODE, android.app.Activity.RESULT_OK, null)
                        result.success(true)
                    }
                }
                "stopVpn" -> {
                    val intent = Intent(this, DnsFilterVpnService::class.java)
                    intent.action = DnsFilterVpnService.ACTION_STOP
                    startService(intent)
                    result.success(true)
                }
                "isVpnRunning" -> {
                    result.success(DnsFilterVpnService.isRunning)
                }
                "getBlockedCount" -> {
                    result.success(DnsFilterVpnService.blockedCount)
                }
                "updateBlockedDomains" -> {
                    val domains = call.argument<List<String>>("domains") ?: emptyList()
                    DnsFilterVpnService.updateBlocklist(domains)
                    result.success(true)
                }
                "addBlockedDomain" -> {
                    val domain = call.argument<String>("domain") ?: ""
                    if (domain.isNotEmpty()) DnsFilterVpnService.addToBlocklist(domain)
                    result.success(true)
                }
                "removeBlockedDomain" -> {
                    val domain = call.argument<String>("domain") ?: ""
                    if (domain.isNotEmpty()) DnsFilterVpnService.removeFromBlocklist(domain)
                    result.success(true)
                }
                "getBlockedDomains" -> {
                    result.success(DnsFilterVpnService.getBlocklist().toList())
                }
                else -> result.notImplemented()
            }
        }

        // ── Parental Controls channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PARENTAL_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasUsagePermission" -> {
                    result.success(hasUsageStatsPermission())
                }
                "requestUsagePermission" -> {
                    startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                    result.success(true)
                }
                "updateBlockedApps" -> {
                    val apps = call.argument<List<String>>("packages") ?: emptyList()
                    blockedApps.clear()
                    blockedApps.addAll(apps)
                    if (apps.isNotEmpty() && !appLockerRunning) {
                        startAppLocker()
                    } else if (apps.isEmpty()) {
                        stopAppLocker()
                    }
                    result.success(true)
                }
                "getBlockedApps" -> {
                    result.success(blockedApps.toList())
                }
                "getInstalledApps" -> {
                    Thread {
                        val apps = getInstalledAppsSimple()
                        runOnUiThread { result.success(apps) }
                    }.start()
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SHREDDER_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "shredFile" -> {
                    val filePath = call.argument<String>("path")
                    if (filePath == null) {
                        result.error("INVALID", "File path is null", null)
                        return@setMethodCallHandler
                    }
                    Thread {
                        try {
                            val file = File(filePath)
                            if (!file.exists()) {
                                runOnUiThread { result.error("NOT_FOUND", "File does not exist: $filePath", null) }
                                return@Thread
                            }
                            val length = file.length()
                            val random = SecureRandom()

                            // 3-pass overwrite using RandomAccessFile for direct I/O
                            val raf = RandomAccessFile(file, "rws")
                            val buffer = ByteArray(minOf(length.toInt(), 8192))

                            // Pass 1: zeros
                            raf.seek(0)
                            var written = 0L
                            java.util.Arrays.fill(buffer, 0x00.toByte())
                            while (written < length) {
                                val toWrite = minOf(buffer.size.toLong(), length - written).toInt()
                                raf.write(buffer, 0, toWrite)
                                written += toWrite
                            }
                            raf.fd.sync()

                            // Pass 2: ones
                            raf.seek(0)
                            written = 0L
                            java.util.Arrays.fill(buffer, 0xFF.toByte())
                            while (written < length) {
                                val toWrite = minOf(buffer.size.toLong(), length - written).toInt()
                                raf.write(buffer, 0, toWrite)
                                written += toWrite
                            }
                            raf.fd.sync()

                            // Pass 3: random
                            raf.seek(0)
                            written = 0L
                            while (written < length) {
                                random.nextBytes(buffer)
                                val toWrite = minOf(buffer.size.toLong(), length - written).toInt()
                                raf.write(buffer, 0, toWrite)
                                written += toWrite
                            }
                            raf.fd.sync()
                            raf.close()

                            // Delete
                            val deleted = file.delete()
                            runOnUiThread {
                                if (deleted) {
                                    result.success(mapOf("success" to true, "size" to length))
                                } else {
                                    result.success(mapOf("success" to false, "error" to "Overwrite succeeded but delete failed. File contents are destroyed."))
                                }
                            }
                        } catch (e: Exception) {
                            runOnUiThread { result.error("SHRED_ERROR", e.message, null) }
                        }
                    }.start()
                }
                "listDirectoryFiles" -> {
                    val dirPath = call.argument<String>("path")
                    if (dirPath == null) {
                        result.error("INVALID", "Directory path is null", null)
                        return@setMethodCallHandler
                    }
                    Thread {
                        try {
                            val dir = File(dirPath)
                            val files = ArrayList<Map<String, Any>>()
                            if (dir.exists() && dir.isDirectory) {
                                dir.walkTopDown().maxDepth(3).forEach { f ->
                                    if (f.isFile) {
                                        files.add(mapOf(
                                            "name" to f.name,
                                            "path" to f.absolutePath,
                                            "size" to f.length()
                                        ))
                                    }
                                }
                            }
                            runOnUiThread { result.success(files) }
                        } catch (e: Exception) {
                            runOnUiThread { result.error("LIST_ERROR", e.message, null) }
                        }
                    }.start()
                }
                "listDirectory" -> {
                    val dirPath = call.argument<String>("path")
                    if (dirPath == null) {
                        result.error("INVALID", "Directory path is null", null)
                        return@setMethodCallHandler
                    }
                    Thread {
                        try {
                            val dir = File(dirPath)
                            val entries = ArrayList<Map<String, Any>>()
                            if (dir.exists() && dir.isDirectory) {
                                val children = dir.listFiles() ?: emptyArray()
                                for (child in children) {
                                    if (child.name.startsWith(".")) continue
                                    entries.add(mapOf(
                                        "name" to child.name,
                                        "path" to child.absolutePath,
                                        "size" to if (child.isFile) child.length() else 0L,
                                        "isDirectory" to child.isDirectory
                                    ))
                                }
                                entries.sortWith(compareBy<Map<String, Any>> {
                                    !(it["isDirectory"] as Boolean)
                                }.thenBy {
                                    (it["name"] as String).lowercase()
                                })
                            }
                            runOnUiThread { result.success(entries) }
                        } catch (e: Exception) {
                            runOnUiThread { result.error("LIST_ERROR", e.message, null) }
                        }
                    }.start()
                }
                "getStorageDirectories" -> {
                    val dirs = ArrayList<Map<String, String>>()
                    // Internal storage
                    dirs.add(mapOf(
                        "name" to "Internal Storage",
                        "path" to Environment.getExternalStorageDirectory().absolutePath
                    ))
                    // Common directories
                    val commonDirs = arrayOf("Download", "Documents", "DCIM", "Pictures", "Music", "Movies")
                    for (d in commonDirs) {
                        val dir = File(Environment.getExternalStorageDirectory(), d)
                        if (dir.exists()) {
                            dirs.add(mapOf("name" to d, "path" to dir.absolutePath))
                        }
                    }
                    result.success(dirs)
                }
                "hasStoragePermission" -> {
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
                        result.success(Environment.isExternalStorageManager())
                    } else {
                        result.success(true)
                    }
                }
                "requestStoragePermission" -> {
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
                        if (!Environment.isExternalStorageManager()) {
                            try {
                                val intent = Intent(android.provider.Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION)
                                startActivity(intent)
                                result.success(true)
                            } catch (e: Exception) {
                                result.error("PERM_ERROR", e.message, null)
                            }
                        } else {
                            result.success(true)
                        }
                    } else {
                        result.success(true)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == VPN_REQUEST_CODE && resultCode == android.app.Activity.RESULT_OK) {
            val intent = Intent(this, DnsFilterVpnService::class.java)
            intent.action = DnsFilterVpnService.ACTION_START
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
        } else {
            super.onActivityResult(requestCode, resultCode, data)
        }
    }

    private fun getInstalledAppsWithPermissions(): List<Map<String, Any>> {
        val list = ArrayList<Map<String, Any>>()
        val pm = packageManager
        val packages = pm.getInstalledPackages(PackageManager.GET_PERMISSIONS)
        
        for (pkg in packages) {
            val isSystemApp = ((pkg.applicationInfo?.flags ?: 0) and ApplicationInfo.FLAG_SYSTEM) != 0
            if (isSystemApp) continue

            val appInfo = HashMap<String, Any>()
            appInfo["appName"] = pkg.applicationInfo?.loadLabel(pm)?.toString() ?: pkg.packageName
            appInfo["packageName"] = pkg.packageName
            
            val permissionsList = ArrayList<String>()
            if (pkg.requestedPermissions != null) {
                for (perm in pkg.requestedPermissions) {
                    permissionsList.add(perm)
                }
            }
            appInfo["permissions"] = permissionsList
            list.add(appInfo)
        }
        return list
    }

    private fun getInstalledAppsSimple(): List<Map<String, Any>> {
        val list = ArrayList<Map<String, Any>>()
        val pm = packageManager
        val packages = pm.getInstalledPackages(0)

        for (pkg in packages) {
            val isSystemApp = ((pkg.applicationInfo?.flags ?: 0) and ApplicationInfo.FLAG_SYSTEM) != 0
            if (isSystemApp) continue
            // Skip our own app
            if (pkg.packageName == packageName) continue

            val appInfo = HashMap<String, Any>()
            appInfo["appName"] = pkg.applicationInfo?.loadLabel(pm)?.toString() ?: pkg.packageName
            appInfo["packageName"] = pkg.packageName
            
            // Extract icon as base64
            try {
                val icon = pm.getApplicationIcon(pkg.applicationInfo!!)
                appInfo["iconBase64"] = encodeIconToBase64(icon)
            } catch (e: Exception) {
                appInfo["iconBase64"] = ""
            }

            list.add(appInfo)
        }
        list.sortBy { (it["appName"] as String).lowercase() }
        return list
    }

    private fun encodeIconToBase64(drawable: Drawable): String {
        val bitmap = if (drawable is BitmapDrawable) {
            drawable.bitmap
        } else {
            val bmp = Bitmap.createBitmap(
                Math.max(1, drawable.intrinsicWidth),
                Math.max(1, drawable.intrinsicHeight),
                Bitmap.Config.ARGB_8888
            )
            val canvas = Canvas(bmp)
            drawable.setBounds(0, 0, canvas.width, canvas.height)
            drawable.draw(canvas)
            bmp
        }
        val outputStream = ByteArrayOutputStream()
        // Compress to PNG, scale down if needed for performance (e.g., 50x50)
        val scaledBitmap = Bitmap.createScaledBitmap(bitmap, 96, 96, true)
        scaledBitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream)
        return Base64.encodeToString(outputStream.toByteArray(), Base64.NO_WRAP)
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun startAppLocker() {
        if (appLockerRunning) return
        appLockerRunning = true
        appLockerThread = Thread {
            Log.d("AppLocker", "App Locker started. Monitoring ${blockedApps.size} apps.")
            val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager

            while (appLockerRunning && !Thread.currentThread().isInterrupted) {
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
                        && currentApp != "com.example.frontend"
                        && blockedApps.contains(currentApp)) {

                        // Get the human-readable name
                        val appName = try {
                            val appInfo = packageManager.getApplicationInfo(currentApp, 0)
                            packageManager.getApplicationLabel(appInfo).toString()
                        } catch (e: Exception) {
                            currentApp
                        }

                        Log.d("AppLocker", "Blocking: $currentApp ($appName)")

                        val blockIntent = Intent(this@MainActivity, BlockedAppActivity::class.java).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
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
                    Log.e("AppLocker", "Error in app locker loop", e)
                    Thread.sleep(2000)
                }
            }
            Log.d("AppLocker", "App Locker stopped.")
        }
        appLockerThread?.isDaemon = true
        appLockerThread?.start()
    }

    private fun stopAppLocker() {
        appLockerRunning = false
        appLockerThread?.interrupt()
        appLockerThread = null
        Log.d("AppLocker", "App Locker stopped by user.")
    }

    override fun onDestroy() {
        super.onDestroy()
        stopAppLocker()
    }
}
