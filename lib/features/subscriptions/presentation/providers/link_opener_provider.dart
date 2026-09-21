import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapse/features/subscriptions/presentation/links/link_opener.dart';
import 'package:lapse/features/subscriptions/presentation/links/url_launcher_link_opener.dart';

final linkOpenerProvider = Provider<LinkOpener>(
  (ref) => const UrlLauncherLinkOpener(),
);
