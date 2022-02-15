import 'package:flutter/material.dart';

import '../../core/parsers/types/module.dart';

class AppPostTags extends StatefulWidget {
  final List<Tag> tags;
  final void Function(Tag) openTag;

  AppPostTags({Key? key, required this.tags, required this.openTag})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _AppPostTagsState();
  }
}

class _AppPostTagsState extends State<AppPostTags> {
  bool _opened = true;
  late List<Tag> _tags;

  @override
  void initState() {
    super.initState();
    if (widget.tags.length - 5 > 5) {
      _opened = false;
      _tags = widget.tags.sublist(0, 5);
    } else {
      _tags = widget.tags;
    }
  }

  Widget _getChip(String text) {
    return Ink(
      padding: const EdgeInsets.fromLTRB(10, 4.5, 10, 4.5),
      child: Text(text, style: const TextStyle(fontSize: 13)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        color: Theme.of(context).splashColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 5,
      runSpacing: 7,
      alignment: WrapAlignment.start,
      children: <Widget>[
        ..._tags.map(
          (e) => Material(
            type: MaterialType.transparency,
            child: InkWell(
              splashColor: Colors.black12,
              borderRadius: BorderRadius.circular(50),
              onTap: () {
                widget.openTag(e);
              },
              child: _getChip(e.value),
            ),
          ),
        ),
        if (!_opened)
          Material(
            type: MaterialType.transparency,
            child: InkWell(
              splashColor: Colors.black12,
              borderRadius: BorderRadius.circular(50),
              onTap: () => setState(() {
                _opened = true;
                _tags = widget.tags;
              }),
              child: _getChip('...'),
            ),
          ),
      ],
    );
  }
}
