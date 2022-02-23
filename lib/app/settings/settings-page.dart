import 'package:flutter/material.dart';

import '../../core/api/api.dart';
import '../../core/common/reload-service.dart';
import '../../core/common/snack-bar.dart';
import '../../core/preferences/preferences.dart';
import '../../main.dart';

class AppSettingsPage extends StatefulWidget {
  const AppSettingsPage({Key? key}) : super(key: key);

  @override
  _AppSettingsPageState createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends State<AppSettingsPage> {
  Preferences _preferences = Preferences();
  late AppTheme _theme;
  late AppPostsType _postsType;
  String? _host;
  late bool _sfw;
  late bool _sendErrorStatistics;
  late bool _gifAutoPlay;

  @override
  void initState() {
    _theme = _preferences.theme;
    _postsType = _preferences.postsType;
    _sfw = _preferences.sfw;
    _sendErrorStatistics = _preferences.sendErrorStatistics;
    _gifAutoPlay = _preferences.gifAutoPlay;
    _host = _preferences.host;
    super.initState();
  }

  void _handleTheme(AppTheme value) async {
    setState(() => _theme = value);
    await _preferences.setTheme(value);
    App.appTheme.add(value);
  }

  void _handlePostType(AppPostsType value) async {
    setState(() => _postsType = value);
    await _preferences.setDefaultPostType(value);
  }

  @override
  Widget build(BuildContext context) {
    final padding =
        const EdgeInsets.symmetric(horizontal: 5.0).copyWith(left: 20);
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        physics: const ClampingScrollPhysics(),
        children: <Widget>[
          const ListTile(title: Text('Хост')),
          Padding(
              padding: padding,
              child: Row(
                children: [
                  DropdownButton<String>(
                    hint: Text('Хост'),
                    value: _host,
                    onChanged: (String? value) async {
                      if (value == null) return;
                      setState(() => _host = value);
                      await _preferences.setHost(value);
                      ReloadService.reload();
                      Api.setHost(value);
                    },
                    items: _preferences.hostList
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  Expanded(child: SizedBox()),
                  TextButton(
                    child: Text('Добавить'),
                    onPressed: () async {
                      final host = await _displayAddHostDialog(context);
                      if (host != null) {
                        _preferences.hostList.add(host);
                        _preferences.setHostList(_preferences.hostList);
                        setState(() {});
                      }
                    },
                  ),
                ],
              )),
          const ListTile(title: Text('Открывать по умолчанию')),
          LabeledRadio<AppPostsType>(
            label: 'Новое',
            padding: padding,
            value: AppPostsType.NEW,
            groupValue: _postsType,
            onChanged: _handlePostType,
          ),
          LabeledRadio<AppPostsType>(
            label: 'Хорошее',
            padding: padding,
            value: AppPostsType.GOOD,
            groupValue: _postsType,
            onChanged: _handlePostType,
          ),
          LabeledRadio<AppPostsType>(
            label: 'Лучшее',
            padding: padding,
            value: AppPostsType.BEST,
            groupValue: _postsType,
            onChanged: _handlePostType,
          ),
          LabeledRadio<AppPostsType>(
            label: 'Бездна',
            padding: padding,
            value: AppPostsType.ALL,
            groupValue: _postsType,
            onChanged: _handlePostType,
          ),
          const ListTile(title: Text('Тема')),
          LabeledRadio<AppTheme>(
            label: 'Автоматически',
            padding: padding,
            value: AppTheme.AUTO,
            groupValue: _theme,
            onChanged: _handleTheme,
          ),
          LabeledRadio<AppTheme>(
            label: 'Темная',
            padding: padding,
            value: AppTheme.DARK,
            groupValue: _theme,
            onChanged: _handleTheme,
          ),
          LabeledRadio<AppTheme>(
            label: 'Светлая',
            padding: padding,
            value: AppTheme.LIGHT,
            groupValue: _theme,
            onChanged: _handleTheme,
          ),
          SwitchListTile(
            title: const Text('SFW'),
            value: _sfw,
            activeColor: Theme.of(context).colorScheme.secondary,
            onChanged: (bool sfw) async {
              setState(() => _sfw = sfw);
              await _preferences.setSFW(sfw);
            },
          ),
          SwitchListTile(
            title: const Text('Воспроизводить гифки автоматически'),
            value: _gifAutoPlay,
            activeColor: Theme.of(context).colorScheme.secondary,
            onChanged: (bool gifAutoPlay) async {
              setState(() => _gifAutoPlay = gifAutoPlay);
              await _preferences.setGifAutoPlay(gifAutoPlay);
            },
          ),
          SwitchListTile(
            title: const Text('Отправлять отчеты об ошибках'),
            value: _sendErrorStatistics,
            activeColor: Theme.of(context).colorScheme.secondary,
            onChanged: (bool sendErrorStatistics) async {
              SnackBarHelper.show(context,
                  'Пока что нельзя это выключить, подождите более стабильной версии');
              _sendErrorStatistics = true;
              // setState(() => _sendErrorStatistics = sendErrorStatistics);
              // await _preferences.setSendErrorStatistics(sendErrorStatistics);
            },
          )
        ],
      ),
    );
  }

  Future<String?> _displayAddHostDialog(BuildContext context) async {
    String? result;
    await showDialog(
      context: context,
      builder: (context) {
        TextEditingController _textFieldController = TextEditingController();
        String? errorText;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return SingleChildScrollView(
              child: OrientationBuilder(builder: (context, _) {
                return Container(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height,
                  ),
                  alignment: Alignment.center,
                  child: AlertDialog(
                    title: Text('Введите новый хост'),
                    content: TextField(
                      autocorrect: false,
                      controller: _textFieldController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 15.0),
                        hintText: 'Хост',
                        errorText: errorText,
                      ),
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: Text('Отмена'),
                        onPressed: () => Navigator.pop(context),
                      ),
                      TextButton(
                        child: Text('Сохранить'),
                        onPressed: () async {
                          if (_preferences.hostList
                              .contains(_textFieldController.text)) {
                            errorText = 'Такой хост уже существует';
                          } else if (_textFieldController.text.isEmpty) {
                            errorText = 'Введите хост';
                          } else {
                            final isValid = await Api()
                                .checkHost(_textFieldController.text);
                            if (isValid) {
                              result = _textFieldController.text;
                              Navigator.pop(context);
                            } else {
                              errorText = 'Это не хост реактора';
                            }
                          }
                          setStateDialog(() {});
                        },
                      ),
                    ],
                  ),
                );
              }),
            );
          },
        );
      },
    );
    return result;
  }
}

class LabeledRadio<T> extends StatelessWidget {
  const LabeledRadio({
    required this.value,
    required this.groupValue,
    this.label,
    this.padding,
    this.onChanged,
  });

  final String? label;
  final EdgeInsets? padding;
  final T groupValue;
  final T value;
  final void Function(T)? onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (value != groupValue) onChanged?.call(value);
      },
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: Row(children: <Widget>[
          SizedBox(
            height: 35,
            child: Radio<T>(
              activeColor: Theme.of(context).colorScheme.secondary,
              groupValue: groupValue,
              value: value,
              onChanged: (T? newValue) {
                if (newValue != null) onChanged?.call(newValue);
              },
            ),
          ),
          Text(label ?? '', style: const TextStyle(fontSize: 12)),
        ]),
      ),
    );
  }
}
