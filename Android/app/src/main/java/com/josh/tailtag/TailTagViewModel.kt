package com.josh.tailtag

import android.app.Application
import android.content.Context
import android.net.Uri
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.josh.tailtag.data.TailTagRepository
import com.josh.tailtag.model.SpottingEntry
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class TailTagViewModel(application: Application) : AndroidViewModel(application) {
    private val repository = TailTagRepository(application)
    private val preferences = application.getSharedPreferences("tailtag_settings", Context.MODE_PRIVATE)

    var entries by mutableStateOf(repository.loadEntries())
        private set
    var hasCompletedOnboarding by mutableStateOf(preferences.getBoolean("onboarding_complete", false))
        private set
    var accentName by mutableStateOf(preferences.getString("accent", "blue") ?: "blue")
        private set
    @set:JvmName("setInternalColorScheme")
    var colorScheme by mutableStateOf(preferences.getString("color_scheme", "system") ?: "system")
        private set

    fun completeOnboarding() {
        hasCompletedOnboarding = true
        preferences.edit().putBoolean("onboarding_complete", true).apply()
    }

    fun replayOnboarding() {
        hasCompletedOnboarding = false
        preferences.edit().putBoolean("onboarding_complete", false).apply()
    }

    fun setAccent(name: String) {
        accentName = name
        preferences.edit().putString("accent", name).apply()
    }

    fun setColorScheme(value: String) {
        colorScheme = value
        preferences.edit().putString("color_scheme", value).apply()
    }

    fun addEntry(
        registration: String,
        airline: String,
        location: String,
        aircraftType: String?,
        notes: String?,
        timestamp: Long,
        photoUris: List<Uri>,
    ) {
        viewModelScope.launch(Dispatchers.IO) {
            val photoPaths = photoUris.mapNotNull(repository::copyPhoto)
            val entry = SpottingEntry(
                photos = photoPaths,
                registration = registration.trim(),
                airline = airline.trim(),
                location = location.trim(),
                aircraftType = aircraftType?.trim()?.takeUnless(String::isNullOrBlank),
                notes = notes?.trim()?.takeUnless(String::isNullOrBlank),
                timestamp = timestamp,
            )
            val updated = listOf(entry) + entries
            repository.saveEntries(updated)
            withContext(Dispatchers.Main) { entries = updated }
        }
    }

    fun updateEntry(entry: SpottingEntry, remainingPhotoPaths: List<String>, newPhotoUris: List<Uri>) {
        viewModelScope.launch(Dispatchers.IO) {
            val newPaths = newPhotoUris.mapNotNull(repository::copyPhoto)
            val finalPaths = remainingPhotoPaths + newPaths
            entry.photos.filterNot(finalPaths::contains).forEach(repository::deletePhoto)
            val updatedEntry = entry.copy(photos = finalPaths)
            val updated = entries.map { if (it.id == entry.id) updatedEntry else it }
            repository.saveEntries(updated)
            withContext(Dispatchers.Main) { entries = updated }
        }
    }

    fun deleteEntry(entry: SpottingEntry) {
        entry.photos.forEach(repository::deletePhoto)
        val updated = entries.filterNot { it.id == entry.id }
        entries = updated
        viewModelScope.launch(Dispatchers.IO) { repository.saveEntries(updated) }
    }

    fun resetApp() {
        entries.flatMap(SpottingEntry::photos).forEach(repository::deletePhoto)
        entries = emptyList()
        repository.deleteAllPhotos()
        preferences.edit().clear().apply()
        hasCompletedOnboarding = false
        accentName = "blue"
        colorScheme = "system"
        viewModelScope.launch(Dispatchers.IO) { repository.saveEntries(emptyList()) }
    }
}
