import '../parsers/types/module.dart';

abstract class Loader<T> {
  bool get complete;

  ContentPage<T> get firstPage;

  List<T> get elements;

  void destroy();

  void reset();

  Future<List<T>?> load();

  Future<List<T>?> loadNext();
}
