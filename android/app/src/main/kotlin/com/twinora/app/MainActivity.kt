package com.twinora.app

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.twinora/audio_picker"
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "pickAudio") {
                pendingResult = result
                val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
                    type = "audio/*"
                    addCategory(Intent.CATEGORY_OPENABLE)
                }
                startActivityForResult(Intent.createChooser(intent, "Select Audio"), 1001)
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == 1001) {
            val uri: Uri? = data?.data
            if (uri != null) {
                val path = getRealPathFromURI(uri)
                pendingResult?.success(path)
            } else {
                pendingResult?.success(null)
            }
            pendingResult = null
        }
    }

    private fun getRealPathFromURI(uri: Uri): String? {
        val cursor = contentResolver.query(uri, null, null, null, null)
        return cursor?.use {
            it.moveToFirst()
            val idx = it.getColumnIndex(android.provider.OpenableColumns.DISPLAY_NAME)
            if (idx >= 0) {
                val fileName = it.getString(idx)
                val inputStream = contentResolver.openInputStream(uri) ?: return null
                val file = java.io.File(cacheDir, fileName)
                file.outputStream().use { output -> inputStream.copyTo(output) }
                file.absolutePath
            } else null
        }
    }
}
