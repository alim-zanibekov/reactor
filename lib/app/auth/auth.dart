import 'package:flutter/material.dart';

import '../../core/auth/auth.dart';
import '../../core/auth/types.dart';
import '../home.dart';

class AppAuthPage extends StatefulWidget {
  const AppAuthPage({Key? key}) : super(key: key);

  @override
  _AppAuthPageState createState() => _AppAuthPageState();
}

class _AppAuthPageState extends State<AppAuthPage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _usernameEditingController = TextEditingController();
  TextEditingController _passwordEditingController = TextEditingController();

  bool _loading = false;
  bool _error = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style;
    return Scaffold(
      appBar: AppBar(title: const Text('Аворизация')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(36.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  height: 45.0,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: _error ? 1 : 0,
                      child: Text(
                        _errorMessage ?? 'Неверное имя пользователя или пароль',
                        style: style.copyWith(
                          color: Theme.of(context).errorColor,
                        ),
                      ),
                    ),
                  ),
                ),
                TextFormField(
                  controller: _usernameEditingController,
                  obscureText: false,
                  validator: (value) => (value?.isEmpty ?? true)
                      ? 'Введите имя пользователя'
                      : null,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(10.0, 15.0, 10.0, 15.0),
                    hintText: 'Имя пользователя',
                  ),
                ),
                const SizedBox(height: 25.0),
                TextFormField(
                  controller: _passwordEditingController,
                  obscureText: true,
                  validator: (value) =>
                      (value?.isEmpty ?? true) ? 'Введите пароль' : null,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(10.0, 15.0, 10.0, 15.0),
                    hintText: 'Пароль',
                  ),
                ),
                const SizedBox(height: 35.0),
                Container(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      if (_formKey.currentState?.validate() ?? false) {
                        FocusScope.of(context).requestFocus(FocusNode());
                        setState(() => _loading = true);
                        try {
                          await Auth().login(
                              _usernameEditingController.value.text,
                              _passwordEditingController.value.text);
                          _loading = false;
                          AppPages.appBottomBarPage.add(AppBottomBarPage.MAIN);
                        } catch (err) {
                          if (err is InvalidUsernameOrPasswordException) {
                            _errorMessage =
                                'Неверное имя пользователя или пароль';
                          } else if (err is RateLimitException) {
                            _errorMessage = 'Превышен лимит обращений';
                          } else if (err is InvalidStatusCodeException) {
                            _errorMessage =
                                'Что то пошло не так, повторите позже';
                          }
                          setState(() {
                            _error = true;
                            _loading = false;
                          });
                        }
                      }
                    },
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child: IndexedStack(
                        key: ValueKey<int>(_loading ? 1 : 0),
                        index: _loading ? 1 : 0,
                        children: <Widget>[
                          Center(child: Text('Войти', style: style)),
                          const Center(
                            child: SizedBox(
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                              ),
                              height: 16,
                              width: 16,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
