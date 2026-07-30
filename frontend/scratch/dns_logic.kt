package com.example.frontend

import android.util.Log
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import java.nio.ByteBuffer

object DnsPacketParser {
    
    // Checks if the packet is IPv4 UDP directed to port 53
    fun isDnsRequest(packet: ByteArray, length: Int): Boolean {
        if (length < 28) return false // Min IPv4 (20) + UDP (8)
        
        val versionAndIHL = packet[0].toInt()
        val version = versionAndIHL ushr 4
        if (version != 4) return false
        
        val ihl = versionAndIHL and 0x0F
        val ipHeaderLength = ihl * 4
        
        if (length < ipHeaderLength + 8) return false
        
        val protocol = packet[9].toInt()
        if (protocol != 17) return false // 17 is UDP
        
        // UDP dest port is at offset ipHeaderLength + 2
        val destPort = ((packet[ipHeaderLength + 2].toInt() and 0xFF) shl 8) or (packet[ipHeaderLength + 3].toInt() and 0xFF)
        return destPort == 53
    }
    
    // Extracts the domain name from a DNS query
    fun extractDomain(packet: ByteArray, length: Int): String? {
        try {
            val ihl = (packet[0].toInt() and 0x0F) * 4
            val dnsOffset = ihl + 8 // IP + UDP
            
            // DNS Header is 12 bytes
            var pos = dnsOffset + 12
            val sb = StringBuilder()
            
            while (pos < length) {
                val len = packet[pos].toInt() and 0xFF
                if (len == 0) break
                
                // If it's a pointer (compression), we just stop here for simplicity
                if ((len and 0xC0) == 0xC0) break
                
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
    
    // Constructs an NXDOMAIN response for a given request packet
    fun buildNxDomainResponse(request: ByteArray, requestLength: Int): ByteArray {
        val ihl = (request[0].toInt() and 0x0F) * 4
        val dnsOffset = ihl + 8
        
        val response = ByteArray(requestLength)
        System.arraycopy(request, 0, response, 0, requestLength)
        
        // Swap IP addresses
        for (i in 0..3) {
            val tmp = response[12 + i]
            response[12 + i] = response[16 + i]
            response[16 + i] = tmp
        }
        
        // Swap UDP ports
        for (i in 0..1) {
            val tmp = response[ihl + i]
            response[ihl + i] = response[ihl + 2 + i]
            response[ihl + 2 + i] = tmp
        }
        
        // DNS Flags: Set Response, AA, RA, and RCODE=3 (NXDOMAIN)
        // Request flags are at dnsOffset + 2
        response[dnsOffset + 2] = 0x81.toByte() // Standard query response, recursion desired
        response[dnsOffset + 3] = 0x83.toByte() // Recursion available, NXDOMAIN
        
        // Set Answer Count to 0
        response[dnsOffset + 6] = 0
        response[dnsOffset + 7] = 0
        
        // Clear UDP Checksum (optional, 0 means no checksum)
        response[ihl + 6] = 0
        response[ihl + 7] = 0
        
        // (Optional) Recalculate IP Checksum, though many OSes ignore it on TUN interfaces
        response[10] = 0
        response[11] = 0
        val ipChecksum = calculateChecksum(response, 0, ihl)
        response[10] = (ipChecksum ushr 8).toByte()
        response[11] = (ipChecksum and 0xFF).toByte()
        
        return response
    }
    
    fun calculateChecksum(buf: ByteArray, offset: Int, length: Int): Int {
        var sum = 0
        var i = offset
        var len = length
        while (len > 1) {
            sum += ((buf[i].toInt() and 0xFF) shl 8) or (buf[i + 1].toInt() and 0xFF)
            i += 2
            len -= 2
        }
        if (len > 0) {
            sum += (buf[i].toInt() and 0xFF) shl 8
        }
        while ((sum shr 16) > 0) {
            sum = (sum and 0xFFFF) + (sum shr 16)
        }
        return sum.inv() and 0xFFFF
    }
}
