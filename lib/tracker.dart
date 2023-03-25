import 'dart:convert';
import 'package:geolocator/geolocator.dart';

class Tracker {
  final List<List<num>> _locations = [];

  Future<Tracker> determineLocation() async {
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

    final position = await Geolocator.getCurrentPosition();
    _locations.add([
      position.latitude,
      position.longitude,
      position.altitude,
      DateTime.now().microsecondsSinceEpoch
    ]);

    return this;
  }

  DateTime? get firstTrack => _locations.isEmpty
      ? null
      : DateTime.fromMicrosecondsSinceEpoch(_locations[0][3].toInt(),
          isUtc: true);

  DateTime? get lastTrack => _locations.isEmpty
      ? null
      : DateTime.fromMicrosecondsSinceEpoch(
          _locations[_locations.length - 1][3].toInt(),
          isUtc: true);

  @override
  String toString() {
    return jsonEncode({
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'properties': {
            'vendor': 'Satoshi Ogata',
            'start': firstTrack?.toIso8601String(),
            'end': lastTrack?.toIso8601String()
          },
          'geometry': {'type': 'LineString', 'coordinates': _locations}
        }
      ]
    });
  }
}
