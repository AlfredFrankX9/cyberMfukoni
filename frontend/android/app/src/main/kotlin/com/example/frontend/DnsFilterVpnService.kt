package com.example.frontend

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log
import androidx.core.app.NotificationCompat
import java.io.FileInputStream
import java.io.FileOutputStream
import java.net.InetSocketAddress
import java.nio.ByteBuffer
import java.nio.channels.DatagramChannel

class DnsFilterVpnService : VpnService() {

    companion object {
        private const val TAG = "DnsFilterVpnService"
        const val ACTION_START = "com.example.frontend.START_VPN"
        const val ACTION_STOP = "com.example.frontend.STOP_VPN"
        var isRunning = false
        var blockedCount = 0

        // Dynamic blocklist — updated from Flutter via MethodChannel
        private val _blocklist = java.util.Collections.synchronizedSet(mutableSetOf(
            "malware.test.com",
            "phishing.test.com",
            "tracker.test.com",
            "ads.test.com",
            "google-analytics.com",
            "doubleclick.net"
        ))

        fun updateBlocklist(domains: List<String>) {
            _blocklist.clear()
            _blocklist.addAll(domains)
            Log.d(TAG, "Blocklist updated: ${_blocklist.size} domains")
        }

        fun addToBlocklist(domain: String) {
            _blocklist.add(domain.lowercase())
            Log.d(TAG, "Added to blocklist: $domain")
        }

        fun removeFromBlocklist(domain: String) {
            _blocklist.remove(domain.lowercase())
            Log.d(TAG, "Removed from blocklist: $domain")
        }

        fun getBlocklist(): Set<String> = _blocklist.toSet()
    }

    private var vpnInterface: ParcelFileDescriptor? = null
    private var vpnThread: Thread? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopVpn()
            return START_NOT_STICKY
        }

        if (intent?.action == ACTION_START || intent?.action == null) {
            startVpn()
        }
        return START_STICKY
    }

    private fun startVpn() {
        if (isRunning) return

        createNotificationChannel()
        val notificationIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, notificationIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val notification = NotificationCompat.Builder(this, "dns_vpn_channel")
            .setContentTitle("Guardian DNS Filter Active")
            .setContentText("Protecting you from malicious domains")
            .setSmallIcon(android.R.drawable.ic_secure)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(1, notification, android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        } else {
            startForeground(1, notification)
        }

        try {
            vpnInterface = Builder()
                .setSession("Guardian DNS")
                .addAddress("10.0.0.2", 24)
                .addDnsServer("10.0.0.1") // Force all DNS queries to our virtual router
                .addRoute("10.0.0.1", 32) // Only intercept traffic meant for our DNS server
                .establish()
                
            isRunning = true
            blockedCount = 0
            
            vpnThread = Thread {
                runVpnLoop()
            }
            vpnThread?.start()

            Log.d(TAG, "VPN Service Started")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start VPN", e)
            stopVpn()
        }
    }

    private fun runVpnLoop() {
        val vpnFileDescriptor = vpnInterface?.fileDescriptor ?: return
        val inputStream = FileInputStream(vpnFileDescriptor)
        val outputStream = FileOutputStream(vpnFileDescriptor)
        val packet = ByteArray(32767)

        try {
            while (!Thread.currentThread().isInterrupted && isRunning) {
                val length = inputStream.read(packet)
                if (length > 0) {
                    processPacket(packet, length, outputStream)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "VPN Loop Exception", e)
        } finally {
            inputStream.close()
            outputStream.close()
        }
    }

    private fun processPacket(packet: ByteArray, length: Int, outputStream: FileOutputStream) {
        if (length < 28) return
        
        val versionAndIHL = packet[0].toInt()
        if (versionAndIHL ushr 4 != 4) return // Not IPv4
        
        val ihl = (versionAndIHL and 0x0F) * 4
        if (length < ihl + 8) return
        
        val protocol = packet[9].toInt()
        if (protocol != 17) return // Not UDP
        
        val destPort = ((packet[ihl + 2].toInt() and 0xFF) shl 8) or (packet[ihl + 3].toInt() and 0xFF)
        if (destPort != 53) return // Not DNS
        
        val domain = extractDomain(packet, length, ihl)
        
        if (domain != null && _blocklist.any { domain.contains(it, ignoreCase = true) }) {
            Log.d(TAG, "Blocked DNS request for: $domain")
            blockedCount++
            val response = buildNxDomainResponse(packet, length, ihl)
            outputStream.write(response)
        } else {
            // Forward to real DNS (8.8.8.8)
            Thread {
                forwardDns(packet, length, ihl, outputStream)
            }.start()
        }
    }

    private fun extractDomain(packet: ByteArray, length: Int, ihl: Int): String? {
        try {
            val dnsOffset = ihl + 8
            var pos = dnsOffset + 12
            val sb = StringBuilder()
            
            while (pos < length) {
                val len = packet[pos].toInt() and 0xFF
                if (len == 0) break
                if ((len and 0xC0) == 0xC0) break // Compression pointer
                
                pos++
                if (pos + len > length) break
                
                if (sb.isNotEmpty()) sb.append(".")
                for (i in 0 until len) {
                    sb.append(packet[pos + i].toInt().toChar())
                }
                pos += len
            }
            return sb.toString()
        } catch (e: Exception) {
            return null
        }
    }

    private fun buildNxDomainResponse(request: ByteArray, requestLength: Int, ihl: Int): ByteArray {
        val dnsOffset = ihl + 8
        val response = ByteArray(requestLength)
        System.arraycopy(request, 0, response, 0, requestLength)
        
        // Swap IPs
        for (i in 0..3) {
            val tmp = response[12 + i]
            response[12 + i] = response[16 + i]
            response[16 + i] = tmp
        }
        // Swap Ports
        for (i in 0..1) {
            val tmp = response[ihl + i]
            response[ihl + i] = response[ihl + 2 + i]
            response[ihl + 2 + i] = tmp
        }
        
        // DNS Flags: NXDOMAIN
        response[dnsOffset + 2] = 0x81.toByte()
        response[dnsOffset + 3] = 0x83.toByte()
        response[dnsOffset + 6] = 0
        response[dnsOffset + 7] = 0
        
        // Clear checksums
        response[10] = 0; response[11] = 0
        response[ihl + 6] = 0; response[ihl + 7] = 0
        
        val ipChecksum = calculateChecksum(response, 0, ihl)
        response[10] = (ipChecksum ushr 8).toByte()
        response[11] = (ipChecksum and 0xFF).toByte()
        
        return response
    }

    private fun forwardDns(request: ByteArray, length: Int, ihl: Int, outputStream: FileOutputStream) {
        try {
            val dnsOffset = ihl + 8
            val payloadLen = length - dnsOffset
            val payload = ByteArray(payloadLen)
            System.arraycopy(request, dnsOffset, payload, 0, payloadLen)

            val socket = java.net.DatagramSocket()
            socket.soTimeout = 3000
            val destAddress = java.net.InetAddress.getByName("8.8.8.8")
            val sendPacket = java.net.DatagramPacket(payload, payloadLen, destAddress, 53)
            socket.send(sendPacket)

            val recvBuf = ByteArray(2048)
            val recvPacket = java.net.DatagramPacket(recvBuf, recvBuf.size)
            socket.receive(recvPacket)

            val responseLen = ihl + 8 + recvPacket.length
            val response = ByteArray(responseLen)
            
            System.arraycopy(request, 0, response, 0, ihl + 8)
            System.arraycopy(recvPacket.data, 0, response, ihl + 8, recvPacket.length)

            // Swap IPs
            for (i in 0..3) {
                val tmp = response[12 + i]
                response[12 + i] = response[16 + i]
                response[16 + i] = tmp
            }
            // Swap Ports
            for (i in 0..1) {
                val tmp = response[ihl + i]
                response[ihl + i] = response[ihl + 2 + i]
                response[ihl + 2 + i] = tmp
            }
            
            // Update IP length
            response[2] = (responseLen ushr 8).toByte()
            response[3] = (responseLen and 0xFF).toByte()
            // Update UDP length
            val udpLen = 8 + recvPacket.length
            response[ihl + 4] = (udpLen ushr 8).toByte()
            response[ihl + 5] = (udpLen and 0xFF).toByte()
            
            // Clear checksums
            response[10] = 0; response[11] = 0
            response[ihl + 6] = 0; response[ihl + 7] = 0
            
            val ipChecksum = calculateChecksum(response, 0, ihl)
            response[10] = (ipChecksum ushr 8).toByte()
            response[11] = (ipChecksum and 0xFF).toByte()

            outputStream.write(response)
            socket.close()
        } catch (e: Exception) {
            // Timeout or network error
        }
    }

    private fun calculateChecksum(buf: ByteArray, offset: Int, length: Int): Int {
        var sum = 0
        var i = offset
        var len = length
        while (len > 1) {
            sum += ((buf[i].toInt() and 0xFF) shl 8) or (buf[i + 1].toInt() and 0xFF)
            i += 2
            len -= 2
        }
        if (len > 0) sum += (buf[i].toInt() and 0xFF) shl 8
        while ((sum shr 16) > 0) sum = (sum and 0xFFFF) + (sum shr 16)
        return sum.inv() and 0xFFFF
    }

    private fun stopVpn() {
        isRunning = false
        vpnThread?.interrupt()
        try {
            vpnInterface?.close()
        } catch (e: Exception) {
            Log.e(TAG, "Error closing VPN interface", e)
        }
        vpnInterface = null
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
        Log.d(TAG, "VPN Service Stopped")
    }

    override fun onDestroy() {
        super.onDestroy()
        stopVpn()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "dns_vpn_channel",
                "DNS VPN Filter",
                NotificationManager.IMPORTANCE_LOW
            )
            channel.description = "Background service for Guardian DNS filter"
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }
}
