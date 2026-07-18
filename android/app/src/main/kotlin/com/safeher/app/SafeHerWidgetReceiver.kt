package com.safeher.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class SafeHerWidgetReceiver : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {

        for (widgetId in appWidgetIds) {

            val views = RemoteViews(
                context.packageName,
                R.layout.safeher_widget
            )

            val intent = Intent(
                context,
                MainActivity::class.java
            )

            intent.action = "SAFEHER_WIDGET_SOS"

            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or
                        PendingIntent.FLAG_IMMUTABLE
            )

            views.setOnClickPendingIntent(
    R.id.widget_root,
    pendingIntent
)

            appWidgetManager.updateAppWidget(
                widgetId,
                views
            )

        }

    }

}