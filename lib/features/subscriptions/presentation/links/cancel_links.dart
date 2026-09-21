import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/presentation/links/link_opener.dart';

Uri? cancelUriFor(Subscription s) {
  final raw = s.cancelUrl?.trim() ?? '';
  if (raw.isEmpty) return null;
  final parsed = Uri.tryParse(raw);
  if (parsed == null) return null;
  final uri = parsed.hasScheme ? parsed : Uri.tryParse('https://$raw');
  if (uri == null || uri.host.isEmpty) return null;
  if (!LinkOpener.webSchemes.contains(uri.scheme.toLowerCase())) return null;
  return uri;
}

Uri howToCancelSearchUri(String name) => Uri.https(
  'www.google.com',
  '/search',
  {'q': 'how to cancel ${name.trim()} subscription'},
);
