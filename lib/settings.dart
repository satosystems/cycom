import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';

import 'io.dart';

const owner = 'owner';
const repo = 'repo';
const branch = 'branch';
const accessToken = 'accessToken';

Future<dynamic> loadSettings() async {
  const defaultJson =
      '{"$owner": "", "$repo": "", "$branch": "", "$accessToken": ""}';
  late String json;
  final list = await IO.list(filter: RegExp(r'settings\.json'));
  if (list.isNotEmpty) {
    json = await IO.read(list.first) ?? defaultJson;
  } else {
    json = defaultJson;
  }
  return jsonDecode(json);
}

class SettingsPage extends StatefulWidget {
  final RouteObserver<ModalRoute<void>> routeObserver;

  const SettingsPage({required this.routeObserver, super.key});

  @override
  State<StatefulWidget> createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> with RouteAware {
  late Future<Map<String, String>> _future;
  late dynamic _settings;
  late TextEditingController _controllerOfOwner;
  late TextEditingController _controllerOfRepo;
  late TextEditingController _controllerOfBranch;
  late TextEditingController _controllerOfAccessToken;

  void _update(final String key, final String value) {
    _settings[key] = value;
  }

  @override
  void initState() {
    super.initState();
    _future = Future(() async {
      _settings = await loadSettings();
      return _settings;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          _controllerOfOwner = TextEditingController(
              text: snapshot.connectionState == ConnectionState.done
                  ? _settings[owner]
                  : '');
          _controllerOfRepo = TextEditingController(
              text: snapshot.connectionState == ConnectionState.done
                  ? _settings[repo]
                  : '');
          _controllerOfBranch = TextEditingController(
              text: snapshot.connectionState == ConnectionState.done
                  ? _settings[branch]
                  : '');
          _controllerOfAccessToken = TextEditingController(
              text: snapshot.connectionState == ConnectionState.done
                  ? _settings[accessToken]
                  : '');
          return Scaffold(
              appBar: AppBar(
                title: const Text('GitHub'),
              ),
              body: SettingsList(sections: [
                SettingsSection(tiles: <SettingsTile>[
                  SettingsTile.navigation(
                      leading: const Icon(Icons.person),
                      title: const Text('Owner'),
                      value: TextField(
                          controller: _controllerOfOwner,
                          onChanged: (text) => _update(owner, text))),
                  SettingsTile.navigation(
                      leading: const Icon(Icons.table_rows),
                      title: const Text('Repository'),
                      value: TextField(
                          controller: _controllerOfRepo,
                          onChanged: (text) => _update(repo, text))),
                  SettingsTile.navigation(
                      leading: const Icon(Icons.fork_right),
                      title: const Text('Branch'),
                      value: TextField(
                          controller: _controllerOfBranch,
                          onChanged: (text) => _update(branch, text))),
                  SettingsTile.navigation(
                      leading: const Icon(Icons.key),
                      title: const Text('Access Token'),
                      value: TextField(
                          controller: _controllerOfAccessToken,
                          onChanged: (text) => _update(accessToken, text)))
                ])
              ]));
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
    IO
        .write('settings.json', jsonEncode(_settings))
        .then((file) => '### done: $file');
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
