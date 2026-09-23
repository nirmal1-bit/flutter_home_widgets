package com.example.widgets_testing

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class JapaneseClozeWidgetProvider : HomeWidgetProvider() {
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
        val index = widgetData.getInt(INDEX_KEY, 0).coerceIn(0, CARDS.lastIndex)
        val feedback = widgetData.getString(FEEDBACK_KEY, "") ?: ""
        val attempts = widgetData.getInt(ATTEMPTS_KEY, 0)
        val card = CARDS[index]
        val correct = feedback == "correct"

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.japanese_cloze_widget_layout).apply {
                setTextViewText(R.id.tv_japanese_progress, "Card ${index + 1} of ${CARDS.size}")
                setTextViewText(
                    R.id.tv_japanese_sentence,
                    if (correct) card.completedSentence else card.sentence,
                )
                setTextViewText(R.id.tv_japanese_translation, card.translation)
                setTextViewText(R.id.tv_japanese_feedback, when (feedback) {
                    "wrong" -> "✗ Not quite — wrong answer $attempts"
                    "correct" -> "✓ Correct! Next unlocked"
                    else -> "Choose the missing word"
                })
                setTextColor(
                    R.id.tv_japanese_feedback,
                    when (feedback) {
                        "wrong" -> Color.rgb(255, 180, 180)
                        "correct" -> Color.rgb(170, 255, 190)
                        else -> Color.rgb(216, 201, 255)
                    },
                )
                setTextViewText(R.id.bt_japanese_option_0, card.options[0])
                setTextViewText(R.id.bt_japanese_option_1, card.options[1])
                setTextViewText(R.id.bt_japanese_option_2, card.options[2])
                setBoolean(R.id.bt_japanese_option_0, "setEnabled", !correct)
                setBoolean(R.id.bt_japanese_option_1, "setEnabled", !correct)
                setBoolean(R.id.bt_japanese_option_2, "setEnabled", !correct)
                setBoolean(R.id.bt_japanese_next, "setEnabled", correct)

                setOnClickPendingIntent(
                    R.id.japanese_widget_root,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
                )
                setOnClickPendingIntent(R.id.bt_japanese_option_0, optionIntent(context, 0))
                setOnClickPendingIntent(R.id.bt_japanese_option_1, optionIntent(context, 1))
                setOnClickPendingIntent(R.id.bt_japanese_option_2, optionIntent(context, 2))
                setOnClickPendingIntent(
                    R.id.bt_japanese_next,
                    HomeWidgetBackgroundIntent.getBroadcast(
                        context,
                        Uri.parse("widgetsTesting://japanese_next"),
                    ),
                )
            }
            val initialized = initializationState.getBoolean("widget_$widgetId", false)
            if (initialized) {
                // Only apply changed properties instead of replacing the whole
                // RemoteViews hierarchy after every answer tap.
                appWidgetManager.partiallyUpdateAppWidget(widgetId, views)
            } else {
                appWidgetManager.updateAppWidget(widgetId, views)
                initializationState.edit().putBoolean("widget_$widgetId", true).apply()
            }
        }
    }

    private fun optionIntent(context: Context, option: Int) =
        HomeWidgetBackgroundIntent.getBroadcast(
            context,
            Uri.parse("widgetsTesting://japanese_option_$option"),
        )

    private data class Card(
        val sentence: String,
        val translation: String,
        val options: List<String>,
        val correctIndex: Int,
    ) {
        val completedSentence: String
            get() = sentence.replace("___", options[correctIndex])
    }

    private companion object {
        const val INDEX_KEY = "japanese_cloze_index"
        const val FEEDBACK_KEY = "japanese_cloze_feedback"
        const val ATTEMPTS_KEY = "japanese_cloze_attempts"
        const val INIT_PREFS = "widget_initialization"
        val CARDS = listOf(
            Card("わたしは ___ です。", "I am a student.", listOf("先生", "学生", "猫"), 1),
            Card("これは ___ です。", "This is a book.", listOf("水", "山", "本"), 2),
            Card("毎日 ___ を飲みます。", "I drink water every day.", listOf("水", "猫", "学校"), 0),
            Card("___ に行きます。", "I go to school.", listOf("本", "学校", "先生"), 1),
            Card("すしが ___ です。", "I like sushi.", listOf("行き", "飲み", "好き"), 2),
        )
    }
}
