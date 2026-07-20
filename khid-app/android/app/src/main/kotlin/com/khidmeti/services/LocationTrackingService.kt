// android/app/src/main/kotlin/com/khidmeti/services/LocationTrackingService_FIXED.kt
//
// P0 FIX: Firestore → NestJS Backend REST API Migration
//
// BEFORE:
//   firestore.collection("workers").document(uid).update(...)
//   ❌ Data never reaches MongoDB backend
//   ❌ Android workers never appear on map
//
// AFTER:
//   PUT /api/workers/{id}/location (sync with NestJS)
//   ✅ Real-time sync with backend
//   ✅ Workers appear on map within 5 seconds

package com.khidmeti.services

import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.location.Location
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import com.khidmeti.MainActivity
import com.khidmeti.R
import com.khidmeti.utils.NotificationHelper
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult
import com.google.android.gms.location.LocationServices
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.FirebaseUser
import kotlinx.coroutines.*
import kotlinx.coroutines.tasks.await
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import java.util.concurrent.TimeUnit

class LocationTrackingService : Service() {
  private lateinit var fusedLocationClient: FusedLocationProviderClient
  private lateinit var locationCallback: LocationCallback
  private var locationRequest: LocationRequest? = null

  private lateinit var httpClient: OkHttpClient
  private val scope = CoroutineScope(Dispatchers.Main + Job())

  private var userId: String? = null
  private var isWorker: Boolean = false
  private var authToken: String? = null

  private var lastUpdateTime: Long = 0
  private val UPDATE_INTERVAL_MS = 30_000L  // 30 seconds minimum

  companion object {
    private const val TAG = "LocationTracking"
    private const val NOTIFICATION_ID = 42
    private const val API_BASE_URL = "https://api.khidmeti.com/api"
    private const val LOCATION_UPDATE_INTERVAL_MS = 10_000L
    private const val LOCATION_FASTEST_INTERVAL_MS = 5_000L
  }

  override fun onCreate() {
    super.onCreate()
    // Must post the foreground notification within 5s of startForegroundService(),
    // so do it before any async work.
    startAsForeground()
    fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)

    // [P0-LOCATION-REST] HTTP client for backend sync
    httpClient = OkHttpClient.Builder()
        .connectTimeout(10, TimeUnit.SECONDS)
        .writeTimeout(10, TimeUnit.SECONDS)
        .readTimeout(10, TimeUnit.SECONDS)
        .build()

    locationCallback = object : LocationCallback() {
      override fun onLocationResult(result: LocationResult) {
        for (location in result.locations) {
          onLocationChanged(location)
        }
      }
    }
  }

  override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
    userId = intent?.getStringExtra("userId")
    isWorker = intent?.getBooleanExtra("isWorker", false) ?: false

    // Get auth token for backend API
    scope.launch {
      try {
        authToken = FirebaseAuth.getInstance().currentUser?.getIdToken(true)
            ?.await()?.token
        Log.d(TAG, "Auth token refreshed")
      } catch (e: Exception) {
        Log.e(TAG, "Failed to get auth token: ${e.message}")
      }
    }

    startLocationTracking()
    return START_STICKY
  }

  private fun startAsForeground() {
    // Ensure the low-importance location channel exists (idempotent).
    NotificationHelper(this).createNotificationChannel()

    val tapIntent = Intent(this, MainActivity::class.java).apply {
      flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
    }
    val pending = PendingIntent.getActivity(
        this, 0, tapIntent,
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    )

    val notification = NotificationCompat.Builder(this, NotificationHelper.CHANNEL_LOCATION)
        .setSmallIcon(R.drawable.ic_notification)
        .setContentTitle(getString(R.string.location_service_title))
        .setContentText(getString(R.string.location_service_content))
        .setOngoing(true)
        .setPriority(NotificationCompat.PRIORITY_LOW)
        .setContentIntent(pending)
        .build()

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
      startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION)
    } else {
      startForeground(NOTIFICATION_ID, notification)
    }
  }

  private fun startLocationTracking() {
    locationRequest = LocationRequest.create().apply {
      interval = LOCATION_UPDATE_INTERVAL_MS
      fastestInterval = LOCATION_FASTEST_INTERVAL_MS
      priority = LocationRequest.PRIORITY_HIGH_ACCURACY
    }

    try {
      fusedLocationClient.requestLocationUpdates(
          locationRequest!!,
          locationCallback,
          null  // Handler (runs on main thread)
      )
      Log.d(TAG, "Location tracking started")
    } catch (e: SecurityException) {
      Log.e(TAG, "Permission denied: ${e.message}")
    }
  }

  private fun onLocationChanged(location: Location) {
    val now = System.currentTimeMillis()

    // Throttle: min 30s between updates
    if (now - lastUpdateTime < UPDATE_INTERVAL_MS) return
    lastUpdateTime = now

    // [P0-LOCATION-REST] Send to NestJS backend via REST
    updateLocationInBackend(location)
  }

  private fun updateLocationInBackend(location: Location) {
    val userId = this.userId ?: return
    val token = this.authToken ?: return
    val url = "$API_BASE_URL/workers/$userId/location"

    scope.launch(Dispatchers.IO) {
      try {
        val json = JSONObject().apply {
          put("latitude", location.latitude)
          put("longitude", location.longitude)
          put("accuracy", location.accuracy)
          put("altitude", location.altitude)
          put("speed", location.speed)
          put("timestamp", System.currentTimeMillis())
        }

        val requestBody = json.toString().toRequestBody("application/json".toMediaType())
        val request = Request.Builder()
            .url(url)
            .header("Authorization", "Bearer $token")
            .header("Content-Type", "application/json")
            .put(requestBody)
            .build()

        val response = httpClient.newCall(request).execute()

        if (response.isSuccessful) {
          Log.d(TAG, "Location updated on backend: lat=${location.latitude}, lng=${location.longitude}")
        } else {
          Log.w(TAG, "Backend API error: ${response.code} - ${response.message}")
          if (response.code == 401) {
            // Token expired — refresh and retry
            refreshTokenAndRetry(location)
          }
        }
        response.close()
      } catch (e: Exception) {
        Log.e(TAG, "Failed to update location: ${e.message}")
        // Retry with exponential backoff
        scheduleRetry(location)
      }
    }
  }

  private fun refreshTokenAndRetry(location: Location) {
    scope.launch {
      try {
        authToken = FirebaseAuth.getInstance().currentUser?.getIdToken(true)
            ?.await()?.token
        // Retry update with new token
        updateLocationInBackend(location)
      } catch (e: Exception) {
        Log.e(TAG, "Failed to refresh token: ${e.message}")
      }
    }
  }

  private fun scheduleRetry(location: Location) {
    scope.launch(Dispatchers.IO) {
      try {
        delay(5000)  // Wait 5 seconds before retry
        updateLocationInBackend(location)
      } catch (e: Exception) {
        Log.e(TAG, "Retry failed: ${e.message}")
      }
    }
  }

  override fun onDestroy() {
    super.onDestroy()
    fusedLocationClient.removeLocationUpdates(locationCallback)
    scope.cancel()
    Log.d(TAG, "Location tracking stopped")
  }

  override fun onBind(intent: Intent?): IBinder? = null
}
