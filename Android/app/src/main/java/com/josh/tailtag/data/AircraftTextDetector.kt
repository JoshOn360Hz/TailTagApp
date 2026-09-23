package com.josh.tailtag.data

import android.content.Context
import android.net.Uri
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions

data class AircraftDetection(val registration: String?, val airline: String?, val confidence: Float)

object AircraftTextDetector {
    private val registrationPatterns = listOf(
        Regex("\\bN[0-9]{1,5}[A-Z]{0,2}\\b"),
        Regex("\\b[GD F]-[A-Z0-9]{3,5}\\b".replace(" ", "")),
        Regex("\\bVH-[A-Z]{3}\\b"),
    )

    private val airlines = listOf(
        "AMERICAN", "DELTA", "UNITED", "SOUTHWEST", "JETBLUE", "ALASKA",
        "BRITISH AIRWAYS", "LUFTHANSA", "AIR FRANCE", "KLM", "EMIRATES",
        "QANTAS", "VIRGIN", "RYANAIR", "EASYJET", "NORWEGIAN", "CATHAY PACIFIC",
        "SINGAPORE", "ANA", "JAL", "TURKISH", "ETIHAD", "QATAR", "SWISS",
        "AUSTRIAN", "SAS", "FINNAIR", "TAP", "IBERIA", "AMERICAN AIRLINES",
    )

    fun detect(context: Context, uri: Uri, onResult: (AircraftDetection) -> Unit) {
        runCatching { InputImage.fromFilePath(context, uri) }
            .onFailure { onResult(AircraftDetection(null, null, 0f)) }
            .onSuccess { image ->
                TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
                    .process(image)
                    .addOnSuccessListener { text ->
                        val lines = text.textBlocks.flatMap { block -> block.lines }.map { it.text.uppercase() }
                        val registration = lines.asSequence()
                            .flatMap { line -> registrationPatterns.asSequence().mapNotNull { pattern -> pattern.find(line)?.value } }
                            .firstOrNull()
                        val airline = airlines.firstOrNull { airlineName -> lines.any { it.contains(airlineName) } }
                            ?.lowercase()
                            ?.replaceFirstChar { it.titlecase() }
                        onResult(AircraftDetection(registration, airline, if (registration != null || airline != null) 0.85f else 0f))
                    }
                    .addOnFailureListener { onResult(AircraftDetection(null, null, 0f)) }
            }
    }
}
