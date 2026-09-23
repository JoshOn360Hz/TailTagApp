package com.josh.tailtag.ui

import android.app.Activity
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Shapes
import androidx.compose.material3.Typography
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.view.WindowCompat
import com.josh.tailtag.TailTagViewModel

private val LightBackground = Color(0xFFF7F8FB)
private val LightSurface = Color(0xFFFFFFFF)
private val LightSurfaceVariant = Color(0xFFEEF0F5)
private val DarkBackground = Color(0xFF111318)
private val DarkSurface = Color(0xFF171A21)
private val DarkSurfaceVariant = Color(0xFF252A33)

fun accentColor(name: String): Color = when (name) {
    "red" -> Color(0xFFFF3B30)
    "orange" -> Color(0xFFFF9500)
    "yellow" -> Color(0xFFFFCC00)
    "green" -> Color(0xFF34C759)
    "purple" -> Color(0xFFAF52DE)
    "pink" -> Color(0xFFFF2D55)
    "teal" -> Color(0xFF30B0C7)
    "indigo" -> Color(0xFF5856D6)
    "mint" -> Color(0xFF00C7BE)
    else -> Color(0xFF007AFF)
}

private fun accentContentColor(name: String): Color = when (name) {
    "orange", "yellow", "green", "teal", "mint" -> Color(0xFF17181B)
    else -> Color.White
}

data class AccentOption(val id: String, val name: String, val color: Color)

val accentOptions = listOf(
    AccentOption("blue", "Blue", accentColor("blue")),
    AccentOption("red", "Red", accentColor("red")),
    AccentOption("orange", "Orange", accentColor("orange")),
    AccentOption("yellow", "Yellow", accentColor("yellow")),
    AccentOption("green", "Green", accentColor("green")),
    AccentOption("purple", "Purple", accentColor("purple")),
    AccentOption("pink", "Pink", accentColor("pink")),
    AccentOption("teal", "Teal", accentColor("teal")),
    AccentOption("indigo", "Indigo", accentColor("indigo")),
    AccentOption("mint", "Mint", accentColor("mint")),
)

private val TailTagShapes = Shapes(
    extraSmall = androidx.compose.foundation.shape.RoundedCornerShape(8.dp),
    small = androidx.compose.foundation.shape.RoundedCornerShape(12.dp),
    medium = androidx.compose.foundation.shape.RoundedCornerShape(18.dp),
    large = androidx.compose.foundation.shape.RoundedCornerShape(24.dp),
    extraLarge = androidx.compose.foundation.shape.RoundedCornerShape(28.dp),
)

private val TailTagTypography = Typography(
    headlineLarge = androidx.compose.ui.text.TextStyle(fontSize = 32.sp, lineHeight = 38.sp, fontWeight = FontWeight.Bold),
    headlineMedium = androidx.compose.ui.text.TextStyle(fontSize = 27.sp, lineHeight = 33.sp, fontWeight = FontWeight.Bold),
    titleLarge = androidx.compose.ui.text.TextStyle(fontSize = 22.sp, lineHeight = 28.sp, fontWeight = FontWeight.SemiBold),
    titleMedium = androidx.compose.ui.text.TextStyle(fontSize = 17.sp, lineHeight = 23.sp, fontWeight = FontWeight.SemiBold),
    bodyLarge = androidx.compose.ui.text.TextStyle(fontSize = 16.sp, lineHeight = 23.sp),
    bodyMedium = androidx.compose.ui.text.TextStyle(fontSize = 14.sp, lineHeight = 20.sp),
    labelLarge = androidx.compose.ui.text.TextStyle(fontSize = 14.sp, lineHeight = 20.sp, fontWeight = FontWeight.SemiBold),
)

@Composable
fun TailTagTheme(viewModel: TailTagViewModel, content: @Composable () -> Unit) {
    val systemDark = isSystemInDarkTheme()
    val dark = when (viewModel.colorScheme) {
        "dark" -> true
        "light" -> false
        else -> systemDark
    }
    val accent = accentColor(viewModel.accentName)
    val accentContent = accentContentColor(viewModel.accentName)
    val colors = if (dark) {
        darkColorScheme(
            primary = accent,
            onPrimary = accentContent,
            primaryContainer = accent.copy(alpha = 0.30f),
            onPrimaryContainer = accentContent,
            secondary = accent,
            onSecondary = accentContent,
            background = DarkBackground,
            surface = DarkSurface,
            surfaceVariant = DarkSurfaceVariant,
            onSurfaceVariant = Color(0xFFBFC5D0),
            outline = Color(0xFF8B929E),
            outlineVariant = Color(0xFF454B56),
        )
    } else {
        lightColorScheme(
            primary = accent,
            onPrimary = accentContent,
            primaryContainer = accent.copy(alpha = 0.16f),
            onPrimaryContainer = accentContent,
            secondary = accent,
            onSecondary = accentContent,
            background = LightBackground,
            surface = LightSurface,
            surfaceVariant = LightSurfaceVariant,
            onSurfaceVariant = Color(0xFF5E6470),
            outline = Color(0xFF7C838F),
            outlineVariant = Color(0xFFD4D8E1),
        )
    }
    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            WindowCompat.getInsetsController(window, view).apply {
                isAppearanceLightStatusBars = !dark
                isAppearanceLightNavigationBars = !dark
            }
            window.statusBarColor = colors.background.toArgb()
            window.navigationBarColor = colors.surface.toArgb()
        }
    }
    MaterialTheme(colorScheme = colors, typography = TailTagTypography, shapes = TailTagShapes, content = content)
}
