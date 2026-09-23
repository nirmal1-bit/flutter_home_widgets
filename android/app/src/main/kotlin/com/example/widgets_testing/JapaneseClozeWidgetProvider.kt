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
        val index = widgetData.getInt(INDEX_KEY, 0).coerceIn(0, CARDS.lastIndex)
        val feedback = widgetData.getString(FEEDBACK_KEY, "") ?: ""
        val attempts = widgetData.getInt(ATTEMPTS_KEY, 0)
        val wrongOption = widgetData.getInt(WRONG_OPTION_KEY, -1)
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
                    "wrong" -> "✗ Not quite — try again"
                    "correct" -> "✓ Correct! Next unlocked"
                    else -> "Choose the missing word"
                })
                setTextViewText(
                    R.id.tv_japanese_attempts,
                    if (attempts > 0) "Wrong attempts: $attempts" else "",
                )
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
                if (wrongOption in 0..2 && feedback == "wrong") {
                    setInt(
                        when (wrongOption) {
                            0 -> R.id.bt_japanese_option_0
                            1 -> R.id.bt_japanese_option_1
                            else -> R.id.bt_japanese_option_2
                        },
                        "setBackgroundColor",
                        Color.rgb(190, 55, 55),
                    )
                }
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
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun optionIntent(context: Context, option: Int) =
        HomeWidgetBackgroundIntent.getBroadcast(
            context,
            Uri.parse("widgetsTesting://japanese_option_$option"),
        )

    private data class Card(val sentence: String, val translation: String, val options: List<String>) {
        val completedSentence: String
            get() = sentence.replace("___", options[0])
    }

    private companion object {
        const val INDEX_KEY = "japanese_cloze_index"
        const val FEEDBACK_KEY = "japanese_cloze_feedback"
        const val ATTEMPTS_KEY = "japanese_cloze_attempts"
        const val WRONG_OPTION_KEY = "japanese_cloze_wrong_option"
        val CARDS = listOf(
            Card("わたしは ___ です。", "I am a student.", listOf("学生", "先生", "猫")),
            Card("これは ___ です。", "This is a book.", listOf("本", "水", "山")),
            Card("毎日 ___ を飲みます。", "I drink water every day.", listOf("水", "猫", "学校")),
            Card("___ に行きます。", "I go to school.", listOf("学校", "本", "先生")),
            Card("すしが ___ です。", "I like sushi.", listOf("好き", "行き", "飲み")),
        )
    }
}
