import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:slider_button/slider_button.dart';

import '../services/AllServices.dart';

class DownloadButton extends StatelessWidget {
  const DownloadButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<Services>(
      builder: (BuildContext context, value, Widget? child) {
        return SliderButton(
          height: 60,
          disable: value.isDownloading,
          action: () async {
            if (value.isButtonClickable) {
              value.requestPermission(context);
            }
            return value.isDownloading;
          },
          label: Center(
            child: Text(
              value.buttonString ?? 'Download File',
              style: const TextStyle(
                color: Color(0xff004254),
                fontWeight: FontWeight.w500,
                fontSize: 17,
              ),
            ),
          ),
          icon: const Icon(
            Icons.download,
            color: Color(0xff052b5a),
          ),
        );
      },
    );
  }
}
