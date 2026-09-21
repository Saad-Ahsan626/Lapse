package io.github.saad_ahsan626.lapse

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val mainHandler = Handler(Looper.getMainLooper())
    private val io: ExecutorService = Executors.newSingleThreadExecutor()

    private var pendingResult: MethodChannel.Result? = null
    private var pendingBytes: ByteArray? = null
    private var pendingRequest = 0

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result -> handle(call, result) }
    }

    override fun onDestroy() {
        pendingResult?.success(if (pendingRequest == REQUEST_SAVE) false else null)
        pendingResult = null
        pendingBytes = null
        io.shutdown()
        super.onDestroy()
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "openNotificationSettings" -> {
                openNotificationSettings()
                result.success(null)
            }
            "appVersion" -> result.success(appVersion())
            "isIgnoringBatteryOptimizations" ->
                result.success(isIgnoringBatteryOptimizations())
            "openBatterySettings" -> {
                openBatterySettings()
                result.success(null)
            }
            "saveDocument" -> saveDocument(call, result)
            "openDocument" -> openDocument(call, result)
            else -> result.notImplemented()
        }
    }

    private fun openNotificationSettings() {
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
        } else {
            appDetailsIntent()
        }
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }

    private fun appVersion(): Map<String, String> {
        val info = packageInfo()
        val build = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            info.longVersionCode
        } else {
            @Suppress("DEPRECATION")
            info.versionCode.toLong()
        }
        return mapOf(
            "name" to (info.versionName ?: "0.0.0"),
            "build" to build.toString(),
        )
    }

    private fun packageInfo(): PackageInfo =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            packageManager.getPackageInfo(
                packageName,
                PackageManager.PackageInfoFlags.of(0),
            )
        } else {
            @Suppress("DEPRECATION")
            packageManager.getPackageInfo(packageName, 0)
        }

    private fun isIgnoringBatteryOptimizations(): Boolean {
        val power = getSystemService(POWER_SERVICE) as? PowerManager
            ?: return true
        return power.isIgnoringBatteryOptimizations(packageName)
    }

    private fun openBatterySettings() {
        val batteryIntent = Intent(
            Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS,
        ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        try {
            startActivity(batteryIntent)
        } catch (e: ActivityNotFoundException) {
            startActivity(appDetailsIntent().addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        }
    }

    private fun appDetailsIntent(): Intent =
        Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
            .setData(Uri.fromParts("package", packageName, null))

    private fun saveDocument(call: MethodCall, result: MethodChannel.Result) {
        val fileName = call.argument<String>("fileName")
        val mimeType = call.argument<String>("mimeType")
        val bytes = call.argument<ByteArray>("bytes")
        if (fileName == null || mimeType == null || bytes == null) {
            result.error("bad_args", "fileName, mimeType and bytes are required", null)
            return
        }
        if (!claim(result)) return
        pendingBytes = bytes
        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT)
            .addCategory(Intent.CATEGORY_OPENABLE)
            .setType(mimeType)
            .putExtra(Intent.EXTRA_TITLE, fileName)
        launch(intent, REQUEST_SAVE)
    }

    private fun openDocument(call: MethodCall, result: MethodChannel.Result) {
        val mimeType = call.argument<String>("mimeType") ?: "application/json"
        if (!claim(result)) return
        val types = linkedSetOf(
            mimeType,
            "application/json",
            "text/plain",
            "application/octet-stream",
        ).toTypedArray()
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT)
            .addCategory(Intent.CATEGORY_OPENABLE)
            .setType("*/*")
            .putExtra(Intent.EXTRA_MIME_TYPES, types)
        launch(intent, REQUEST_OPEN)
    }

    private fun claim(result: MethodChannel.Result): Boolean {
        if (pendingResult != null) {
            result.error("busy", "Another document request is in progress", null)
            return false
        }
        pendingResult = result
        pendingRequest = 0
        return true
    }

    @Suppress("DEPRECATION")
    private fun launch(intent: Intent, requestCode: Int) {
        pendingRequest = requestCode
        try {
            startActivityForResult(intent, requestCode)
        } catch (e: ActivityNotFoundException) {
            val result = pendingResult
            pendingResult = null
            pendingBytes = null
            result?.error("unavailable", "No app can handle documents", null)
        }
    }

    @Deprecated("Deprecated in Java")
    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != REQUEST_SAVE && requestCode != REQUEST_OPEN) {
            super.onActivityResult(requestCode, resultCode, data)
            return
        }
        val result = pendingResult ?: return
        val bytes = pendingBytes
        pendingResult = null
        pendingBytes = null
        val uri = data?.data
        val cancelled = resultCode != Activity.RESULT_OK || uri == null
        if (requestCode == REQUEST_SAVE) {
            if (cancelled || bytes == null) {
                result.success(false)
            } else {
                writeDocument(uri!!, bytes, result)
            }
        } else {
            if (cancelled) {
                result.success(null)
            } else {
                readDocument(uri!!, result)
            }
        }
    }

    private fun writeDocument(uri: Uri, bytes: ByteArray, result: MethodChannel.Result) {
        io.execute {
            try {
                val stream = contentResolver.openOutputStream(uri, "wt")
                    ?: throw java.io.IOException("Could not open $uri")
                stream.use { it.write(bytes) }
                mainHandler.post { result.success(true) }
            } catch (e: Exception) {
                mainHandler.post { result.error("write_failed", e.message, null) }
            }
        }
    }

    private fun readDocument(uri: Uri, result: MethodChannel.Result) {
        io.execute {
            try {
                val stream = contentResolver.openInputStream(uri)
                    ?: throw java.io.IOException("Could not open $uri")
                val bytes = stream.use { it.readBytes() }
                mainHandler.post { result.success(bytes) }
            } catch (e: Exception) {
                mainHandler.post { result.error("read_failed", e.message, null) }
            }
        }
    }

    companion object {
        private const val CHANNEL = "lapse/system"
        private const val REQUEST_SAVE = 7301
        private const val REQUEST_OPEN = 7302
    }
}
