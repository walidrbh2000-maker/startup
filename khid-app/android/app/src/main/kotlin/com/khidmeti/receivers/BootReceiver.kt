package com.khidmeti.receivers

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import com.khidmeti.services.LocationTrackingService

/**
 * Receiver qui démarre automatiquement le service au démarrage du téléphone
 */
class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == "android.intent.action.QUICKBOOT_POWERON") {
            
            println("📱 Démarrage du téléphone détecté")
            
            // Récupérer les préférences pour savoir si on doit redémarrer le service
            val prefs = context.getSharedPreferences("app_prefs", Context.MODE_PRIVATE)
            val shouldTrackLocation = prefs.getBoolean("track_location", false)
            val userId = prefs.getString("user_id", null)
            val isWorker = prefs.getBoolean("is_worker", false)
            
            if (shouldTrackLocation && userId != null) {
                println("🔄 Redémarrage du service de localisation pour user: $userId")
                
                val serviceIntent = Intent(context, LocationTrackingService::class.java).apply {
                    putExtra("userId", userId)
                    putExtra("isWorker", isWorker)
                }
                
                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        context.startForegroundService(serviceIntent)
                    } else {
                        context.startService(serviceIntent)
                    }
                } catch (e: Exception) {
                    // Android 12+ forbids starting a location FGS from BOOT_COMPLETED.
                    // Tracking resumes when the user next opens the app.
                    println("⚠️ Boot FGS start blocked: ${e.message}")
                }
            }
        }
    }
}