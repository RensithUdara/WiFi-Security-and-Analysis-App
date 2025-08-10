package com.example.vigilant // Make sure this matches your actual package name

import android.app.AppOpsManager
import android.content.Context
import android.net.TrafficStats
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    // A single, consistent channel name
    private val CHANNEL = "com.vigilant.app/data_usage"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call, result ->
            when (call.method) {
                "hasUsagePermission" -> {
                    result.success(checkUsagePermission())
                }
                // Added the missing method handler
                "getDataUsage" -> {
                    try {
                        val usage = getDataUsage()
                        result.success(usage)
                    } catch (e: Exception) {
                        result.error("UNAVAILABLE", "Data usage not available.", e.toString())
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun checkUsagePermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, android.os.Process.myUid(), packageName)
        } else {
            appOps.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, android.os.Process.myUid(), packageName)
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    // The actual native implementation for getting data usage
    private fun getDataUsage(): Map<String, Long> {
        // These stats are for the entire device since boot
        val mobileRxBytes = TrafficStats.getMobileRxBytes()
        val mobileTxBytes = TrafficStats.getMobileTxBytes()
        val totalRxBytes = TrafficStats.getTotalRxBytes()
        val totalTxBytes = TrafficStats.getTotalTxBytes()

        val mobileBytes = mobileRxBytes + mobileTxBytes
        val totalBytes = totalRxBytes + totalTxBytes

        // WiFi usage is the total minus the mobile usage
        val wifiBytes = totalBytes - mobileBytes

        // Return a map with the results
        return mapOf("wifi" to wifiBytes, "mobile" to mobileBytes)
    }
}
