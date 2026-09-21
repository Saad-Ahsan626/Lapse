class BackupFormatException implements Exception {
  const BackupFormatException(this.message);

  const BackupFormatException.notJson()
    : message = "This file couldn't be read. Choose a Lapse backup (.json).";

  const BackupFormatException.unreadable()
    : message = "Couldn't open that file.";

  const BackupFormatException.wrongApp()
    : message = "This file isn't a Lapse backup.";

  const BackupFormatException.newerVersion()
    : message =
          'This backup was made by a newer version of Lapse. '
          'Update the app to import it.';

  const BackupFormatException.missingVersion()
    : message = "This backup doesn't say which version made it.";

  const BackupFormatException.badExportDate()
    : message = "This backup's export date is missing or invalid.";

  const BackupFormatException.badSettings()
    : message = "This backup's settings are missing or invalid.";

  const BackupFormatException.badList()
    : message = "This backup's subscriptions or payments are missing.";

  factory BackupFormatException.badSubscription(String? name, int position) =>
      BackupFormatException(
        name == null || name.trim().isEmpty
            ? 'Subscription $position in this backup is invalid.'
            : '“${name.trim()}” in this backup is invalid.',
      );

  factory BackupFormatException.duplicateSubscription(String name) =>
      BackupFormatException('“$name” appears twice in this backup.');

  factory BackupFormatException.badPayment(int position) =>
      BackupFormatException('Payment $position in this backup is invalid.');

  final String message;

  @override
  String toString() => 'BackupFormatException: $message';
}
