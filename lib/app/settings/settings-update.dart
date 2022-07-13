import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/common/app-updater.dart';
import '../../core/common/snack-bar.dart';

class SettingsUpdate extends StatefulWidget {
  const SettingsUpdate({Key? key}) : super(key: key);

  @override
  State<SettingsUpdate> createState() => _SettingsUpdateState();
}

class _SettingsUpdateState extends State<SettingsUpdate> {
  final _appUpdater = AppUpdater();
  String? _version, _lastVersion, _lastVersionUrl;
  bool _loading = false;

  @override
  void initState() {
    AppUpdater.getCurrentVersion().then((version) {
      if (mounted) setState(() => _version = version);
    });
    super.initState();
  }

  Future<bool> _checkUpdates() async {
    final value = await _appUpdater.checkForUpdates();
    if (value != null) {
      _lastVersionUrl = value.left;
      _lastVersion = value.right;
      if (mounted) setState(() => null);
    }
    return value != null;
  }

  Future<void> _update() async {
    if (_lastVersionUrl != null) {
      setState(() => _loading = true);
      try {
        await _appUpdater.install(_lastVersionUrl!, _lastVersion!);
      } finally {
        _lastVersion = null;
        _lastVersionUrl = null;
        _loading = false;
        if (mounted) setState(() => null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final version = _version;
    if (version == null) {
      return SizedBox();
    }
    return Row(
      children: [
        Text('Версия: $_version', style: const TextStyle(fontSize: 14)),
        Expanded(child: SizedBox()),
        if (Platform.isAndroid)
          Center(
            child: _loading
                ? Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _lastVersion != null &&
                        AppUpdater.compareVersions(_lastVersion!, version) > 0
                    ? TextButton(
                        child: Text('Обновить до $_lastVersion'),
                        onPressed: () => _update(),
                      )
                    : TextButton(
                        child: const Text('Проверить обновления'),
                        onPressed: () async {
                          setState(() => _loading = true);
                          var res = false;
                          try {
                            res = await _checkUpdates();
                          } finally {
                            setState(() => _loading = false);
                            if (!res) {
                              SnackBarHelper.show(context, 'Обновлений нет');
                            }
                          }
                        },
                      ),
          )
      ],
    );
  }
}
