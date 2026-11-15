package com.abuhmaid.homesets

import android.app.Activity
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.abuhmaid.homesets/media"
    private var pendingResult: MethodChannel.Result? = null
    private val REQUEST_CODE_PICK_IMAGE = 1001

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
                        val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
                            type = "image/*"
                            addCategory(Intent.CATEGORY_OPENABLE)
                        }
                        startActivityForResult(intent, REQUEST_CODE_PICK_IMAGE)
                    } catch (e: Exception) {
                        pendingResult = null
                        result.error("PICKER_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE_PICK_IMAGE) {
            val result = pendingResult ?: return
            pendingResult = null

            if (resultCode == Activity.RESULT_OK && data != null && data.data != null) {
                handleSelectedUri(data.data!!, result)
            } else {
                result.success(null)
            }
        }
    }

    private fun handleSelectedUri(uri: Uri, result: MethodChannel.Result) {
        try {
            val stagingDir = File(context.cacheDir, "progress_staging")
            if (!stagingDir.exists()) {
                stagingDir.mkdirs()
            }
            val stageFile = File(stagingDir, "stage_${System.currentTimeMillis()}.jpg")

            context.contentResolver.openInputStream(uri)?.use { inputStream ->
                FileOutputStream(stageFile).use { outputStream ->
                    inputStream.copyTo(outputStream)
                }
            }

            if (stageFile.exists() && stageFile.length() > 0) {
                result.success(stageFile.absolutePath)
            } else {
                result.error("EMPTY_FILE", "Selected image was empty", null)
            }
        } catch (e: Exception) {
            result.error("COPY_FAILED", e.message, null)
        }
    }
}
