import 'package:lapse/features/subscriptions/presentation/links/link_opener.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlLauncherLinkOpener implements LinkOpener {
  const UrlLauncherLinkOpener();

  @override
  Future<bool> open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object {
      return false;
    }
  }
}
