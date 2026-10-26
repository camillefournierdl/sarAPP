import 'package:flutter/foundation.dart' show kDebugMode;

/// Compile-time feature flags. Since they are `const`, disabled UI is
/// tree-shaken out of release builds; the backend code stays in the repo.
///
/// Debug builds always count as test releases. Build a test release with:
///   flutter build apk --dart-define=TEST_RELEASE=true
const bool kTestRelease =
    kDebugMode || bool.fromEnvironment('TEST_RELEASE');

/// Analytics tab, nerd mode and test-data seeding. Hidden in public releases
/// until analytics is ready; Settings shows a "coming soon" tile instead.
const bool kAnalyticsEnabled = kTestRelease;
