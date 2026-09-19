import 'package:lapse/features/catalog/domain/entities/catalog_service.dart';
import 'package:lapse/features/subscriptions/domain/entities/billing_period.dart';

CatalogService catalogServiceFixture(
  String key,
  String name, {
  int? popularRank,
  List<String> aliases = const [],
}) => CatalogService(
  key: key,
  name: name,
  category: 'Other',
  initials: name.substring(0, 2).toUpperCase(),
  brandColor: 0xFF000000,
  defaultPeriod: BillingPeriod.monthly,
  popularRank: popularRank,
  aliases: aliases,
);

final List<CatalogService> sampleCatalog = [
  catalogServiceFixture('netflix', 'Netflix', popularRank: 1),
  catalogServiceFixture('spotify', 'Spotify', popularRank: 2),
  catalogServiceFixture(
    'youtube_premium',
    'YouTube Premium',
    popularRank: 3,
    aliases: const ['yt', 'youtube'],
  ),
  catalogServiceFixture(
    'chatgpt_plus',
    'ChatGPT Plus',
    popularRank: 5,
    aliases: const ['openai', 'gpt'],
  ),
  catalogServiceFixture(
    'disney_plus',
    'Disney+',
    popularRank: 4,
    aliases: const ['disney plus'],
  ),
  catalogServiceFixture('apple_tv_plus', 'Apple TV+'),
  catalogServiceFixture('paramount_plus', 'Paramount+'),
  catalogServiceFixture('deezer', 'Deezer'),
  catalogServiceFixture('audible', 'Audible'),
  catalogServiceFixture('hulu', 'Hulu'),
  catalogServiceFixture(
    'dropbox',
    'Dropbox',
    aliases: const ['dropbox plus'],
  ),
  catalogServiceFixture('internet_archive', 'Web Archive Net'),
];
