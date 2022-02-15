import 'package:flutter/material.dart';

import '../../core/api/api.dart';
import '../../core/widgets/chips-input.dart';
import '../common/open.dart';

class AppSearch extends StatefulWidget {
  @override
  _AppSearchState createState() => _AppSearchState();
}

class _AppSearchState extends State<AppSearch> {
  final _queryController = TextEditingController();
  final _authorController = TextEditingController();
  final _api = Api();
  List<String?>? _tags;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Поиск'),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Container(
          height: double.infinity,
          child: SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.all(15.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          autocorrect: false,
                          controller: _queryController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 15.0,
                              vertical: 15.0,
                            ),
                            hintText: 'Запрос',
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          autocorrect: false,
                          controller: _authorController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 15.0,
                              vertical: 15.0,
                            ),
                            hintText: 'Автор',
                          ),
                        ),
                      )
                    ],
                  ),
                  SizedBox(height: 20),
                  ChipsInput<String>(
                    initialValue: [],
                    decoration: InputDecoration(
                      labelText: 'Теги',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
                    ),
                    maxChips: 300,
                    findSuggestions: (String query) async {
                      final tags = await _api.autocompleteTags(query);

                      return tags.map((e) => e.value).toList();
                    },
                    onChanged: (data) {
                      _tags = data;
                    },
                    chipBuilder: (context, state, tag) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Ink(
                          key: ObjectKey(tag),
                          padding: const EdgeInsets.fromLTRB(10, 4.5, 10, 4.5),
                          child:
                              Text(tag, style: const TextStyle(fontSize: 13)),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            color: Theme.of(context).splashColor,
                          ),
                          // materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      );
                    },
                    suggestionBuilder: (context, state, tag) {
                      return ListTile(
                        key: ObjectKey(tag),
                        title: Text(tag),
                        onTap: () => state.selectSuggestion(tag),
                      );
                    },
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(child: SizedBox()),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.only(left: 8, right: 8),
                        ),
                        child: const Text('Поиск'),
                        onPressed: () {
                          openSearchList(
                            context,
                            _queryController.text,
                            _authorController.text,
                            _tags,
                          );
                        },
                      )
                    ],
                  ),
                  // Expanded(child: SizedBox())
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
