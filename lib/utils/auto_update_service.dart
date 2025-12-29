import 'dart:async';
import 'dart:io';
import 'package:android_package_installer/android_package_installer.dart';
import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vx/common/version.dart';
import 'package:vx/main.dart';
import 'package:vx/pref_helper.dart';
import 'package:vx/utils/download.dart';
import 'package:vx/utils/github_release.dart';
import 'package:vx/utils/logger.dart';
import 'package:vx/utils/os.dart';
import 'package:vx/utils/path.dart';
import 'package:window_manager/window_manager.dart';

class AutoUpdateService extends ChangeNotifier {
  final PrefHelper _prefHelper;
  final String _currentVersion;
  Timer? _updateTimer;
  final Downloader _downloader;

  static String _installerSuffix() {
    if (Platform.isWindows) {
      return '.exe';
    } else if (Platform.isAndroid) {
      return '.apk';
    } else if (isRpm()) {
      return '.rpm';
    } else {
      return '.deb';
    }
  }

  static Future<String> assetName() async {
    if (Platform.isAndroid) {
      return 'vx-arm64-v8a.apk.zip';
    } else if (Platform.isWindows) {
      // final ar = await arch();
      return 'VXInstaller.exe';
    } else if (isRpm()) {
      final ar = await arch();
      if (ar.contains('arm64')) {
        return 'vx-arm64.rpm';
      }
      return 'vx-x64.rpm';
    } else {
      final ar = await arch();
      if (ar.contains('arm64')) {
        return 'vx-arm64.deb';
      }
      return 'vx-x64.deb';
    }
  }

  String? downloadingVersion;
  // version and apk file path
  DownloadedInstaller? get hasLocalInstallerToInstall {
    final installer = _prefHelper.downloadedInstaller;
    if (installer == null) {
      return null;
    }
    final localApkVersion = installer.version;
    if (localApkVersion == _currentVersion ||
        !versionNewerThan(localApkVersion, _currentVersion)) {
      _deleteLocalApk();
      return null;
    }
    return installer;
  }

  // a function that checks for whether [currentVersion] is the newest version.
  // if so, return the newest version and the download url.
  // if not, return null.
  final Future<GitHubRelease?> Function(String currentVersion, String assetName)
      _checkForUpdate;

  // Auto-update checks are performed daily (every 24 hours) when enabled
  AutoUpdateService({
    required PrefHelper prefHelper,
    required String currentVersion,
    required Downloader downloader,
    required Future<GitHubRelease?> Function(
            String currentVersion, String assetName)
        checkForUpdate,
  })  : _prefHelper = prefHelper,
        _currentVersion = currentVersion,
        _downloader = downloader,
        _checkForUpdate = checkForUpdate {
    _initialize();
  }

  /// Check if enough time has passed since the last update check
  bool _shouldCheckAndUpdate() {
    if (_prefHelper.downloadedInstaller != null) {
      return true;
    }

    final lastCheckTime = _prefHelper.lastUpdateCheckTime;
    if (lastCheckTime == null) {
      // First time running, should check
      return true;
    }

    final lastCheck = DateTime.fromMillisecondsSinceEpoch(lastCheckTime);
    final now = DateTime.now();
    final timeSinceLastCheck = now.difference(lastCheck);

    // Check if 24 hours have passed
    return timeSinceLastCheck.inHours >= 24;
  }

  /// Get the time remaining until the next update check
  Duration _getTimeUntilNextCheck() {
    final lastCheckTime = _prefHelper.lastUpdateCheckTime;
    if (lastCheckTime == null) {
      return Duration.zero;
    }

    final lastCheck = DateTime.fromMillisecondsSinceEpoch(lastCheckTime);
    final now = DateTime.now();
    final nextCheck = lastCheck.add(const Duration(hours: 24));

    return nextCheck.difference(now);
  }

  void _initialize() {
    // Start auto-update if enabled
    if (_prefHelper.autoUpdate) {
      startAutoUpdate();
    }
  }

  bool get autoUpdate => _prefHelper.autoUpdate;
  void setAutoUpdate(bool value) {
    _prefHelper.setAutoUpdate(value);
    notifyListeners();
    updateAutoUpdateState();
  }

  /// Update auto-update state based on current preferences
  void updateAutoUpdateState() {
    if (_prefHelper.autoUpdate) {
      startAutoUpdate();
      logger.i('Auto-update enabled - will check daily for updates');
    } else {
      stopAutoUpdate();
      logger.i('Auto-update disabled');
    }
  }

  /// Start automatic update checking
  void startAutoUpdate() {
    if (_updateTimer != null) return;

    logger.i('Starting auto-update service');

    // Check if we need to check for updates based on last check time
    if (_shouldCheckAndUpdate()) {
      checkAndUpdate();
    } else {
      final timeUntilNextCheck = _getTimeUntilNextCheck();
      logger.i(
          'Last check was recent, next check in: ${timeUntilNextCheck.inHours}h ${timeUntilNextCheck.inMinutes % 60}m');
    }

    // Schedule daily checks (24 hours)
    const dailyInterval = Duration(hours: 24);
    _updateTimer = Timer.periodic(dailyInterval, (_) => checkAndUpdate());

    logger.i('Auto-update service scheduled to check daily');
  }

  /// Stop automatic update checking
  void stopAutoUpdate() {
    logger.i('Stopping auto-update service');
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  /// Check for updates and install if there is a new version
  Future<void> checkAndUpdate() async {
    logger.i('checkAndUpdate');

    try {
      // _prefHelper.setDownloadedApkPath(join(await getCacheDir(), '2.0.12.apk'));
      // check if there is a previously downloaded apk
      final localInstaller = _prefHelper.downloadedInstaller;
      // get newest version
      final release = await _checkForUpdate(_currentVersion, await assetName());
      if (release != null) {
        final newestVersion = release.version;
        // if local apk exist
        if (localInstaller != null) {
          final localVersion = localInstaller.version;
          // if it is older than the newest version, delete it
          if (localVersion != newestVersion) {
            logger.d('local apk not newest, delete it $localInstaller');
            await _deleteLocalApk();
          } else {
            if (_prefHelper.skipVersion == newestVersion) {
              logger.d('skip this version, delete local apk $localInstaller');
              await _deleteLocalApk();
            } else {
              logger.d('local apk is newest, notify listeners');
              notifyListeners();
            }
            return;
          }
          // no local apk, download it
        }
        if (_prefHelper.skipVersion == newestVersion) {
          logger.d('skip this version, no need to download');
          return;
        }

        downloadingVersion = newestVersion;
        notifyListeners();

        await _downloadToLocal(release).catchError((error) {
          logger.e('Error downloading update', error: error);
        });

        downloadingVersion = null;
        notifyListeners();
      }
      _prefHelper.setLastUpdateCheckTime(DateTime.now().millisecondsSinceEpoch);
    } catch (e, stackTrace) {
      logger.e('_checkAndUpdate', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> _downloadToLocal(GitHubRelease release) async {
    final cacheDir = await getCacheDir();
    final newestDownloadUrl =
        'https://download.5vnetwork.com/${await assetName()}';

    if (Platform.isAndroid) {
      final zipPath = join(cacheDir, '${release.version}.apk.zip');
      logger.d('downloading new apk zip $zipPath');
      await _downloader
          .download(newestDownloadUrl, zipPath)
          .then((value) async {
        logger.d('downloaded new apk zip $zipPath, extract it');
        final apkFolder = zipPath.replaceAll(".apk.zip", "");
        // a folder named ${version} will be created and inside it there is a vx-arm64-v8a.apk
        await extractFileToDisk(zipPath, apkFolder);
        File(zipPath).deleteSync();
        // move the apk out of the folder and delete the folder
        final apkFile = File(join(apkFolder, "vx-arm64-v8a.apk"));
        final newApkFile = apkFile
            .renameSync(join(await getCacheDir(), "${release.version}.apk"));
        Directory(apkFolder).deleteSync(recursive: true);

        _prefHelper.setDownloadedInstallerPath(DownloadedInstaller(
          version: release.version,
          path: newApkFile.path,
          newFeatures: release.body,
        ));
      });
    } else if (Platform.isWindows) {
      final downloadDest =
          join(cacheDir, 'VXInstaller_${release.version}${_installerSuffix()}');
      await _downloader.download(newestDownloadUrl, downloadDest);
      _prefHelper.setDownloadedInstallerPath(DownloadedInstaller(
        version: release.version,
        path: downloadDest,
        newFeatures: release.body,
      ));
    } else if (Platform.isLinux) {
      logger.d(
        'Downloading installer for Linux $newestDownloadUrl',
      );
      final downloadDest =
          join(cacheDir, '${release.version}${_installerSuffix()}');
      await _downloader.download(newestDownloadUrl, downloadDest);
      _prefHelper.setDownloadedInstallerPath(DownloadedInstaller(
        version: release.version,
        path: downloadDest,
        newFeatures: release.body,
      ));
    }
  }

  _deleteLocalApk() {
    final localInstaller = _prefHelper.downloadedInstaller;
    if (localInstaller != null) {
      final apkFile = File(localInstaller.path);
      if (apkFile.existsSync()) {
        apkFile.deleteSync();
      }
      _prefHelper.setDownloadedInstallerPath(null);
      notifyListeners();
    }
  }

  void setSkipVersion(String version) async {
    _prefHelper.setSkipVersion(version);
    await _deleteLocalApk();
  }

  Future<void> installLocalInstaller() async {
    final installer = _prefHelper.downloadedInstaller;
    if (installer == null) {
      throw Exception('No installer found');
    }
    if (Platform.isAndroid) {
      if (File(installer.path).existsSync()) {
        int? statusCode = await AndroidPackageInstaller.installApk(
            apkFilePath: installer.path);
        if (statusCode != null) {
          PackageInstallerStatus installationStatus =
              PackageInstallerStatus.byCode(statusCode);
          if (installationStatus == PackageInstallerStatus.success) {
            await _deleteLocalApk();
          } else {
            throw Exception('Failed to install update: $statusCode');
          }
        }
      } else {
        throw Exception('Installer file not found');
      }
    } else if (Platform.isWindows) {
      await Process.start(
          // runInShell: true,
          // mode: ProcessStartMode.detached,
          'powershell.exe',
          ['-Command', 'Start-Process', installer.path]);
      await exitCurrentApp();
    } else {
      await Process.run('gnome-terminal', [
        '--',
        'bash',
        '-c',
        'echo "Running the following command to update VX:"; echo "sudo ${isRpm() ? 'dnf install' : 'dpkg -i'} ${installer}"; bash'
      ]);
      // await exitCurrentApp();
    }
  }

  @override
  void dispose() {
    stopAutoUpdate();
    super.dispose();
  }
}

class DownloadedInstaller {
  final String version;
  final String path;
  final String newFeatures;

  DownloadedInstaller({
    required this.version,
    required this.path,
    required this.newFeatures,
  });

  factory DownloadedInstaller.fromJson(Map<String, dynamic> json) {
    return DownloadedInstaller(
      version: json['version'],
      path: json['path'],
      newFeatures: json['newFeatures'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'path': path,
      'newFeatures': newFeatures,
    };
  }
}
