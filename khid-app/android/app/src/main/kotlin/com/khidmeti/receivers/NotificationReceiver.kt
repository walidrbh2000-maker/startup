package com.khidmeti.receivers

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Receiver pour gérer les actions des notifications
 */
class NotificationReceiver : BroadcastReceiver() {

    companion object {
        const val ACTION_ACCEPT = "com.khidmeti.ACTION_ACCEPT"
        const val ACTION_DECLINE = "com.khidmeti.ACTION_DECLINE"
        const val ACTION_REPLY = "com.khidmeti.ACTION_REPLY"
        const val EXTRA_REQUEST_ID = "request_id"
        const val EXTRA_NOTIFICATION_ID = "notification_id"
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            ACTION_ACCEPT -> handleAccept(context, intent)
            ACTION_DECLINE -> handleDecline(context, intent)
            ACTION_REPLY -> handleReply(context, intent)
        }
    }

    private fun handleAccept(context: Context, intent: Intent) {
        val requestId = intent.getStringExtra(EXTRA_REQUEST_ID)
        val notificationId = intent.getIntExtra(EXTRA_NOTIFICATION_ID, -1)
        
        println("✅ Action ACCEPT pour demande: $requestId")
        
        // Envoyer l'événement à Flutter via MethodChannel
        // Ceci sera géré par MainActivity
        
        // Annuler la notification
        if (notificationId != -1) {
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) 
                as android.app.NotificationManager
            notificationManager.cancel(notificationId)
        }
    }

    private fun handleDecline(context: Context, intent: Intent) {
        val requestId = intent.getStringExtra(EXTRA_REQUEST_ID)
        val notificationId = intent.getIntExtra(EXTRA_NOTIFICATION_ID, -1)
        
        println("❌ Action DECLINE pour demande: $requestId")
        
        // Annuler la notification
        if (notificationId != -1) {
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) 
                as android.app.NotificationManager
            notificationManager.cancel(notificationId)
        }
    }

    private fun handleReply(context: Context, intent: Intent) {
        println("💬 Action REPLY")
        
        // Ouvrir l'application pour répondre
        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        launchIntent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(launchIntent)
    }
}