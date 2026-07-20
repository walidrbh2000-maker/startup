package com.khidmeti.utils

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationCompat
import com.khidmeti.R

class NotificationHelper(private val context: Context) {

    companion object {
        const val CHANNEL_DEFAULT = "khidmeti_default"
        const val CHANNEL_MESSAGES = "khidmeti_messages"
        const val CHANNEL_SERVICES = "khidmeti_services"
        const val CHANNEL_LOCATION = "khidmeti_location"
        const val CHANNEL_ALERTS = "khidmeti_alerts"
    }

    private val notificationManager = 
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    /**
     * Crée tous les canaux de notification nécessaires
     */
    fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            
            // Canal par défaut
            val defaultChannel = NotificationChannel(
                CHANNEL_DEFAULT,
                "Notifications générales",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Notifications générales de l'application"
                setShowBadge(true)
                enableLights(true)
                enableVibration(true)
            }

            // Canal messages
            val messagesChannel = NotificationChannel(
                CHANNEL_MESSAGES,
                "Messages",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications de nouveaux messages"
                setShowBadge(true)
                enableLights(true)
                lightColor = context.getColor(R.color.notification_color)
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 250, 250, 250)
            }

            // Canal services
            val servicesChannel = NotificationChannel(
                CHANNEL_SERVICES,
                "Demandes de service",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications des demandes de service"
                setShowBadge(true)
                enableLights(true)
                enableVibration(true)
            }

            // Canal localisation
            val locationChannel = NotificationChannel(
                CHANNEL_LOCATION,
                "Suivi de localisation",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Notifications de suivi de position"
                setShowBadge(false)
                enableLights(false)
                enableVibration(false)
            }

            // Canal alertes
            val alertsChannel = NotificationChannel(
                CHANNEL_ALERTS,
                "Alertes importantes",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Alertes importantes nécessitant une action"
                setShowBadge(true)
                enableLights(true)
                lightColor = android.graphics.Color.RED
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 500, 200, 500)
            }

            // Enregistrer tous les canaux
            notificationManager.createNotificationChannels(
                listOf(
                    defaultChannel,
                    messagesChannel,
                    servicesChannel,
                    locationChannel,
                    alertsChannel
                )
            )
        }
    }

    /**
     * Crée une notification de base
     */
    fun createBasicNotification(
        channelId: String,
        title: String,
        message: String,
        priority: Int = NotificationCompat.PRIORITY_DEFAULT
    ): NotificationCompat.Builder {
        return NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title)
            .setContentText(message)
            .setPriority(priority)
            .setAutoCancel(true)
            .setColor(context.getColor(R.color.notification_color))
    }

    /**
     * Affiche une notification
     */
    fun showNotification(notificationId: Int, notification: android.app.Notification) {
        notificationManager.notify(notificationId, notification)
    }

    /**
     * Annule une notification
     */
    fun cancelNotification(notificationId: Int) {
        notificationManager.cancel(notificationId)
    }

    /**
     * Annule toutes les notifications
     */
    fun cancelAllNotifications() {
        notificationManager.cancelAll()
    }

    /**
     * Vérifie si les notifications sont activées
     */
    fun areNotificationsEnabled(): Boolean {
        return notificationManager.areNotificationsEnabled()
    }

    /**
     * Obtient le nombre de notifications actives
     */
    fun getActiveNotificationsCount(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            notificationManager.activeNotifications.size
        } else {
            0
        }
    }
}