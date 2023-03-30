import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPage extends StatefulWidget {
  final RouteObserver<ModalRoute<void>> routeObserver;
  final List<Position> positions;

  const MapPage(
      {required this.routeObserver, required this.positions, super.key});

  @override
  MapPageState createState() => MapPageState();
}

class MapPageState extends State<MapPage> with RouteAware {
  GoogleMapController? _gmc;
  StreamSubscription<Position>? _subscription;
  final _kGooglePlex = const CameraPosition(
    target: LatLng(35.12694, 136.28902),
    zoom: 16,
  );

  final locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 100,
  );

  @override
  void initState() {
    super.initState();
    _subscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position? position) {
      debugPrint(position == null
          ? 'Unknown'
          : 'Position: ${position.timestamp}, ${position.latitude}, ${position.longitude}');
      if (position != null) {
        widget.positions.add(position);
        if (_gmc != null) {
          _gmc!.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 16)));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      mapType: MapType.normal,
      initialCameraPosition: _kGooglePlex,
      myLocationEnabled: true,
      onMapCreated: (GoogleMapController controller) => _gmc = controller,
    );
  }

  @override
  void didChangeDependencies() {
    debugPrint('### didChangeDependencies');
    super.didChangeDependencies();
    widget.routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void dispose() async {
    debugPrint('### dispose');
    widget.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() {
    debugPrint('### didPush');
  }

  @override
  void didPop() {
    debugPrint('### didPop');
    if (_gmc != null) {
      _gmc!.dispose();
    }
    if (_subscription != null) {
      _subscription!.cancel();
    }
  }

  @override
  void didPushNext() {
    debugPrint('### didPushNext');
  }

  @override
  void didPopNext() {
    debugPrint('### didPopNext');
  }
}
