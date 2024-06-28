import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:youtube_downloader_master/services/AllServices.dart';
import 'package:youtube_downloader_master/widgets/AlertMessage.dart';
import 'package:youtube_downloader_master/widgets/DownloadRow.dart';
import 'package:youtube_downloader_master/widgets/Downloadbutton.dart';

import '../widgets/LinkTextField.dart';

class FileDownloader extends StatefulWidget {
  const FileDownloader({super.key});

  @override
  _FileDownloaderState createState() => _FileDownloaderState();
}

class _FileDownloaderState extends State<FileDownloader>
    with WidgetsBindingObserver {
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();

    FlutterNativeSplash.remove();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _showNotification(String title, String body) async {
    var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    var platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xff004254),
          title: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Youtube Downloader",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.download_rounded,
                color: Colors.white,
                size: 28,
              ),
            ],
          ),
        ),
        body: Consumer<Services>(
          builder: (BuildContext context, value, Widget? child) {
            return Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/logo-development.jpg"),
                  fit: BoxFit.fill,
                ),
              ),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(
                    child: SizedBox(
                      height: 200,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const LinkTextfield(),
                          const SizedBox(height: 20),
                          Provider.of<Services>(context, listen: true)
                                  .isDownloading
                              ? const StartDownloadRow()
                              : const DownloadButton(),
                          if (value.statusMessage.isNotEmpty)
                            const AlertMessage(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
