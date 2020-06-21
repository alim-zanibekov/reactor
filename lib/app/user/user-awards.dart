import 'package:flutter/material.dart';

import '../../core/common/retry-netwok-image.dart';
import '../../core/content/types/module.dart';

class AppUserAwards extends StatefulWidget {
  final List<Award> awards;

  const AppUserAwards({Key key, this.awards}) : super(key: key);

  @override
  _AppUserAwards createState() => _AppUserAwards();
}

class _AppUserAwards extends State<AppUserAwards> {
  bool _opened = true;
  List<Award> awards;

  @override
  void initState() {
    if (widget.awards.length > 50) {
      awards = widget.awards.sublist(0, 30);
      _opened = false;
    } else {
      awards = widget.awards;
    }
    super.initState();
  }

  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.start,
      spacing: 5,
      runSpacing: 5,
      children: [
        ...awards
            .map((e) => GestureDetector(
                  onTap: () {
                    Scaffold.of(context).removeCurrentSnackBar();
                    Scaffold.of(context).showSnackBar(SnackBar(
                        duration: Duration(seconds: 10),
                        content: Text(e.title)));
                  },
                  child: SizedBox(
                      child: Image(
                        image: AppNetworkImageWithRetry(e.icon),
                      ),
                      width: 25,
                      height: 25),
                ))
            .toList(),
        if (!_opened)
          GestureDetector(
            onTap: () => setState(() {
              _opened = true;
              awards = widget.awards;
            }),
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 4.5, 10, 4.5),
              child: const Text('...', style: TextStyle(fontSize: 13)),
              decoration: BoxDecoration(
                  color: isDark ? Colors.black26 : Colors.grey[200],
                  borderRadius: BorderRadius.circular(50)),
            ),
          )
      ],
    );
  }
}
