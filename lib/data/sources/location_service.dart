import 'package:geolocator/geolocator.dart';

/// Why a location read could not be obtained.
enum LocationFailure {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
}

/// Thrown by [LocationService] when device state or permission blocks a read.
class LocationServiceException implements Exception {
  const LocationServiceException(this.failure);

  final LocationFailure failure;

  String get message {
    switch (failure) {
      case LocationFailure.serviceDisabled:
        return 'Location services are disabled. Enable them to start tracking.';
      case LocationFailure.permissionDenied:
        return 'Location permission was denied.';
      case LocationFailure.permissionDeniedForever:
        return 'Location permission is permanently denied. '
            'Enable it in Settings to start tracking.';
    }
  }

  @override
  String toString() => 'LocationServiceException: $message';
}

/// Wraps geolocator: graceful permission handling + a single position read.
///
/// The [GeolocatorPlatform] is injectable so the permission flow can be unit
/// tested without a device.
class LocationService {
  LocationService({GeolocatorPlatform? geolocator})
      : _geolocator = geolocator ?? GeolocatorPlatform.instance;

  final GeolocatorPlatform _geolocator;

  static const LocationSettings _settings =
      LocationSettings(accuracy: LocationAccuracy.high);

  /// Ensures services are enabled and permission is granted, requesting it once
  /// if currently denied. Throws [LocationServiceException] on any blocking
  /// state (services off, denied, or permanently denied).
  Future<void> ensurePermission() async {
    if (!await _geolocator.isLocationServiceEnabled()) {
      throw const LocationServiceException(LocationFailure.serviceDisabled);
    }

    var permission = await _geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationServiceException(
        LocationFailure.permissionDeniedForever,
      );
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      throw const LocationServiceException(LocationFailure.permissionDenied);
    }
  }

  /// Verifies permission, then returns the device's current position.
  Future<Position> getCurrentPosition() async {
    await ensurePermission();
    return _geolocator.getCurrentPosition(locationSettings: _settings);
  }

  /// Opens the OS app settings — used to recover from "denied forever".
  Future<bool> openAppSettings() => _geolocator.openAppSettings();
}
