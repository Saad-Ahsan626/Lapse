import 'package:flutter/widgets.dart';

class KeyboardInset extends StatelessWidget {
  const KeyboardInset({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: child,
  );
}
