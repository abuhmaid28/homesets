package com.abuhmaid.homesets

import android.app.Activity
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.media.ExifInterface
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.abuhmaid.homesets/media"
    private var pendingResult: MethodChannel.Result? = null
    private val REQUEST_CODE_PICK_IMAGE = 1001
    private val executor = Executors.newSingleThreadExecutor()

    private val MAX_RAW_INPUT_BYTES = 25 * 1024 * 1024L // 25 MB max raw stream limit
    private val MAX_DIMENSION = 2048 // Max pixel width/height to prevent OOM

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
                val uri = data.data!!
                executor.execute {
                    handleSelectedUriBackground(uri, result)
                }
            } else {
                result.success(null)
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
                        if (totalRead > MAX_RAW_INPUT_BYTES) {
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

    override fun onDestroy() {
        executor.shutdown()
        super.onDestroy()
    }
}
