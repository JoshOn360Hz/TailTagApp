package com.josh.tailtag.data

import android.content.ContentResolver
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import com.josh.tailtag.model.SpottingEntry
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.io.FileOutputStream
import java.util.UUID

class TailTagRepository(private val context: Context) {
    private val preferences = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
    private val photoDirectory = File(context.filesDir, "spotting_photos").apply { mkdirs() }

    fun loadEntries(): List<SpottingEntry> = runCatching {
        val raw = preferences.getString(ENTRIES_KEY, null) ?: return emptyList()
        val array = JSONArray(raw)
        buildList {
            for (index in 0 until array.length()) {
                val item = array.getJSONObject(index)
                add(
                    SpottingEntry(
                        id = item.getString("id"),
                        photos = item.getJSONArray("photos").let { photos ->
                            buildList {
                                for (photoIndex in 0 until photos.length()) add(photos.getString(photoIndex))
                            }
                        },
                        registration = item.getString("registration"),
                        airline = item.getString("airline"),
                        location = item.getString("location"),
                        aircraftType = item.optString("aircraftType").takeUnless { it.isBlank() },
                        notes = item.optString("notes").takeUnless { it.isBlank() },
                        timestamp = item.getLong("timestamp"),
                    ),
                )
            }
        }
    }.getOrDefault(emptyList())

    fun saveEntries(entries: List<SpottingEntry>) {
        val array = JSONArray()
        entries.forEach { entry ->
            array.put(
                JSONObject().apply {
                    put("id", entry.id)
                    put("photos", JSONArray(entry.photos))
                    put("registration", entry.registration)
                    put("airline", entry.airline)
                    put("location", entry.location)
                    put("aircraftType", entry.aircraftType.orEmpty())
                    put("notes", entry.notes.orEmpty())
                    put("timestamp", entry.timestamp)
                },
            )
        }
        preferences.edit().putString(ENTRIES_KEY, array.toString()).apply()
    }

    fun copyPhoto(uri: Uri): String? = runCatching {
        val resolver = context.contentResolver
        val source = resolver.openInputStream(uri) ?: return null
        source.use { input ->
            val bytes = input.readBytes()
            val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
            val destination = File(photoDirectory, "${UUID.randomUUID()}.jpg")
            if (bitmap == null) {
                destination.writeBytes(bytes)
            } else {
                val scaled = scale(bitmap, 1800)
                FileOutputStream(destination).use { output ->
                    scaled.compress(Bitmap.CompressFormat.JPEG, 82, output)
                }
                if (scaled !== bitmap) scaled.recycle()
                bitmap.recycle()
            }
            destination.absolutePath
        }
    }.getOrNull()

    fun deletePhoto(path: String) {
        if (path.startsWith(photoDirectory.absolutePath)) File(path).delete()
    }

    fun deleteAllPhotos() {
        photoDirectory.listFiles()?.forEach(File::delete)
    }

    private fun scale(bitmap: Bitmap, maxDimension: Int): Bitmap {
        val largest = maxOf(bitmap.width, bitmap.height)
        if (largest <= maxDimension) return bitmap
        val ratio = maxDimension.toFloat() / largest
        return Bitmap.createScaledBitmap(
            bitmap,
            (bitmap.width * ratio).toInt().coerceAtLeast(1),
            (bitmap.height * ratio).toInt().coerceAtLeast(1),
            true,
        )
    }

    companion object {
        private const val PREFERENCES = "tailtag_data"
        private const val ENTRIES_KEY = "entries"
    }
}
