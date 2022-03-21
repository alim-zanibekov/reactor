import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/api/api.dart';
import '../../../core/common/snack-bar.dart';
import '../../../core/parsers/types/module.dart';

class AppQuiz extends StatefulWidget {
  final Quiz quiz;
  final void Function(Quiz) quizUpdated;

  const AppQuiz({
    Key? key,
    required this.quiz,
    required this.quizUpdated,
  }) : super(key: key);

  @override
  _AppQuizState createState() => _AppQuizState();
}

class _AppQuizState extends State<AppQuiz> {
  static final _api = Api();
  bool _loading = false;

  _vote(int id) async {
    _loading = true;
    try {
      final quiz = await _api.voteQuiz(id);
      widget.quizUpdated(quiz);
    } catch (e) {
      SnackBarHelper.show(context, 'Не удалось проголосовать');
    } finally {
      _loading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width - 16.0;
    final texts = widget.quiz.answers.map((e) => '${e.count} (${e.percent}%)');
    final maxLenText = texts.fold(
        texts.first.length, (int acc, element) => max(acc, element.length));
    final answers = widget.quiz.answers.map((e) {
      if (e.id != null) {
        return InkWell(
          onTap: () {
            if (!_loading) {
              _vote(e.id!);
            }
          },
          child: Row(children: <Widget>[
            SizedBox(
              height: 35,
              child: Radio<bool>(
                activeColor: Theme.of(context).colorScheme.secondary,
                groupValue: false,
                value: true,
                onChanged: (_) {},
              ),
            ),
            Flexible(
              child: Padding(
                padding: EdgeInsets.fromLTRB(0, 5, 10, 5),
                child: Text(e.text, style: const TextStyle(fontSize: 13)),
              ),
            ),
          ]),
        );
      }
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(vertical: 5),
              child: Text(e.text),
            ),
            Row(
              children: <Widget>[
                SizedBox(
                  width: width - maxLenText * 8,
                  child: LinearProgressIndicator(
                    value: e.percent / 100.0,
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.light
                            ? Colors.black12
                            : null,
                  ),
                ),
                Expanded(child: SizedBox()),
                Text(e.count.toString(),
                    style: TextStyle(fontWeight: FontWeight.w500)),
                Text(' (${e.percent}%)', style: TextStyle(fontSize: 12)),
              ],
            )
          ],
        ),
      );
    });

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(widget.quiz.title,
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
          ),
          SizedBox(height: 10),
          ...answers,
        ],
      ),
    );
  }
}
