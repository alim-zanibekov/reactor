import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/api/api.dart';
import '../../core/common/snack-bar.dart';
import '../../core/parsers/types/module.dart';

class AppCommentAnswer extends StatefulWidget {
  final PostComment comment;
  final Function? onSend;

  const AppCommentAnswer({Key? key, required this.comment, this.onSend})
      : super(key: key);

  @override
  _AppCommentAnswerState createState() => _AppCommentAnswerState();
}

class _AppCommentAnswerState extends State<AppCommentAnswer> {
  static final _api = Api();
  bool _loading = false;
  File? _file;
  double _progressSend = 0.0000001;
  TextEditingController _controller = TextEditingController();

  _sendAnswer() async {
    setState(() {
      _loading = true;
    });
    try {
      await _api.createComment(
        widget.comment.postId,
        widget.comment.id,
        _controller.text,
        _file,
        onSendProgress: (sent, total) => setState(() {
          _progressSend = sent.toDouble() / total.toDouble();
        }),
      );
      widget.onSend?.call();
      _controller.text = '';
    } on Exception {
      SnackBarHelper.show(context, 'Произошла ошибка при загрузке');
    }
    setState(() {
      _progressSend = 0.000001;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ColoredBox(
      color: isDark ? Colors.black26 : Colors.grey[200]!,
      child: Column(children: <Widget>[
        SizedBox(
          height: 2,
          child: LinearProgressIndicator(
            value: _progressSend,
            backgroundColor: Colors.transparent,
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: 10, left: 10, right: 10),
          child: TextField(
            controller: _controller,
            focusNode: null,
            autofocus: false,
            maxLines: null,
            style: const TextStyle(fontSize: 12),
            decoration: const InputDecoration(
              hintText: 'Напишите комментарий...',
              contentPadding: EdgeInsets.all(15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(5.0)),
                borderSide: BorderSide(color: Colors.blue, width: 1),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 10),
          child: Row(children: <Widget>[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 10, right: 5),
                child: Text(
                  _file?.path.split('/').last ?? '',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (_file != null)
              Padding(
                padding: const EdgeInsets.only(right: 5),
                child: InkWell(
                  onTap: () => setState(() => _file = null),
                  child: Icon(Icons.delete_outline, size: 18),
                ),
              ),
            SizedBox(
              height: 25,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.only(left: 5, right: 5),
                ),
                onPressed: () async {
                  if (_loading) return;

                  final result = await FilePicker.platform
                      .pickFiles(type: FileType.image, allowMultiple: false);
                  if (result != null && result.files.single.path != null) {
                    _file = File(result.files.single.path!);
                  }
                  setState(() {});
                },
                child: const Text(
                  'Загрузить картинку',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Container(
              height: 25,
              padding: const EdgeInsets.only(right: 10),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(3.0),
                ),
                onPressed: () {
                  if (_loading) return;
                  _sendAnswer();
                },
                child: const Text(
                  'Отправить',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            )
          ]),
        )
      ]),
    );
  }
}
