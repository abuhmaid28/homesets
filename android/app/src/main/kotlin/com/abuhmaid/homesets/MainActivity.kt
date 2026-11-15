package com.abuhmaid.homesets

import android.net.Uri
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.abuhmaid.homesets/media"
    private var pendingResult: MethodChannel.Result? = null

    // Native Photo Picker launcher (Android 13+ Photo Picker or backported picker contract)
    private val pickVisualMediaLauncher = registerForActivityResult(
        ActivityResultContracts.PickVisualMedia()
    ) { uri: Uri? ->
        handleSelectedUri(uri)
    }

    // Fallback content picker launcher for older Android devices
    private val getContentLauncher = registerForActivityResult(
        ActivityResultContracts.GetContent()
    ) { uri: Uri? ->
        handleSelectedUri(uri)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickImage" -> {
                    if (pendingResult != null) {
                        result.error("ALREADY_ACTIVE", "A media selection request is already pending", null)
                        return@setMethodCallHandler
                    }
                    pendingResult = result
                    try {
                        if (ActivityResultContracts.PickVisualMedia.isPhotoPickerAvailable(this)) {
                            pickVisualMediaLauncher.launch(
                                PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)
                            )
                        } else {
                            getContentLauncher.launch("image/*")
                        }
                    } catch (e: Exception) {
                        pendingResult = null
                        result.error("PICK_FAILED", e.localizedMessage, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun handleSelectedUri(uri: Uri?) {
        val result = pendingResult ?: return
        pendingResult = null

        if (uri == null) {
            result.success(null)
            return
        }

        try {
            // Copy selected URI directly to an app-private cache file
            val inputStream = contentResolver.openInputStream(uri)
            if (inputStream == null) {
                result.error("STREAM_ERROR", "Could not open stream for selected image", null)
                return
            }

            val stagingDir = File(cacheDir, "progress_staging")
            if (!stagingDir.exists()) {
                stagingDir.mkdirs()
            }
            val stagingFile = File(stagingDir, "stage_${System.currentTimeMillis()}.jpg")
            val outputStream = FileOutputStream(stagingFile)

            inputStream.use { input ->
                outputStream.use { output ->
                    input.copyTo(output)
                }
            }

            result.success(stagingFile.absolutePath)
        } catch (e: Exception) {
            result.error("COPY_ERROR", e.localizedMessage, null)
        }
    }
}
