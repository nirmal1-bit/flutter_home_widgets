package com.example.widgets_testing

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class HomeScreenWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val initializationState = context.getSharedPreferences(
            INIT_PREFS,
            Context.MODE_PRIVATE,
        )
        appWidgetIds.forEach { widgetId ->
            val cardIndex = widgetData.getInt(CARD_INDEX_KEY, 0).coerceIn(0, CARDS.lastIndex)
            val revealed = widgetData.getBoolean(REVEALED_KEY, false)
            val card = CARDS[cardIndex]

            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                setTextViewText(R.id.tv_progress, "Card ${cardIndex + 1} of ${CARDS.size}")
                setTextViewText(R.id.tv_question, card.first)
                setTextViewText(R.id.tv_answer, card.second)
                setTextViewText(R.id.tv_answer_label, if (revealed) "Answer" else "Tap reveal")
                setViewVisibility(R.id.tv_answer, if (revealed) android.view.View.VISIBLE else android.view.View.GONE)
                setTextViewText(R.id.bt_reveal, if (revealed) "Revealed" else "Reveal answer")
                setBoolean(R.id.bt_reveal, "setEnabled", !revealed)
                setBoolean(R.id.bt_next, "setEnabled", revealed)

                val launchIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                )
                setOnClickPendingIntent(R.id.widget_root, launchIntent)

                val revealIntent = HomeWidgetBackgroundIntent.getBroadcast(
                    context,
                    Uri.parse("widgetsTesting://reveal"),
                )
                setOnClickPendingIntent(R.id.bt_reveal, revealIntent)

                val nextIntent = HomeWidgetBackgroundIntent.getBroadcast(
                    context,
                    Uri.parse("widgetsTesting://next"),
                )
                setOnClickPendingIntent(R.id.bt_next, nextIntent)
            }

            val initialized = initializationState.getBoolean("widget_$widgetId", false)
            if (initialized) {
                // Preserve the existing RemoteViews tree to avoid launcher
                // blinking after every flashcard interaction.
                appWidgetManager.partiallyUpdateAppWidget(widgetId, views)
            } else {
                appWidgetManager.updateAppWidget(widgetId, views)
                initializationState.edit().putBoolean("widget_$widgetId", true).apply()
            }
        }
    }

    private companion object {
        const val CARD_INDEX_KEY = "flashcard_index"
        const val REVEALED_KEY = "flashcard_revealed"
        const val INIT_PREFS = "widget_initialization"

        val CARDS = listOf(
            "What is Einstein's photoelectric equation?" to
                "Kₘₐₓ = hf − φ\nKₘₐₓ = ½mv²ₘₐₓ = eVₛ",
            "What is the threshold frequency?" to
                "Minimum frequency for emission.\nf₀ = φ / h",
            "What happens when intensity increases?" to
                "At fixed f > f₀, photocurrent increases, but Kₘₐₓ and Vₛ do not.",
            "What happens when frequency increases?" to
                "Kₘₐₓ and stopping voltage increase.\nKₘₐₓ = h(f − f₀)",
            "What is the threshold wavelength?" to
                "Longest wavelength that ejects electrons.\nλ₀ = hc / φ",
        )
    }
}
