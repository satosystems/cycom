import 'dart:convert';
import 'package:geolocator/geolocator.dart';

class Tracker {
  final List<Position> _positions = [];

  static Future<void> requestPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return Future.error('Location services are disabled.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
  }

  void addLocations(final List<Position> positions) {
    _positions.addAll(positions);
  }

  void addLocation(final Position position) {
    _positions.add(Position(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: position.timestamp ?? DateTime.now(),
        accuracy: position.accuracy,
        altitude: position.altitude,
        heading: position.heading,
        speed: position.speed,
        speedAccuracy: position.speedAccuracy,
        floor: position.floor));
  }

  Future<Tracker> determineLocation() async {
    final position = await Geolocator.getCurrentPosition();
    addLocation(position);

    return this;
  }

  Position? get firstPosition => _positions.isEmpty ? null : _positions[0];

  Position? get lastPosition =>
      _positions.isEmpty ? null : _positions[_positions.length - 1];

  @override
  String toString() {
    return jsonEncode({
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'properties': {
            'vendor': 'Satoshi Ogata',
            'start': firstPosition?.timestamp?.toIso8601String(),
            'end': lastPosition?.timestamp?.toIso8601String()
          },
          'geometry': {'type': 'LineString', 'coordinates': _positions}
        }
      ]
    });
  }
}
