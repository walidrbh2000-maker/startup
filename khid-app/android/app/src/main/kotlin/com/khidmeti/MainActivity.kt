package com.khidmeti

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.khidmeti.services.LocationTrackingService
import com.khidmeti.utils.PermissionManager
import com.khidmeti.utils.NotificationHelper

class MainActivity : FlutterFragmentActivity() {
    
    private val CHANNEL = "com.khidmeti/native"
    private val PERMISSION_REQUEST_CODE = 1001
    
    private lateinit var permissionManager: PermissionManager
    private lateinit var notificationHelper: NotificationHelper
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Initialisation des helpers
        permissionManager = PermissionManager(this)
        notificationHelper = NotificationHelper(this)
        
        // Créer le canal de notification
        notificationHelper.createNotificationChannel()
        
        // Demander les permissions au démarrage
        requestNecessaryPermissions()
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Configuration du channel de communication Flutter <-> Native
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startLocationService" -> {
                    val userId = call.argument<String>("userId")
                    val isWorker = call.argument<Boolean>("isWorker") ?: false
                    
                    if (userId != null) {
                        startLocationService(userId, isWorker)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "userId is required", null)
                    }
                }
                
                "stopLocationService" -> {
                    stopLocationService()
                    result.success(true)
                }
                
                "checkPermissions" -> {
                    val hasPermissions = permissionManager.hasAllRequiredPermissions()
                    result.success(hasPermissions)
                }
                
                "requestPermissions" -> {
                    requestNecessaryPermissions()
                    result.success(true)
                }
                
                "openAppSettings" -> {
                    openAppSettings()
                    result.success(true)
                }
                
                "requestIgnoreBatteryOptimizations" -> {
                    requestIgnoreBatteryOptimizations()
                    result.success(true)
                }
                
                "isIgnoringBatteryOptimizations" -> {
                    val isIgnoring = permissionManager.isIgnoringBatteryOptimizations()
                    result.success(isIgnoring)
                }
                
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun startLocationService(userId: String, isWorker: Boolean) {
        if (!permissionManager.hasLocationPermissions()) {
            requestNecessaryPermissions()
            return
        }
        
        val intent = Intent(this, LocationTrackingService::class.java).apply {
            putExtra("userId", userId)
            putExtra("isWorker", isWorker)
        }
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }
    
    private fun stopLocationService() {
        val intent = Intent(this, LocationTrackingService::class.java)
        stopService(intent)
    }
    
    private fun requestNecessaryPermissions() {
        val permissions = mutableListOf<String>()
        
        // Permissions de localisation
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) 
            != PackageManager.PERMISSION_GRANTED) {
            permissions.add(Manifest.permission.ACCESS_FINE_LOCATION)
        }
        
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION) 
            != PackageManager.PERMISSION_GRANTED) {
            permissions.add(Manifest.permission.ACCESS_COARSE_LOCATION)
        }
        
        // Permission localisation en arrière-plan (Android 10+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_BACKGROUND_LOCATION) 
                != PackageManager.PERMISSION_GRANTED) {
                permissions.add(Manifest.permission.ACCESS_BACKGROUND_LOCATION)
            }
        }
        
        // Permission notifications (Android 13+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) 
                != PackageManager.PERMISSION_GRANTED) {
                permissions.add(Manifest.permission.POST_NOTIFICATIONS)
            }
        }
        
        // Permission enregistrement audio
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) 
            != PackageManager.PERMISSION_GRANTED) {
            permissions.add(Manifest.permission.RECORD_AUDIO)
        }
        
        // Demander les permissions manquantes
        if (permissions.isNotEmpty()) {
            ActivityCompat.requestPermissions(
                this,
                permissions.toTypedArray(),
                PERMISSION_REQUEST_CODE
            )
        }
    }
    
    private fun requestIgnoreBatteryOptimizations() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (!permissionManager.isIgnoringBatteryOptimizations()) {
                val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                    data = Uri.parse("package:$packageName")
                }
                startActivity(intent)
            }
        }
    }
    
    private fun openAppSettings() {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.fromParts("package", packageName, null)
        }
        startActivity(intent)
    }
    
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        
        when (requestCode) {
            PERMISSION_REQUEST_CODE -> {
                val allGranted = grantResults.all { it == PackageManager.PERMISSION_GRANTED }
                
                // Informer Flutter du résultat
                flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                    MethodChannel(messenger, CHANNEL).invokeMethod(
                        "onPermissionsResult",
                        mapOf("granted" to allGranted)
                    )
                }
                
                // Si localisation en premier plan accordée mais pas arrière-plan
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    val hasForeground = grantResults.getOrNull(0) == PackageManager.PERMISSION_GRANTED
                    val hasBackground = permissions.contains(Manifest.permission.ACCESS_BACKGROUND_LOCATION) &&
                            grantResults.last() == PackageManager.PERMISSION_GRANTED
                    
                    if (hasForeground && !hasBackground) {
                        // Demander la permission arrière-plan séparément
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(Manifest.permission.ACCESS_BACKGROUND_LOCATION),
                            PERMISSION_REQUEST_CODE + 1
                        )
                    }
                }
            }
        }
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        
        // Gérer les intents des notifications
        if (intent.action == "FLUTTER_NOTIFICATION_CLICK") {
            val payload = intent.getStringExtra("payload")
            
            flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                MethodChannel(messenger, CHANNEL).invokeMethod(
                    "onNotificationTapped",
                    payload
                )
            }
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        // Ne pas arrêter le service de localisation ici pour qu'il continue en arrière-plan
    }
}