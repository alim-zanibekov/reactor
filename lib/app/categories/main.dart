import 'package:flutter/material.dart';

import '../../core/common/retry-network-image.dart';
import '../../core/parsers/types/module.dart';
import '../common/open.dart';

class AppCategoriesMain extends StatelessWidget {
  const AppCategoriesMain({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      _children(
        context,
        'Anime',
        'http://joyreactor.cc/images/category/300/anime.jpg',
        Tag('Anime', prefix: 'anime'),
      ),
      _children(
        context,
        'Эротика',
        'http://joyreactor.cc/images/category/300/erot.jpg',
        Tag('эротика', link: 'эротика'),
      ),
      _children(
        context,
        'Игры',
        'http://joyreactor.cc/images/category/300/games.jpg',
        Tag('игры', link: 'игры'),
      ),
      _children(
        context,
        'Политота',
        'http://joyreactor.cc/images/category/politota.png',
        Tag('политота', link: 'политота'),
      ),
      _children(
        context,
        'anon',
        'http://joyreactor.cc/images/category/300/anon.jpg',
        Tag('anon', link: 'anon'),
      ),
      _children(
        context,
        'Фэндомы',
        'http://joyreactor.cc/images/category/300/fandome.jpg',
        Tag('фэндомы', link: 'фэндомы', isMain: true),
      ),
      _children(
        context,
        'Разное',
        'http://joyreactor.cc/images/category/300/raznoe.jpg',
        Tag('разное', link: 'разное', isMain: true),
      ),
    ]);
  }

  Widget _image(String source) {
    return SizedBox(
      height: 70,
      child: ClipRRect(
        child: AspectRatio(
          aspectRatio: 1,
          child: Image(
            fit: BoxFit.cover,
            alignment: Alignment.lerp(
              Alignment.center,
              Alignment.centerLeft,
              0.34,
            )!,
            image: AppNetworkImageWithRetry(source),
          ),
        ),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _content(BuildContext context, String title, Tag tag) {
    final style = DefaultTextStyle.of(context).style;

    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Container(
            height: 70,
            padding: const EdgeInsets.only(left: 5, top: 2),
            child: Text(title, style: style.copyWith(fontSize: 18)),
          ),
          if (!tag.isMain && tag.value != 'anon' && tag.value != 'политота')
            SizedBox(
              height: 30,
              child: OutlinedButton(
                onPressed: () => openTag(
                  context,
                  Tag(
                    tag.value,
                    link: tag.link ?? 'Anime',
                    isMain: true,
                    prefix: tag.prefix,
                  ),
                ),
                child: Text('Подразделы', style: style.copyWith(fontSize: 12)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _children(BuildContext context, String title, String source, Tag tag) {
    return Material(
      child: InkWell(
        onTap: () => openTag(context, tag),
        child: Padding(
          padding: const EdgeInsets.all(4).copyWith(right: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _image(source),
              _content(context, title, tag),
            ],
          ),
        ),
      ),
    );
  }
}
