class Pair<T, E> {
  Pair(this.left, this.right);

  final T left;
  final E right;

  @override
  String toString() => 'Pair[$left, $right]';
}
