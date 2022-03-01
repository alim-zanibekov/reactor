import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:reactor/core/preferences/preferences.dart';

import '../http/dio-instance.dart';
import 'pair.dart';
import 'platform.dart';
import 'save-file.dart';

class AppUpdater {
  static final AppUpdater _instance = AppUpdater._internal();

  factory AppUpdater() {
    return _instance;
  }

  AppUpdater._internal();

  final _dio = getDioInstance();
  final _preferences = Preferences();

  Future<Pair<String, String>?> checkForUpdates() async {
    try {
      if (Platform.isAndroid) {
        final version = await getCurrentVersion();
        final res = await _dio.get(
            'https://github.com/alim-zanibekov/reactor/releases/latest',
            options: Options(followRedirects: true));
        var gitVersionRaw = res.realUri.pathSegments.last;
        final gitVersion = gitVersionRaw.replaceAll(RegExp("[^0-9\.\+]"), "");
        if (compareVersions(gitVersion, version) > 0) {
          final apkName = RegExp("\/([^\/]*?\.apk)")
              .firstMatch(res.data as String)
              ?.group(1);
          return Pair(
            'https://github.com/alim-zanibekov/reactor/releases/download/$gitVersionRaw/$apkName',
            gitVersion,
          );
        }
      }
    } catch (err, stacktrace) {
      print(err);
      print(stacktrace);
    }
    return null;
  }

  Future<void> install(String url, String version) async {
    try {
      var filePath = await _getDownloadedApkPath();
      final versionFull = await _getDownloadedApkVersion(filePath);

      if (versionFull == null || versionFull != version) {
        final file = await SaveFile.downloadAndSaveExternal(url, filePath);
        filePath = file.path;
      }

      await AppPlatform.installApk(filePath);
    } catch (err, stacktrace) {
      print(err);
      print(stacktrace);
    }
    return null;
  }

  Future<void> initialCheckUpdates(BuildContext context) async {
    if (!Platform.isAndroid) {
      return;
    }

    final version = await getCurrentVersion();
    {
      final path = await _getDownloadedApkPath();
      final alreadyDownloadedVersion = await _getDownloadedApkVersion(path);
      if (alreadyDownloadedVersion != null &&
          compareVersions(alreadyDownloadedVersion, version) <= 0) {
        await File(path).delete();
      }
    }

    final value = await checkForUpdates();
    if (value != null) {
      final lastVersionUrl = value.left;
      final lastVersion = value.right;

      if (compareVersions(lastVersion, version) > 0 &&
          lastVersion != _preferences.lastAlertVersion) {
        final dialogResult = await showUpdateDialog(context, lastVersion);
        if (dialogResult) {
          await install(lastVersionUrl, lastVersion);
          _preferences.setLastAlertVersion(null);
        } else {
          _preferences.setLastAlertVersion(lastVersion);
        }
      }
    }
  }

  Future<bool> showUpdateDialog(BuildContext context, String version) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Доступно обновление'),
            content: Text('Обновиться до версии $version?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Нет'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Да'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<String> _getDownloadedApkPath() async {
    final storageDir = await getExternalStorageDirectory();
    if (storageDir == null) {
      throw Exception('Can\'t get external storage directory path');
    }

    return storageDir.path + '/reactor.apk';
  }

  Future<String?> _getDownloadedApkVersion(String filePath) async {
    final info = await File(filePath).exists()
        ? await AppPlatform.getApkInfo(filePath)
        : null;

    return info != null ? info.versionFull : null;
  }

  static int compareVersions(String v1, String v2) {
    final v1List = v1
        .split(RegExp("[\.\+]"))
        .map((e) => int.tryParse(e))
        .whereType<int>()
        .toList();
    final v2List = v2
        .split(RegExp("[\.\+]"))
        .map((e) => int.tryParse(e))
        .whereType<int>()
        .toList();
    int cmp = 0;
    for (var i = 0; i < min(v1List.length, v2List.length) && cmp == 0; i++) {
      cmp = v1List[i] - v2List[i];
    }
    if (cmp == 0 && v1List.length != v2List.length) {
      cmp = v1List.length - v2List.length;
    }
    return cmp;
  }

  static Future<String> getCurrentVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (info.buildNumber == "1") {
      return info.version;
    }
    return "${info.version}+${info.buildNumber}";
  }
}
