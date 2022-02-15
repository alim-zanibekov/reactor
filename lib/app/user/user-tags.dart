import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/parsers/types/module.dart';
import '../common/open.dart';

class AppUserTags extends StatefulWidget {
  final List<Tag> tags;
  final TextStyle? textStyle;
  final bool canHide;

  AppUserTags(
      {Key? key, required this.tags, this.textStyle, this.canHide = true})
      : super(key: key);

  @override
  _AppUserTagsState createState() => _AppUserTagsState();
}

class _AppUserTagsState extends State<AppUserTags> {
  bool _opened = true;
  late List<Tag> tags;

  @override
  void initState() {
    if (widget.tags.length > 30 && widget.canHide) {
      tags = widget.tags.sublist(0, 30);
      _opened = false;
    } else {
      tags = widget.tags;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.left,
      text: TextSpan(
        style: DefaultTextStyle.of(context).style.copyWith(height: 1.5),
        children: <InlineSpan>[
          ...tags.map((e) => TextSpan(children: <InlineSpan>[
                TextSpan(
                  text: e.value,
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => openTag(context, e),
                  style: TextStyle(
                    fontSize: 14 *
                        (e is UserTag && e.weight != null
                            ? e.weight! * 0.8
                            : 1.0),
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(text: '  '),
              ])),
          if (!_opened)
            WidgetSpan(
              child: GestureDetector(
                onTap: () => setState(() {
                  tags = widget.tags;
                  _opened = true;
                }),
                child: Container(
                  width: 40,
                  height: 20,
                  color: Colors.transparent,
                  alignment: Alignment.bottomLeft,
                  child: const Text('...'),
                ),
              ),
            )
        ],
      ),
    );
  }
}
