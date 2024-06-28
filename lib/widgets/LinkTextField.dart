import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../services/AllServices.dart';
import '../utils/styles.dart';

class LinkTextfield extends StatelessWidget {
  const LinkTextfield({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<Services>(
      builder: (BuildContext context, Services value, Widget? child) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TextField(
            style: value.getTheme(context) == Brightness.light
                ? labelstyleLight
                : labelstyleDark,
            //readOnly: true,
            controller: value.urlController,
            decoration: InputDecoration(
              enabledBorder: OutlineInputBorder(
                borderSide:
                    const BorderSide(color: Color(0xff1e365c), width: 2.0),
                borderRadius: BorderRadius.circular(12.0),
              ),
              disabledBorder: OutlineInputBorder(
                borderSide:
                    const BorderSide(color: Color(0xff1e365c), width: 2.0),
                borderRadius: BorderRadius.circular(12.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide:
                    const BorderSide(color: Color(0xff1e365c), width: 2.0),
                borderRadius: BorderRadius.circular(12.0),
              ),
              hintText: 'Enter a YouTube URL',
              hintStyle: const TextStyle(
                color: Color(0xff1e365c),
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              labelStyle: value.getTheme(context) == Brightness.light
                  ? labelstyleLight
                  : labelstyleDark,
              suffixIcon: IconButton(
                icon: const FaIcon(
                  FontAwesomeIcons.paste,
                  color: Color(0xff1e365c),
                  size: 24,
                ),
                onPressed: () {
                  value.pasteIn();
                },
              ),
              filled: true,
              fillColor: value.getTheme(context) == Brightness.light
                  ? Colors.white
                  : Colors.grey[800],
            ),
          ),
        );
      },
    );
  }
}
