package com.example.widgets_testing

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class StudyImageWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val imagePath = widgetData.getString(IMAGE_PATH_KEY, null)
        val title = widgetData.getString(IMAGE_TITLE_KEY, "Study formula")

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.study_image_widget_layout).apply {
                setTextViewText(R.id.tv_image_title, title)
                if (imagePath != null) {
                    setImageViewBitmap(R.id.iv_study_image, BitmapFactory.decodeFile(imagePath))
                    setViewVisibility(R.id.iv_study_image, View.VISIBLE)
                    setViewVisibility(R.id.tv_image_placeholder, View.GONE)
                } else {
                    setViewVisibility(R.id.iv_study_image, View.GONE)
                    setViewVisibility(R.id.tv_image_placeholder, View.VISIBLE)
                }

                val launchIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("widgetsTesting://image"),
                )
                setOnClickPendingIntent(R.id.image_widget_root, launchIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private companion object {
        const val IMAGE_PATH_KEY = "selected_study_image"
        const val IMAGE_TITLE_KEY = "selected_study_image_title"
    }
}
