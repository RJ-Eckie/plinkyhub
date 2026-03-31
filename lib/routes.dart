/// Navigation tab routes in sidebar order.
enum AppRoute {
  myPlinky('/my-plinky'),
  editor('/editor'),
  presets('/presets', itemSegment: 'preset'),
  packs('/packs', itemSegment: 'pack'),
  samples('/samples', itemSegment: 'sample'),
  wavetables('/wavetables', itemSegment: 'wavetable'),
  patterns('/patterns', itemSegment: 'pattern'),
  users('/users'),
  profile('/profile'),
  about('/about'),
  ;

  const AppRoute(this.path, {this.itemSegment});

  /// The URL path for this tab route.
  final String path;

  /// The singular path segment used in detail routes (e.g. 'preset'
  /// for `/:username/preset/:name`). Null for tabs without item pages.
  final String? itemSegment;

  /// All tab paths in sidebar order, for indexed navigation.
  static final tabPaths = AppRoute.values.map((r) => r.path).toList();

  /// The route shown when the app starts.
  static const initial = AppRoute.myPlinky;

  /// Path to a tab's sub-tab (e.g. `/presets/community`).
  String tab(String tabName) => '$path/$tabName';

  /// Path to a user's item detail page for this route type.
  String itemPage(String username, String name) =>
      '/$username/$itemSegment/${Uri.encodeComponent(name)}';

  /// Path to a user's sample edit page.
  static String sampleEditPage(String username, String name) =>
      '/$username/${AppRoute.samples.itemSegment}/'
      '${Uri.encodeComponent(name)}/edit';

  /// Path to a user's profile page.
  static String userPage(String username) => '/$username';
}
