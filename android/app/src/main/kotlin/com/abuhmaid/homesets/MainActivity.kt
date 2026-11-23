package com.abuhmaid.homesets

import android.Manifest
import android.app.Activity
import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.media.ExifInterface
import android.net.Uri
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.util.Calendar
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val MEDIA_CHANNEL = "com.abuhmaid.homesets/media"
    private val BACKUP_CHANNEL = "com.abuhmaid.homesets/backup"
    private val REMINDERS_CHANNEL = "com.abuhmaid.homesets/reminders"

    private var pendingMediaResult: MethodChannel.Result? = null
    private var pendingBackupResult: MethodChannel.Result? = null
    private var pendingPermissionResult: MethodChannel.Result? = null

    private var exportStagedFilePath: String? = null
    private var importTargetStagingPath: String? = null

    private val REQUEST_CODE_PICK_IMAGE = 1001
    private val REQUEST_CODE_CREATE_BACKUP = 1002
    private val REQUEST_CODE_OPEN_BACKUP = 1003
    private val REQUEST_CODE_POST_NOTIFICATIONS = 2003

    private val executor = Executors.newSingleThreadExecutor()

    private val MAX_RAW_IMAGE_BYTES = 25 * 1024 * 1024L // 25 MB max raw stream limit
    private val MAX_BACKUP_BYTES = 250 * 1024 * 1024L // 250 MB max backup stream limit
    private val MAX_DIMENSION = 2048 // Max pixel width/height to prevent OOM

    companion object {
        const val REMINDER_CHANNEL_ID = "homesets_daily_reminders"
        const val REMINDER_NOTIFICATION_ID = 2001
        const val REMINDER_REQUEST_CODE = 2002
        const val PREFS_NAME = "homesets_reminder_prefs"
        const val KEY_REMINDER_CONSENT = "reminder_consent_enabled"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. Media Channel (P5 Photo Picker)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MEDIA_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickImage" -> {
                    if (pendingMediaResult != null) {
                        result.error("ALREADY_ACTIVE", "A media selection request is already pending", null)
                        return@setMethodCallHandler
                    }
                    pendingMediaResult = result
                    try {
                        val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
                            type = "image/*"
                            addCategory(Intent.CATEGORY_OPENABLE)
                        }
                        startActivityForResult(intent, REQUEST_CODE_PICK_IMAGE)
                    } catch (e: Exception) {
                        pendingMediaResult = null
                        result.error("PICKER_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // 2. Backup & SAF Channel (P6 Manual Backup & Restore)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BACKUP_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "exportBackup" -> {
                    if (pendingBackupResult != null) {
                        result.error("ALREADY_ACTIVE", "A backup operation is already pending", null)
                        return@setMethodCallHandler
                    }
                    val stagedPath = call.argument<String>("stagedFilePath")
                    val suggestedName = call.argument<String>("suggestedFileName") ?: "homesets_backup.homesets"

                    if (stagedPath == null || !File(stagedPath).exists()) {
                        result.error("INVALID_FILE", "Staged backup file does not exist", null)
                        return@setMethodCallHandler
                    }

                    pendingBackupResult = result
                    exportStagedFilePath = stagedPath

                    try {
                        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = "application/octet-stream"
                            putExtra(Intent.EXTRA_TITLE, suggestedName)
                        }
                        startActivityForResult(intent, REQUEST_CODE_CREATE_BACKUP)
                    } catch (e: Exception) {
                        pendingBackupResult = null
                        exportStagedFilePath = null
                        result.error("SAF_ERROR", e.message, null)
                    }
                }
                "importBackup" -> {
                    if (pendingBackupResult != null) {
                        result.error("ALREADY_ACTIVE", "A backup operation is already pending", null)
                        return@setMethodCallHandler
                    }
                    val targetStaging = call.argument<String>("targetStagingPath")
                    if (targetStaging == null) {
                        result.error("INVALID_ARG", "Target staging path is required", null)
                        return@setMethodCallHandler
                    }

                    pendingBackupResult = result
                    importTargetStagingPath = targetStaging

                    try {
                        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = "*/*"
                        }
                        startActivityForResult(intent, REQUEST_CODE_OPEN_BACKUP)
                    } catch (e: Exception) {
                        pendingBackupResult = null
                        importTargetStagingPath = null
                        result.error("SAF_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // 3. Reminders Channel (P6 Daily Local Reminders)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, REMINDERS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "areNotificationsEnabled" -> {
                    result.success(areRemindersEffectivelyEnabled())
                }
                "requestNotificationPermission" -> {
                    if (areRemindersEffectivelyEnabled()) {
                        result.success(true)
                        return@setMethodCallHandler
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        if (pendingPermissionResult != null) {
                            result.error("ALREADY_PENDING", "A permission request is already in progress", null)
                            return@setMethodCallHandler
                        }
                        pendingPermissionResult = result
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                            REQUEST_CODE_POST_NOTIFICATIONS
                        )
                    } else {
                        result.success(areRemindersEffectivelyEnabled())
                    }
                }
                "getNotificationPermissionStatus" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        val hasPermission = ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
                        if (hasPermission) {
                            if (!isNotificationChannelEnabled()) {
                                result.success("channelDisabled")
                            } else {
                                result.success("granted")
                            }
                        } else {
                            val shouldShow = ActivityCompat.shouldShowRequestPermissionRationale(this, Manifest.permission.POST_NOTIFICATIONS)
                            result.success(if (shouldShow) "denied" else "notDetermined")
                        }
                    } else {
                        if (!isNotificationChannelEnabled()) {
                            result.success("channelDisabled")
                        } else {
                            result.success("granted")
                        }
                    }
                }
                "scheduleDailyReminder" -> {
                    if (!areRemindersEffectivelyEnabled()) {
                        result.success(false)
                        return@setMethodCallHandler
                    }
                    val hour = call.argument<Int>("hour") ?: 15
                    val minute = call.argument<Int>("minute") ?: 30
                    val title = call.argument<String>("title") ?: "HOMESETS"
                    val body = call.argument<String>("body") ?: "Ready for your workout?"

                    setupNotificationChannel()
                    val scheduled = scheduleAlarm(hour, minute, title, body)
                    result.success(scheduled)
                }
                "cancelDailyReminder" -> {
                    val cancelled = cancelAlarm()
                    result.success(cancelled)
                }
                "setReminderConsent" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    val committed = try {
                        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                        prefs.edit().putBoolean(KEY_REMINDER_CONSENT, enabled).commit()
                    } catch (e: Exception) {
                        false
                    }
                    result.success(committed)
                }
                "getReminderConsent" -> {
                    val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                    result.success(prefs.getBoolean(KEY_REMINDER_CONSENT, false))
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        // Photo Picker Result
        if (requestCode == REQUEST_CODE_PICK_IMAGE) {
            val result = pendingMediaResult ?: return
            pendingMediaResult = null

            if (resultCode == Activity.RESULT_OK && data != null && data.data != null) {
                val uri = data.data!!
                executor.execute {
                    handleSelectedUriBackground(uri, result)
                }
            } else {
                result.success(null)
            }
        }
        // SAF Create Document (Export) Result
        else if (requestCode == REQUEST_CODE_CREATE_BACKUP) {
            val result = pendingBackupResult ?: return
            val sourcePath = exportStagedFilePath
            pendingBackupResult = null
            exportStagedFilePath = null

            if (resultCode == Activity.RESULT_OK && data != null && data.data != null && sourcePath != null) {
                val destinationUri = data.data!!
                executor.execute {
                    handleBackupExportBackground(sourcePath, destinationUri, result)
                }
            } else {
                result.success(false)
            }
        }
        // SAF Open Document (Import) Result
        else if (requestCode == REQUEST_CODE_OPEN_BACKUP) {
            val result = pendingBackupResult ?: return
            val targetPath = importTargetStagingPath
            pendingBackupResult = null
            importTargetStagingPath = null

            if (resultCode == Activity.RESULT_OK && data != null && data.data != null && targetPath != null) {
                val sourceUri = data.data!!
                executor.execute {
                    handleBackupImportBackground(sourceUri, targetPath, result)
                }
            } else {
                result.success(null)
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_CODE_POST_NOTIFICATIONS) {
            val result = pendingPermissionResult ?: return
            pendingPermissionResult = null

            val isGranted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            val enabled = isGranted && (nm?.areNotificationsEnabled() != false)
            result.success(enabled)
        }
    }

    private fun handleBackupExportBackground(sourcePath: String, destinationUri: Uri, result: MethodChannel.Result) {
        try {
            val sourceFile = File(sourcePath)
            if (!sourceFile.exists()) {
                throw IllegalStateException("Staged backup file not found")
            }

            context.contentResolver.openOutputStream(destinationUri)?.use { outputStream ->
                FileInputStream(sourceFile).use { inputStream ->
                    val buffer = ByteArray(16384)
                    var bytesRead: Int
                    while (inputStream.read(buffer).also { bytesRead = it } != -1) {
                        outputStream.write(buffer, 0, bytesRead)
                    }
                    outputStream.flush()
                }
            } ?: throw IllegalStateException("Could not open output stream for destination URI")

            runOnUiThread {
                result.success(true)
            }
        } catch (e: Exception) {
            runOnUiThread {
                result.error("EXPORT_FAILED", e.message ?: "Failed to write backup to destination", null)
            }
        }
    }

    private fun handleBackupImportBackground(sourceUri: Uri, targetPath: String, result: MethodChannel.Result) {
        val targetFile = File(targetPath)
        try {
            targetFile.parentFile?.mkdirs()
            if (targetFile.exists()) {
                targetFile.delete()
            }

            context.contentResolver.openInputStream(sourceUri)?.use { inputStream ->
                FileOutputStream(targetFile).use { outputStream ->
                    val buffer = ByteArray(16384)
                    var bytesRead: Int
                    var totalRead = 0L
                    while (inputStream.read(buffer).also { bytesRead = it } != -1) {
                        totalRead += bytesRead
                        if (totalRead > MAX_BACKUP_BYTES) {
                            throw IllegalStateException("Selected backup archive exceeds maximum allowed size of 250MB")
                        }
                        outputStream.write(buffer, 0, bytesRead)
                    }
                    outputStream.flush()
                }
            } ?: throw IllegalStateException("Could not open input stream from source URI")

            if (!targetFile.exists() || targetFile.length() == 0L) {
                throw IllegalStateException("Imported backup file is empty")
            }

            runOnUiThread {
                result.success(targetFile.absolutePath)
            }
        } catch (e: Exception) {
            if (targetFile.exists()) {
                targetFile.delete()
            }
            runOnUiThread {
                result.error("IMPORT_FAILED", e.message ?: "Failed to read backup from source", null)
            }
        }
    }

    private fun handleSelectedUriBackground(uri: Uri, result: MethodChannel.Result) {
        val stagingDir = File(context.cacheDir, "progress_staging")
        if (!stagingDir.exists()) {
            stagingDir.mkdirs()
        }
        val rawTempFile = File(stagingDir, "raw_${System.currentTimeMillis()}.tmp")
        val finalStageFile = File(stagingDir, "stage_${System.currentTimeMillis()}.jpg")

        try {
            // 1. Bounded copy of incoming stream to a temporary raw file (max 25MB)
            context.contentResolver.openInputStream(uri)?.use { inputStream ->
                FileOutputStream(rawTempFile).use { outputStream ->
                    val buffer = ByteArray(8192)
                    var bytesRead: Int
                    var totalRead = 0L
                    while (inputStream.read(buffer).also { bytesRead = it } != -1) {
                        totalRead += bytesRead
                        if (totalRead > MAX_RAW_IMAGE_BYTES) {
                            throw IllegalStateException("Selected image exceeds maximum allowed size of 25MB")
                        }
                        outputStream.write(buffer, 0, bytesRead)
                    }
                }
            } ?: throw IllegalStateException("Could not open input stream from content URI")

            if (!rawTempFile.exists() || rawTempFile.length() == 0L) {
                throw IllegalStateException("Selected image file is empty")
            }

            // 2. Decode bounds to check dimensions & prevent OOM
            val boundsOptions = BitmapFactory.Options().apply {
                inJustDecodeBounds = true
            }
            BitmapFactory.decodeFile(rawTempFile.absolutePath, boundsOptions)
            if (boundsOptions.outWidth <= 0 || boundsOptions.outHeight <= 0) {
                throw IllegalArgumentException("Invalid image: could not decode dimensions")
            }

            // 3. Compute inSampleSize if dimensions exceed MAX_DIMENSION
            var sampleSize = 1
            while (boundsOptions.outWidth / sampleSize > MAX_DIMENSION ||
                boundsOptions.outHeight / sampleSize > MAX_DIMENSION) {
                sampleSize *= 2
            }

            val decodeOptions = BitmapFactory.Options().apply {
                inSampleSize = sampleSize
                inPreferredConfig = Bitmap.Config.ARGB_8888
            }

            var decodedBitmap = BitmapFactory.decodeFile(rawTempFile.absolutePath, decodeOptions)
                ?: throw IllegalArgumentException("Image decoding failed: unsupported or corrupted format")

            // 4. Handle EXIF orientation rotation
            try {
                val exif = ExifInterface(rawTempFile.absolutePath)
                val orientation = exif.getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL)
                val rotationAngle = when (orientation) {
                    ExifInterface.ORIENTATION_ROTATE_90 -> 90f
                    ExifInterface.ORIENTATION_ROTATE_180 -> 180f
                    ExifInterface.ORIENTATION_ROTATE_270 -> 270f
                    else -> 0f
                }
                if (rotationAngle != 0f) {
                    val matrix = Matrix().apply { postRotate(rotationAngle) }
                    val rotatedBitmap = Bitmap.createBitmap(
                        decodedBitmap, 0, 0, decodedBitmap.width, decodedBitmap.height, matrix, true
                    )
                    if (rotatedBitmap != decodedBitmap) {
                        decodedBitmap.recycle()
                        decodedBitmap = rotatedBitmap
                    }
                }
            } catch (_: Exception) {
                // Non-fatal orientation read fallback
            }

            // 5. Re-encode to clean, sanitized JPEG (strips all EXIF/GPS metadata)
            FileOutputStream(finalStageFile).use { outputStream ->
                val compressed = decodedBitmap.compress(Bitmap.CompressFormat.JPEG, 90, outputStream)
                if (!compressed) {
                    throw IllegalStateException("Failed to compress sanitized image to JPEG")
                }
            }
            decodedBitmap.recycle()

            if (!finalStageFile.exists() || finalStageFile.length() == 0L) {
                throw IllegalStateException("Sanitized output image is empty")
            }

            runOnUiThread {
                result.success(finalStageFile.absolutePath)
            }
        } catch (e: Exception) {
            if (finalStageFile.exists()) {
                finalStageFile.delete()
            }
            runOnUiThread {
                result.error("IMPORT_FAILED", e.message ?: "Failed to import photo", null)
            }
        } finally {
            if (rawTempFile.exists()) {
                rawTempFile.delete()
            }
        }
    }

    private fun setupNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "HOMESETS Daily Reminders"
            val descriptionText = "Gentle daily workout reminders"
            val importance = NotificationManager.IMPORTANCE_DEFAULT
            val channel = NotificationChannel(REMINDER_CHANNEL_ID, name, importance).apply {
                description = descriptionText
            }
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun isNotificationChannelEnabled(): Boolean {
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return false
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N && !nm.areNotificationsEnabled()) {
            return false
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            setupNotificationChannel()
            val channel = nm.getNotificationChannel(REMINDER_CHANNEL_ID)
            if (channel != null && channel.importance == NotificationManager.IMPORTANCE_NONE) {
                return false
            }
        }
        return true
    }

    private fun areRemindersEffectivelyEnabled(): Boolean {
        val hasPerm = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
        return hasPerm && isNotificationChannelEnabled()
    }

    private fun scheduleAlarm(hour: Int, minute: Int, title: String, body: String): Boolean {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return false
        return try {
            val intent = Intent(this, HomesetsReminderReceiver::class.java).apply {
                action = HomesetsReminderReceiver.ACTION_DAILY_REMINDER
                putExtra("title", title)
                putExtra("body", body)
            }
            val pendingIntent = PendingIntent.getBroadcast(
                this,
                REMINDER_REQUEST_CODE,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
            )

            val calendar = Calendar.getInstance().apply {
                set(Calendar.HOUR_OF_DAY, hour)
                set(Calendar.MINUTE, minute)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
                if (before(Calendar.getInstance())) {
                    add(Calendar.DAY_OF_YEAR, 1)
                }
            }

            // Use inexact repeating daily alarm to conserve battery and avoid requiring exact alarm permissions
            alarmManager.setInexactRepeating(
                AlarmManager.RTC_WAKEUP,
                calendar.timeInMillis,
                AlarmManager.INTERVAL_DAY,
                pendingIntent
            )
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun cancelAlarm(): Boolean {
        // Enforce fail-closed consent revocation even if AlarmManager cancel fails (P6-NOTIFY-07, P6-NOTIFY-08, P6-NOTIFY-11)
        val consentRevoked = try {
            val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit().putBoolean(KEY_REMINDER_CONSENT, false).commit()
        } catch (e: Exception) {
            false
        }

        val alarmManager = getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return false
        val alarmCancelled = try {
            val intent = Intent(this, HomesetsReminderReceiver::class.java).apply {
                action = HomesetsReminderReceiver.ACTION_DAILY_REMINDER
            }
            val pendingIntent = PendingIntent.getBroadcast(
                this,
                REMINDER_REQUEST_CODE,
                intent,
                PendingIntent.FLAG_NO_CREATE or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
            )
            if (pendingIntent != null) {
                alarmManager.cancel(pendingIntent)
                pendingIntent.cancel()
            }
            // If pendingIntent was null, alarm was already absent: verified idempotent success
            true
        } catch (e: Exception) {
            false
        }
        return consentRevoked && alarmCancelled
    }

    override fun onDestroy() {
        executor.shutdown()
        super.onDestroy()
    }
}
