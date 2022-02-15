import 'package:html/dom.dart';
import 'package:html/parser.dart' as parser;

import 'types/post.dart';
import 'utils.dart';

class QuizParser {
  Quiz? parseQuizFromPost(Element parsedPage) {
    final block = parsedPage.querySelector('.post_poll_holder');
    if (block != null) {
      return parseQuiz(block);
    }
    return null;
  }

  Quiz parseQuiz(Element block) {
    final title = block.querySelector('.poll_quest')?.text.trim();
    final table = block.querySelector('.polls_table');
    final answers = table != null
        ? _parseQuizTable(table)
        : _parseQuizList(block.querySelectorAll('.poll_answer'));
    return Quiz(
      title: title ?? '-//-',
      answers: answers,
    );
  }

  Quiz parseQuizResponse(String page) {
    final parsedPage = parser.parse(page);
    final body = parsedPage.body;
    if (body == null) throw Exception("Invalid quiz response");
    return parseQuiz(body);
  }

  List<QuizAnswer> _parseQuizList(List<Element> elements) {
    List<QuizAnswer> answers = [];
    for (final element in elements) {
      int? id;
      final link = element.children.length > 0 ? element.children.first : null;

      final idMatch = _voteIdRegex.firstMatch((link?.attributes ?? {})['href']);
      if (idMatch != null && idMatch.groupCount > 0) {
        id = Utils.getNumberInt(idMatch.group(1));
      }
      answers.add(QuizAnswer(
        text: element.text.trim(),
        id: id,
        percent: 0,
      ));
    }
    return answers;
  }

  List<QuizAnswer> _parseQuizTable(Element table) {
    int i = 0;
    String? text;
    List<QuizAnswer> answers = [];
    for (final line in table.querySelectorAll('tr')) {
      if (i % 2 == 0) {
        text = line.text.trim();
      } else {
        final td = line.children.length > 0 ? line.children.last : null;
        final count = Utils.getNumberInt(td?.querySelector('b')?.text);
        final percent = Utils.getNumberDouble(
            td != null && td.nodes.length > 0 ? td.nodes.last.text : null);

        answers.add(QuizAnswer(
          text: text ?? '',
          percent: percent ?? 0,
          count: count,
        ));
      }
      i++;
    }
    return answers;
  }

  static final _voteIdRegex = RegExp(r'vote\/([0-9]+)', caseSensitive: false);
}
