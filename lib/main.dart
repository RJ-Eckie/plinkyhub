import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plinkyhub/pages/about_page.dart';
import 'package:plinkyhub/pages/editor_page.dart';
import 'package:plinkyhub/pages/saved_patches_page.dart';
import 'package:plinkyhub/widgets/authentication_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  runApp(const ProviderScope(child: PlinkyHubApp()));
}

class PlinkyHubApp extends StatelessWidget {
  const PlinkyHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PlinkyHub',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF28222E),
        useMaterial3: true,
        textTheme: TextTheme(
          headlineLarge: GoogleFonts.fingerPaint(),
          headlineMedium: GoogleFonts.fingerPaint(),
          headlineSmall: GoogleFonts.fingerPaint(),
        ),
      ),
      home: const PlinkyHubShell(),
    );
  }
}

class PlinkyHubShell extends StatefulWidget {
  const PlinkyHubShell({super.key});

  @override
  State<PlinkyHubShell> createState() => _PlinkyHubShellState();
}

class _PlinkyHubShellState extends State<PlinkyHubShell> {
  int _selectedIndex = 0;

  static const _pages = <Widget>[
    EditorPage(),
    SavedPatchesPage(),
    AboutPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            leading: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'Plinky\n'),
                    TextSpan(text: 'Hub'),
                  ],
                ),
                style: GoogleFonts.fingerPaint(
                  textStyle: Theme.of(context).textTheme.titleLarge,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            trailing: const Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: AuthenticationButton(),
                ),
              ),
            ),
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.piano_outlined),
                selectedIcon: Icon(Icons.piano),
                label: Text('Editor'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.cloud_outlined),
                selectedIcon: Icon(Icons.cloud),
                label: Text('My Patches'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.info_outline),
                selectedIcon: Icon(Icons.info),
                label: Text('About'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
    );
  }
}
