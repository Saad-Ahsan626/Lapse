import 'package:flutter/widgets.dart';

class SwipeActionsGroup extends StatefulWidget {
  const SwipeActionsGroup({required this.child, super.key});

  final Widget child;

  static SwipeActionsGroupState? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_SwipeActionsGroupScope>()?.state;

  @override
  State<SwipeActionsGroup> createState() => SwipeActionsGroupState();
}

class SwipeActionsGroupState extends State<SwipeActionsGroup> {
  Object? _openOwner;
  VoidCallback? _closeOpen;

  void didOpen(Object owner, VoidCallback close) {
    if (identical(_openOwner, owner)) return;
    final previous = _closeOpen;
    _openOwner = owner;
    _closeOpen = close;
    previous?.call();
  }

  void didClose(Object owner) {
    if (!identical(_openOwner, owner)) return;
    _openOwner = null;
    _closeOpen = null;
  }

  void closeAll() {
    final close = _closeOpen;
    _openOwner = null;
    _closeOpen = null;
    close?.call();
  }

  @override
  Widget build(BuildContext context) =>
      _SwipeActionsGroupScope(state: this, child: widget.child);
}

class _SwipeActionsGroupScope extends InheritedWidget {
  const _SwipeActionsGroupScope({required this.state, required super.child});

  final SwipeActionsGroupState state;

  @override
  bool updateShouldNotify(_SwipeActionsGroupScope oldWidget) =>
      !identical(state, oldWidget.state);
}
