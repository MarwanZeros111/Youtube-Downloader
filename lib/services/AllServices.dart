import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class Services with ChangeNotifier {
  final TextEditingController _urlController = TextEditingController();
  bool _isDownloading = false;
  String _statusMessage = "";
  bool _isDialogVisible = false;
  double _progress = 0.0;
  bool _isPaused = false;
  bool isSuccessfulDownload = false;
  String? buttonString;
  bool isButtonClickable = true;

  StreamSubscription<List<int>>? _downloadSubscription;

  void pasteIn() => _pasteClipboardContent();
  void startDownload(BuildContext context) =>
      _startDownload(_urlController.text, context);
  void showPermissionDialog(BuildContext context) =>
      _showPermissionDialog(context);
  void requestPermission(BuildContext context) => _requestPermission(context);

  TextEditingController get urlController => _urlController;
  bool get isDownloading => _isDownloading;
  String get statusMessage => _statusMessage;
  bool get isDialogVisible => _isDialogVisible;
  bool get isPaused => _isPaused;
  double get progress => _progress;

  Future<void> _requestPermission(BuildContext context) async {
    bool permissionStatus;
    final deviceInfo = await DeviceInfoPlugin().androidInfo;

    if (deviceInfo.version.sdkInt > 32) {
      permissionStatus = await Permission.photos.request().isGranted;
    } else {
      permissionStatus = await Permission.storage.request().isGranted;
    }

    if (permissionStatus) {
      startDownload(context);
    } else {
      showPermissionDialog(context);
    }
    notifyListeners();
  }

  Brightness getTheme(BuildContext context) {
    return MediaQuery.of(context).platformBrightness;
  }

  Future<void> _startDownload(String url, BuildContext context) async {
    bool result = await InternetConnectionChecker().hasConnection;
    if (url.isEmpty) {
      _showDialog('Please Enter A URL', false, context);
      return;
    }

    if (!result) {
      _showDialog('No Internet Connection', false, context);
      return;
    } else {
      if (url.contains('youtube') || url.contains('youtu')) {
        downloadYouTubeVideo(url, context);
      } else {
        _showDialog('Only Youtube Links Please', false, context);
      }
    }
  }

  Future<void> downloadYouTubeVideo(
      String videoUrl, BuildContext context) async {
    var yt = YoutubeExplode();
    _isDownloading = true;
    _statusMessage = "Downloading...";
    notifyListeners();

    try {
      var videoId = extractVideoId(videoUrl);
      if (videoId == null) {
        if (context.mounted) {
          _showDialog('Invalid YouTube video ID or URL', false, context);
        }
        _isDownloading = false;
        _statusMessage = "";
        notifyListeners();
        return;
      }

      var manifest = await yt.videos.streamsClient.getManifest(videoId);
      var streamInfo = manifest.muxed.withHighestBitrate();
      var stream = yt.videos.streamsClient.get(streamInfo);

      var dir = await getTemporaryDirectory();
      var filePath = '${dir.path}/${DateTime.now().toString()}.mp4';
      var file = File(filePath);
      var output = file.openWrite();

      var totalBytes = streamInfo.size.totalBytes;
      var downloadedBytes = 0;

      _downloadSubscription = stream.listen(
        (data) {
          output.add(data);
          downloadedBytes += data.length;
          double progress = downloadedBytes / totalBytes;

          _progress = progress;
          notifyListeners();
        },
        onDone: () async {
          await output.close();
          final result = await ImageGallerySaver.saveFile(filePath);
          if (result['isSuccess']) {
            isSuccessfulDownload = true;
          } else {
            isSuccessfulDownload = false;
          }
          log('Downloaded: ${file.path}');
          yt.close();
          _isDownloading = false;
          _statusMessage =
              isSuccessfulDownload ? "Download Complete" : "Download Failed";
          _progress = 0.0;
          getButtonText();
        },
        onError: (e) {
          if (context.mounted) {
            _showDialog('Something Wrong Happened, Try Again', false, context);
          }
          yt.close();
          _isDownloading = false;
          _statusMessage = "Download Failed";
          _progress = 0.0;
          notifyListeners();
        },
        cancelOnError: true,
      );
    } catch (e) {
      if (context.mounted) {
        _showDialog('Something Wrong Happened, Try Again', false, context);
      }
      yt.close();
      _isDownloading = false;
      _statusMessage = "Download Failed";
      _progress = 0.0;
      notifyListeners();
    }
  }

  void getButtonText() {
    if (isSuccessfulDownload) {
      buttonString = 'Done :)';
      isButtonClickable = false;
      notifyListeners();
    }
    Timer(const Duration(seconds: 3), () {
      buttonString = "Download File";
      isButtonClickable = true;
      notifyListeners();
    });
  }

  void pauseDownload() {
    if (_downloadSubscription != null && !_isPaused) {
      _downloadSubscription!.pause();
      _isPaused = true;
      _statusMessage = "Download Paused";
      notifyListeners();
    }
  }

  void resumeDownload() {
    if (_downloadSubscription != null && _isPaused) {
      _downloadSubscription!.resume();
      _isPaused = false;
      _statusMessage = "Downloading...";
      notifyListeners();
    }
  }

  void cancelDownload(BuildContext context) {
    if (_downloadSubscription != null) {
      _downloadSubscription!.cancel();
      _isDownloading = false;
      _isPaused = false;
      _progress = 0.0;
      _statusMessage = "Download Canceled";
      notifyListeners();
    }
    if (context.mounted) {
      _showDialog('You Canceled The Download', false, context);
    }
  }

  String? extractVideoId(String url) {
    final shortUrlPattern = RegExp(r'youtu\.be\/([a-zA-Z0-9_-]+)');
    final regularUrlPattern = RegExp(r'v=([a-zA-Z0-9_-]+)');
    final embedUrlPattern = RegExp(r'youtube\.com\/embed\/([a-zA-Z0-9_-]+)');
    final shortsUrlPattern = RegExp(r'youtube\.com\/shorts\/([a-zA-Z0-9_-]+)');
    final liveUrlPattern = RegExp(r'youtube\.com\/live\/([a-zA-Z0-9_-]+)');

    var shortMatch = shortUrlPattern.firstMatch(url);
    if (shortMatch != null) {
      return shortMatch.group(1);
    }

    var regularMatch = regularUrlPattern.firstMatch(url);
    if (regularMatch != null) {
      return regularMatch.group(1);
    }

    var embedMatch = embedUrlPattern.firstMatch(url);
    if (embedMatch != null) {
      return embedMatch.group(1);
    }

    var shortsMatch = shortsUrlPattern.firstMatch(url);
    if (shortsMatch != null) {
      return shortsMatch.group(1);
    }

    var liveMatch = liveUrlPattern.firstMatch(url);
    if (liveMatch != null) {
      return liveMatch.group(1);
    }

    return null;
  }

  void _pasteClipboardContent() async {
    ClipboardData? clipboardData = await Clipboard.getData('text/plain');
    if (clipboardData != null) {
      _urlController.text = clipboardData.text!;
    }
    notifyListeners();
  }

  void _showDialog(String message, bool isSuccess, BuildContext context) {
    if (_isDialogVisible) return;
    _isDialogVisible = true;
    notifyListeners();

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Notification'),
          content: Row(
            children: [
              Expanded(child: Text(message)),
              isSuccess
                  ? const Icon(Icons.done, color: Colors.green)
                  : const Icon(Icons.error, color: Colors.red),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
                _isDialogVisible = false;
                notifyListeners();
              },
            ),
          ],
        );
      },
    );
  }

  void _showPermissionDialog(BuildContext context) {
    if (!context.mounted) return; // Check if the widget is still mounted

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Storage Permission Required',
              style: TextStyle(fontSize: 15),
            ),
          ),
          content: const Text('Please grant access to storage to continue.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Settings'),
              onPressed: () {
                openAppSettings();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
