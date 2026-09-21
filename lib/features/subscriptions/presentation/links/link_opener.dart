abstract interface class LinkOpener {
  static const webSchemes = {'http', 'https'};

  Future<bool> open(Uri uri);
}
