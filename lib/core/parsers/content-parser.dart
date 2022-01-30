import 'package:html/dom.dart';
import 'package:html/parser.dart' as parser;

import './types/module.dart';
import '../common/pair.dart';
import 'types/utils.dart';

class ContentParser {
  List<ContentUnit> parseContent(String? c) {
    final parsedPage = parser.parse(c);
    return parse(parsedPage.body!);
  }

  ContentUnit? _parseImage(Element element) {
    final iFrame = element.querySelector('iframe');
    final youTubeVideo =
        element.querySelector('.youtube-player')?.attributes['src'];
    final embedHasSrc =
        iFrame != null && (iFrame.attributes['src']?.isNotEmpty ?? false);

    final coub = embedHasSrc &&
        iFrame!.attributes['src']!.contains('://coub.com/embed/');

    final vimeo =
        embedHasSrc && iFrame!.attributes['src']!.contains('vimeo.com/video/');

    final soundCloud = embedHasSrc &&
        iFrame!.attributes['src']!.contains('soundcloud.com/player');

    final gif = element.querySelectorAll('source');
    final image = element.querySelector('img');
    final prettyPhoto = element.querySelector('.prettyPhotoLink');

    if (gif.isNotEmpty) {
      final href = element.querySelector('.video_gif_source');
      final width = double.parse(gif.first.parentNode!.attributes['width']!);
      final height = double.parse(gif.first.parentNode!.attributes['height']!);
      final src = gif.map((e) => e.attributes['src']).toList();
      final srcWebm = src.indexWhere((e) => e!.toLowerCase().endsWith('webm'));
      final srcMp4 = src.indexWhere((e) => e!.toLowerCase().endsWith('mp4'));

      if (srcMp4 != -1 || srcWebm != -1) {
        return ContentUnitGif(
            srcMp4 != -1 ? src[srcMp4]! : src[srcWebm]!, width, height,
            gifUrl: href?.attributes['href']);
      }
    } else if (youTubeVideo != null) {
      final link = _youtubeRegex.firstMatch(youTubeVideo)?.group(1);
      final id = link != null ? convertYouTubeUrlToId(link) : null;
      if (id != null) return ContentUnitYouTubeVideo(id);
    } else if (coub) {
      final link = iFrame!.attributes['src'];
      final id = link != null ? convertCoubUrlToId(link) : null;
      if (id != null) return ContentUnitCoubVideo(id);
    } else if (vimeo) {
      final link = iFrame!.attributes['src'];
      final id = link != null ? convertVimeoUrlToId(link) : null;
      if (id != null) return ContentUnitVimeoVideo(id);
    } else if (soundCloud) {
      final link = iFrame!.attributes['src'];
      final id = link != null ? getSoundCloudUrl(link) : null;
      if (id != null) return ContentUnitSoundCloudAudio(id);
    } else if (image != null) {
      var width = double.tryParse(image.attributes['width']!);
      var height = double.tryParse(image.attributes['height']!);
      if (height == null || width == null) {
        width = height = null;
      }
      final src = image.attributes['src'];
      if (src != null) {
        return ContentUnitImage(src, width, height,
            prettyImageLink: (prettyPhoto?.attributes ?? {})['href']);
      }
    }
    return null;
  }

  List<ContentTextStyle> _extractStyles(List<ContentTextStyle?> stack) {
    return Set.of([
      for (var style in stack)
        if (style != null) style
    ]).toList();
  }

  ContentTextSize? _extractTextSize(List<ContentTextSize?> stack) {
    try {
      return stack.lastWhere((element) => element != null);
    } on StateError {
      return ContentTextSize.s12;
    }
  }

  String? _extractLink(List<String?> links) {
    try {
      return links.lastWhere((element) => element != null);
    } on StateError {
      return null;
    }
  }

  List<ContentUnit> parse(Element content) {
    List<ContentUnit> result = [];
    List<Pair<int, Object>> nodes = content.nodes.reversed
        .map<Pair<int, Object>>((e) => Pair(0, e))
        .toList();
    List<Pair<int, ContentTextSize?>> sizes = [Pair(0, ContentTextSize.s12)];
    List<Pair<int, ContentTextStyle?>> styles = [
      Pair(0, ContentTextStyle.NORMAL)
    ];
    List<Pair<int, String?>> links = [Pair(0, null)];

    while (nodes.isNotEmpty) {
      final pair = nodes.removeLast();
      final node = pair.right;
      if (pair.left < sizes.length - 1) {
        while (sizes.isNotEmpty && sizes.length - 1 != pair.left) {
          sizes.removeLast();
          styles.removeLast();
          links.removeLast();
        }
      }
      final nextDepth = pair.left + 1;
      if (node is ContentUnitBreak) {
        if (result.isNotEmpty) {
          result.add(node);
        }
      } else if (node is Node && node.nodeType == Node.ELEMENT_NODE) {
        Element element = node as Element;
        if (element.classes.contains('comments_bottom') ||
            element.classes.contains('mainheader') ||
            element.classes.contains('post_poll_holder') ||
            element.classes.contains('blog_results')) {
          continue;
        }

        if (element.attributes['class'] == 'image') {
          final res = _parseImage(element);
          if (res != null) {
            result.add(res);
          }
        } else if (element.localName == 'br') {
          nodes.add(Pair(nextDepth, ContentUnitBreak(ContentBreak.LINEBREAK)));
        } else if (node.nodes.isNotEmpty) {
          ContentTextSize? size;
          ContentTextStyle? style;

          if (element.localName == 'h1')
            size = ContentTextSize.s18;
          else if (element.localName == 'h2')
            size = ContentTextSize.s16;
          else if (element.localName == 'h3')
            size = ContentTextSize.s14;
          else if (element.localName == 'h4')
            size = ContentTextSize.s14;
          else if (element.localName == 'h5')
            size = ContentTextSize.s12;
          else if (element.localName == 'h6') size = ContentTextSize.s12;

          if (size != null) {
            style = ContentTextStyle.BOLD;
          } else {
            if (element.localName == 'b' || element.localName == 'strong')
              style = ContentTextStyle.BOLD;
            else if (element.localName == 'i')
              style = ContentTextStyle.ITALIC;
            else if (element.localName == 's' || element.localName == 'strike')
              style = ContentTextStyle.LINE;
            else if (element.localName == 'a')
              style = ContentTextStyle.UNDERLINE;
          }

          final block = BLOCK_NODES.contains(element.localName);

          sizes.add(Pair(nextDepth, size));
          styles.add(Pair(nextDepth, style));
          links.add(Pair(nextDepth,
              (element.localName == 'a') ? element.attributes['href'] : null));

          if (block) {
            nodes.add(
              Pair(nextDepth, ContentUnitBreak(ContentBreak.BLOCK_BREAK)),
            );
          }
          nodes.addAll(node.nodes.reversed.map((e) => Pair(nextDepth, e)));
          if (block) {
            nodes.add(
              Pair(nextDepth, ContentUnitBreak(ContentBreak.BLOCK_BREAK)),
            );
          }
        }
      } else if (node is Node &&
          node.nodeType == Node.TEXT_NODE &&
          node.text != null &&
          node.text!.trim().isNotEmpty) {
        String? link = _extractLink(links.map((e) => e.right).toList());
        String text = node.text!;
        if (result.isEmpty || result.last is ContentUnitBreak) {
          text = text.trimLeft();
        }
        final size = _extractTextSize(sizes.map((e) => e.right).toList()) ??
            ContentTextSize.s12;
        final style = _extractStyles(styles.map((e) => e.right).toList());

        if (link != null) {
          if (_redirectRegex.hasMatch(link)) {
            link = Uri.decodeQueryComponent(
                _redirectRegex.firstMatch(link)!.group(1)!);
          }
          result.add(ContentUnitLink(
            text,
            link: link,
            size: size,
            style: style,
          ));
        } else {
          result.add(ContentUnitText(
            text,
            size: size,
            style: style,
          ));
        }
      }
    }
    late ContentUnit prev;
    final preResult = result.where((e) {
      bool res = e is! ContentUnitBreak ||
          (e is ContentUnitBreak &&
                  (e.value == ContentBreak.BLOCK_BREAK &&
                      prev.value != e.value &&
                      prev.value != ContentBreak.LINEBREAK) ||
              e.value == ContentBreak.LINEBREAK);
      prev = e;
      return res;
    }).toList();

    while (preResult.isNotEmpty && preResult.last is ContentBreak) {
      preResult.removeLast();
    }
    List<ContentUnit<String?>> answer = [];

    for (int i = 0; i < preResult.length; ++i) {
      if (preResult[i] is ContentUnitBreak) {
        if (answer.isNotEmpty && answer.last is ContentUnitText) {
          answer.last.value = (answer.last.value ?? '') + '\n';
        }
      } else {
        answer.add(preResult[i] as ContentUnit<String?>);
      }
    }

    if (answer.isNotEmpty && answer.last is ContentUnitText) {
      answer.last.value = answer.last.value!.trim();
    }

    return answer;
  }

  static final _youtubeRegex = RegExp(
    r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/ ]{11})',
    caseSensitive: false,
  );

  static final _redirectRegex = RegExp(
    r'(?:https?)?:?\/\/(?:joy|[^\/\.]+\.)?reactor.cc\/redirect\?url=([^\&]+)',
    caseSensitive: false,
  );
  static const List<String> BLOCK_NODES = [
    'p',
    'div',
    'h1',
    'h2',
    'h3',
    'h4',
    'h5',
    'h6',
  ];
}
