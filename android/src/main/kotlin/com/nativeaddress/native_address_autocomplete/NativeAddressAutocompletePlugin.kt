package com.nativeaddress.native_address_autocomplete

import android.content.Context
import android.location.Address
import android.location.Geocoder
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.Locale
import java.util.UUID
import java.util.concurrent.Executors
import kotlin.math.asin
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin

/** NativeAddressAutocompletePlugin */
class NativeAddressAutocompletePlugin :
    FlutterPlugin,
    MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    @Volatile
    private var latestRequestId: Int = 0

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "native_address_autocomplete")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        when (call.method) {
            "isAvailable" -> result.success(Geocoder.isPresent())
            "suggestAddresses" -> suggestAddresses(call, result)
            "resolveAddress" -> resolveAddress(call, result)
            else -> result.notImplemented()
        }
    }

    private fun suggestAddresses(
        call: MethodCall,
        result: Result
    ) {
        val query = call.argument<String>("query")?.trim().orEmpty()
        if (query.isEmpty()) {
            result.success(emptyList<Map<String, Any?>>())
            return
        }

        val limit = min(max(call.argument<Int>("limit") ?: 5, 1), 20)
        val countries = call.argument<List<String>>("countries")
            ?.map { it.uppercase(Locale.US) }
            ?.toSet()
            .orEmpty()
        val latitude = call.argument<Double>("latitude")
        val longitude = call.argument<Double>("longitude")
        val radiusMeters = call.argument<Double>("radiusMeters") ?: 50000.0
        val requestId = call.argument<Int>("requestId") ?: latestRequestId + 1
        latestRequestId = requestId

        executor.execute {
            try {
                val geocoder = geocoder(call)
                @Suppress("DEPRECATION")
                val addresses = if (latitude != null && longitude != null) {
                    val bounds = boundingBox(latitude, longitude, radiusMeters)
                    geocoder.getFromLocationName(
                        query,
                        limit,
                        bounds.minLatitude,
                        bounds.minLongitude,
                        bounds.maxLatitude,
                        bounds.maxLongitude
                    )
                } else {
                    geocoder.getFromLocationName(query, limit)
                }.orEmpty()

                val suggestions = addresses
                    .asSequence()
                    .filter { address ->
                        countries.isEmpty() ||
                            address.countryCode?.uppercase(Locale.US)?.let { it in countries } == true
                    }
                    .take(limit)
                    .map(::addressToMap)
                    .toList()

                mainHandler.post {
                    if (requestId == latestRequestId) {
                        result.success(suggestions)
                    } else {
                        result.success(emptyList<Map<String, Any?>>())
                    }
                }
            } catch (error: Exception) {
                mainHandler.post {
                    result.error("autocomplete_failed", error.localizedMessage, null)
                }
            }
        }
    }

    private fun resolveAddress(
        call: MethodCall,
        result: Result
    ) {
        val query = call.argument<String>("fullText")
            ?: call.argument<String>("primaryText")
            ?: ""
        if (query.isBlank()) {
            result.success(null)
            return
        }
        val requestId = call.argument<Int>("requestId") ?: latestRequestId + 1
        latestRequestId = requestId

        executor.execute {
            try {
                @Suppress("DEPRECATION")
                val address = geocoder(call)
                    .getFromLocationName(query, 1)
                    ?.firstOrNull()

                mainHandler.post {
                    if (requestId == latestRequestId) {
                        result.success(address?.let(::addressToResolvedMap) ?: suggestionToResolvedMap(call))
                    } else {
                        result.success(null)
                    }
                }
            } catch (error: Exception) {
                mainHandler.post {
                    result.error("resolve_failed", error.localizedMessage, null)
                }
            }
        }
    }

    private fun addressToMap(address: Address): Map<String, Any?> {
        val fullText = addressLine(address)
        return mapOf(
            "id" to UUID.nameUUIDFromBytes(fullText.toByteArray()).toString(),
            "primaryText" to primaryText(address, fullText),
            "secondaryText" to secondaryText(address),
            "fullText" to fullText,
            "latitude" to if (address.hasLatitude()) address.latitude else null,
            "longitude" to if (address.hasLongitude()) address.longitude else null,
            "countryCode" to address.countryCode,
            "streetNumber" to address.subThoroughfare,
            "street" to address.thoroughfare,
            "city" to address.locality,
            "state" to address.adminArea,
            "postalCode" to address.postalCode,
            "country" to address.countryName
        )
    }

    private fun geocoder(call: MethodCall): Geocoder {
        val localeTag = call.argument<String>("locale")
        val locale = localeTag
            ?.takeIf { it.isNotBlank() }
            ?.let(Locale::forLanguageTag)
            ?: Locale.getDefault()
        return Geocoder(context, locale)
    }

    private fun addressToResolvedMap(address: Address): Map<String, Any?> {
        val fullText = addressLine(address)
        return mapOf(
            "primaryText" to primaryText(address, fullText),
            "secondaryText" to secondaryText(address),
            "fullText" to fullText,
            "streetNumber" to address.subThoroughfare,
            "street" to address.thoroughfare,
            "city" to address.locality,
            "state" to address.adminArea,
            "postalCode" to address.postalCode,
            "country" to address.countryName,
            "countryCode" to address.countryCode,
            "latitude" to if (address.hasLatitude()) address.latitude else null,
            "longitude" to if (address.hasLongitude()) address.longitude else null
        )
    }

    private fun suggestionToResolvedMap(call: MethodCall): Map<String, Any?> {
        return mapOf(
            "primaryText" to call.argument<String>("primaryText"),
            "secondaryText" to call.argument<String>("secondaryText"),
            "fullText" to call.argument<String>("fullText").orEmpty(),
            "streetNumber" to call.argument<String>("streetNumber"),
            "street" to call.argument<String>("street"),
            "city" to call.argument<String>("city"),
            "state" to call.argument<String>("state"),
            "postalCode" to call.argument<String>("postalCode"),
            "country" to call.argument<String>("country"),
            "countryCode" to call.argument<String>("countryCode"),
            "latitude" to call.argument<Double>("latitude"),
            "longitude" to call.argument<Double>("longitude")
        )
    }

    private fun addressLine(address: Address): String {
        return if (address.maxAddressLineIndex >= 0) {
            address.getAddressLine(0)
        } else {
            listOfNotNull(
                address.featureName,
                address.thoroughfare,
                address.locality,
                address.adminArea,
                address.countryName
            ).joinToString(", ")
        }
    }

    private fun primaryText(
        address: Address,
        fallback: String
    ): String {
        return address.featureName
            ?: address.thoroughfare
            ?: address.subLocality
            ?: address.locality
            ?: fallback
    }

    private fun secondaryText(address: Address): String? {
        val parts = listOfNotNull(
            address.locality,
            address.adminArea,
            address.postalCode,
            address.countryName
        ).distinct()
        return parts.takeIf { it.isNotEmpty() }?.joinToString(", ")
    }

    private fun boundingBox(
        latitude: Double,
        longitude: Double,
        radiusMeters: Double
    ): SearchBounds {
        val earthRadiusMeters = 6371000.0
        val radiusRadians = radiusMeters / earthRadiusMeters
        val latitudeRadians = Math.toRadians(latitude)
        val longitudeRadians = Math.toRadians(longitude)

        val minLatitude = latitudeRadians - radiusRadians
        val maxLatitude = latitudeRadians + radiusRadians
        val deltaLongitude = asin(sin(radiusRadians) / cos(latitudeRadians))

        return SearchBounds(
            minLatitude = Math.toDegrees(minLatitude),
            minLongitude = Math.toDegrees(longitudeRadians - deltaLongitude),
            maxLatitude = Math.toDegrees(maxLatitude),
            maxLongitude = Math.toDegrees(longitudeRadians + deltaLongitude)
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}

private data class SearchBounds(
    val minLatitude: Double,
    val minLongitude: Double,
    val maxLatitude: Double,
    val maxLongitude: Double
)
