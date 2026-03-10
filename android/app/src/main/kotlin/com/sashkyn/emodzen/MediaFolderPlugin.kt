package com.sashkyn.emodzen

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Point
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.DocumentsContract
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.io.ByteArrayOutputStream

class MediaFolderPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware,
    PluginRegistry.ActivityResultListener {

    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var pendingResult: MethodChannel.Result? = null

    companion object {
        private const val REQUEST_OPEN_TREE = 9001
        const val CHANNEL = "com.sashkyn.emodzen/media_folder"
        private const val DCIM_CAMERA_URI =
            "content://com.android.externalstorage.documents/tree/primary%3ADCIM%2FCamera"
    }

    // region FlutterPlugin

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    // endregion

    // region ActivityAware

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeActivityResultListener(this)
        activity = null
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) =
        onAttachedToActivity(binding)

    override fun onDetachedFromActivityForConfigChanges() = onDetachedFromActivity()

    // endregion

    // region MethodCallHandler

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "openDocumentTree" -> openDocumentTree(result)
            "listFiles" -> {
                val treeUri = call.argument<String>("treeUri") ?: return result.error("ARGS", "treeUri required", null)
                val recursive = call.argument<Boolean>("recursive") ?: false
                listFiles(treeUri, recursive, result)
            }
            "getDocumentContent" -> {
                val uri = call.argument<String>("uri") ?: return result.error("ARGS", "uri required", null)
                getDocumentContent(uri, result)
            }
            "getDocumentThumbnail" -> {
                val uri = call.argument<String>("uri") ?: return result.error("ARGS", "uri required", null)
                val width = call.argument<Int>("width") ?: 200
                val height = call.argument<Int>("height") ?: 200
                getDocumentThumbnail(uri, width, height, result)
            }
            "getVideoThumbnail" -> {
                val uri = call.argument<String>("uri") ?: return result.error("ARGS", "uri required", null)
                getVideoThumbnail(uri, result)
            }
            else -> result.notImplemented()
        }
    }

    // endregion

    // region ActivityResultListener

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_OPEN_TREE) return false
        val result = pendingResult ?: return false
        pendingResult = null

        if (resultCode != Activity.RESULT_OK || data == null) {
            result.success(null)
            return true
        }

        val uri = data.data ?: run { result.success(null); return true }

        // Persist URI permission across app restarts
        val flags = data.flags and (Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
        try {
            context.contentResolver.takePersistableUriPermission(uri, flags)
        } catch (_: SecurityException) {}

        result.success(uri.toString())
        return true
    }

    // endregion

    // region SAF operations

    private fun openDocumentTree(result: MethodChannel.Result) {
        val act = activity ?: run {
            result.error("NO_ACTIVITY", "Activity not available", null)
            return
        }
        pendingResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            putExtra(DocumentsContract.EXTRA_INITIAL_URI, Uri.parse(DCIM_CAMERA_URI))
        }
        act.startActivityForResult(intent, REQUEST_OPEN_TREE)
    }

    private fun listFiles(treeUriStr: String, recursive: Boolean, result: MethodChannel.Result) {
        Thread {
            try {
                val treeUri = Uri.parse(treeUriStr)
                val files = mutableListOf<Map<String, Any?>>()
                collectFiles(treeUri, DocumentsContract.getTreeDocumentId(treeUri), files, recursive)
                Handler(Looper.getMainLooper()).post { result.success(files) }
            } catch (e: Exception) {
                Handler(Looper.getMainLooper()).post { result.error("LIST_ERROR", e.message, null) }
            }
        }.start()
    }

    private fun collectFiles(
        treeUri: Uri,
        parentDocId: String,
        out: MutableList<Map<String, Any?>>,
        recursive: Boolean,
    ) {
        val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, parentDocId)
        val projection = arrayOf(
            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            DocumentsContract.Document.COLUMN_MIME_TYPE,
            DocumentsContract.Document.COLUMN_LAST_MODIFIED,
        )
        context.contentResolver.query(childrenUri, projection, null, null, null)?.use { cursor ->
            val idCol = cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DOCUMENT_ID)
            val nameCol = cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DISPLAY_NAME)
            val mimeCol = cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_MIME_TYPE)
            val modCol = cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_LAST_MODIFIED)

            while (cursor.moveToNext()) {
                val docId = cursor.getString(idCol)
                val mimeType = cursor.getString(mimeCol)
                val isDir = mimeType == DocumentsContract.Document.MIME_TYPE_DIR
                val docUri = DocumentsContract.buildDocumentUriUsingTree(treeUri, docId)
                out.add(
                    mapOf(
                        "uri" to docUri.toString(),
                        "name" to cursor.getString(nameCol),
                        "mimeType" to mimeType,
                        "lastModifiedMs" to cursor.getLong(modCol),
                        "isDirectory" to isDir,
                    )
                )
                if (isDir && recursive) {
                    collectFiles(treeUri, docId, out, true)
                }
            }
        }
    }

    private fun getDocumentContent(uriStr: String, result: MethodChannel.Result) {
        Thread {
            try {
                val uri = Uri.parse(uriStr)
                val bytes = context.contentResolver.openInputStream(uri)?.use { it.readBytes() }
                Handler(Looper.getMainLooper()).post { result.success(bytes) }
            } catch (e: Exception) {
                Handler(Looper.getMainLooper()).post { result.error("READ_ERROR", e.message, null) }
            }
        }.start()
    }

    private fun getDocumentThumbnail(uriStr: String, width: Int, height: Int, result: MethodChannel.Result) {
        Thread {
            try {
                val uri = Uri.parse(uriStr)
                val bitmap = DocumentsContract.getDocumentThumbnail(
                    context.contentResolver, uri, Point(width, height), null
                )
                if (bitmap != null) {
                    val out = ByteArrayOutputStream()
                    bitmap.compress(Bitmap.CompressFormat.JPEG, 90, out)
                    Handler(Looper.getMainLooper()).post { result.success(out.toByteArray()) }
                } else {
                    Handler(Looper.getMainLooper()).post { result.success(null) }
                }
            } catch (_: Exception) {
                Handler(Looper.getMainLooper()).post { result.success(null) }
            }
        }.start()
    }

    private fun getVideoThumbnail(uriStr: String, result: MethodChannel.Result) {
        Thread {
            try {
                val uri = Uri.parse(uriStr)
                val retriever = MediaMetadataRetriever()
                retriever.setDataSource(context, uri)
                val bitmap = retriever.getFrameAtTime(0, MediaMetadataRetriever.OPTION_CLOSEST_SYNC)
                retriever.release()
                if (bitmap != null) {
                    val out = ByteArrayOutputStream()
                    bitmap.compress(Bitmap.CompressFormat.JPEG, 80, out)
                    Handler(Looper.getMainLooper()).post { result.success(out.toByteArray()) }
                } else {
                    Handler(Looper.getMainLooper()).post { result.success(null) }
                }
            } catch (_: Exception) {
                Handler(Looper.getMainLooper()).post { result.success(null) }
            }
        }.start()
    }

    // endregion
}
