import 'package:flutter/material.dart';

import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';

enum MissingCancelLinkChoice { addLink, search }

Future<MissingCancelLinkChoice?> showMissingCancelLinkSheet(
  BuildContext context,
) => showLapseSheet<MissingCancelLinkChoice>(
  context: context,
  title: 'No cancel link yet',
  builder: (_) => const MissingCancelLinkSheet(),
);

class MissingCancelLinkSheet extends StatelessWidget {
  const MissingCancelLinkSheet({super.key});

  @override
  Widget build(BuildContext context) {
    void choose(MissingCancelLinkChoice choice) =>
        Navigator.of(context).pop(choice);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        Space.screen,
        0,
        Space.screen,
        Space.xl + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Add the service's cancel page so it's one tap away next time.",
            style: context.lapse.text.bodyMuted,
          ),
          const SizedBox(height: Space.xl),
          LapseButton(
            label: 'Add a cancel link',
            icon: Icons.link_rounded,
            expand: true,
            onPressed: () => choose(MissingCancelLinkChoice.addLink),
          ),
          const SizedBox(height: 10),
          LapseButton(
            label: 'Search how to cancel',
            icon: Icons.search_rounded,
            variant: LapseButtonVariant.secondary,
            expand: true,
            onPressed: () => choose(MissingCancelLinkChoice.search),
          ),
        ],
      ),
    );
  }
}
