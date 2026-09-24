import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/catalog/presentation/catalog_picker.dart';

class HomeAddFab extends StatefulWidget {
  const HomeAddFab({super.key});

  @override
  State<HomeAddFab> createState() => _HomeAddFabState();
}

class _HomeAddFabState extends State<HomeAddFab> {
  bool _pickerOpen = false;

  Future<void> _openPicker() async {
    if (_pickerOpen) return;
    setState(() => _pickerOpen = true);
    await showCatalogPicker(context);
    if (mounted) setState(() => _pickerOpen = false);
  }

  @override
  Widget build(BuildContext context) =>
      LapseFab(open: _pickerOpen, onPressed: () => unawaited(_openPicker()));
}
