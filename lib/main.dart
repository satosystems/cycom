import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'github.dart';
import 'io.dart';
import 'map.dart';
import 'settings.dart';
import 'tracker.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Tracker.requestPermission();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const ListPage(),
      navigatorObservers: [routeObserver],
    );
  }
}

class ListPage extends StatefulWidget {
  const ListPage({super.key});

  @override
  ListPageState createState() => ListPageState();
}

class ListPageState extends State<ListPage> {
  late Future<List<String>> _future;

  @override
  void initState() {
    super.initState();
    _future = Future(() async {
      return await IO.list(filter: RegExp(r'.+\.geojson'));
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
        future: _future,
        builder: (context, snapshot) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Trackers'),
            ),
            drawer: Drawer(
                child: ListView(children: [
              const DrawerHeader(
                  decoration: BoxDecoration(color: Colors.blue),
                  child: Text("Cycom")),
              ListTile(
                title: const Text("GitHub"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) =>
                          SettingsPage(routeObserver: routeObserver)));
                },
              ),
            ])),
            body: snapshot.connectionState == ConnectionState.done
                ? ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      return Card(
                        child: ListTile(
                          title: Text(snapshot.data![index]),
                        ),
                      );
                    })
                : Text(snapshot.connectionState.name),
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                final List<Position> positions = [];
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => MapPage(
                        routeObserver: routeObserver, positions: positions),
                  ),
                );
                debugPrint('### positions.length: ${positions.length}');
                if (positions.isNotEmpty) {
                  setState(() {
                    final tracker = Tracker();
                    tracker.addLocations(positions);
                    final startTimestamp =
                        tracker.firstPosition!.timestamp!.toIso8601String();
                    final filename = '$startTimestamp.geojson';
                    IO.write(filename, tracker.toString()).then((file) {
                      debugPrint('### done: $file');
                      loadSettings()
                          .then((settings) => GitHub.pushFile(
                              settings[accessToken],
                              settings[owner],
                              settings[repo],
                              settings[branch],
                              file,
                              'Add by Cycom',
                              'Cycom',
                              'cycom@example.com'))
                          .then((isSucceeded) {
                        if (isSucceeded) {
                          debugPrint('### push complete: $filename');
                        } else {
                          debugPrint('### push failed: $filename');
                        }
                      }).then((_) => {});
                    });
                    snapshot.data!.add(filename);
                  });
                }
              },
              child: const Icon(Icons.add),
            ),
          );
        });
  }
}
