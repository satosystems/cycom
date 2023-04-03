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
  final double _zoom = 16;
  GoogleMapController? _gmc;
  StreamSubscription<Position>? _subscription;
  late Future<CameraPosition> _future;
  final locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 100,
  );

  @override
  void initState() {
    super.initState();
    _future = Future(() async {
      final position = await Geolocator.getCurrentPosition();
      return CameraPosition(
          target: LatLng(position.latitude, position.longitude), zoom: _zoom);
    });

    _subscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position? position) {
      debugPrint(position == null
          ? '### Unknown'
          : '### Position: ${position.timestamp}, ${position.latitude}, ${position.longitude}');
      if (position != null) {
        widget.positions.add(position);
        _gmc?.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: _zoom)));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          return snapshot.connectionState == ConnectionState.done
              ? GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: snapshot.data!,
                  myLocationEnabled: true,
                  onMapCreated: (GoogleMapController controller) =>
                      _gmc = controller,
                )
              : Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(snapshot.connectionState.name,
                            style: const TextStyle(fontSize: 24)),
                      ],
                    ),
                  ),
                );
        });
  }

  @override
  void didChangeDependencies() {
    debugPrint('### didChangeDependencies');
    super.didChangeDependencies();
    widget.routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void dispose() {
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
