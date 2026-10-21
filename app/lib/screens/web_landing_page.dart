/// The public download page, shown when Digital Saver runs in a browser.
///
/// Built on the Max Tools download page — same palette, same radii, same card
/// and button shapes — so the two products read as one family. One deliberate
/// departure, decided 2026-10-21: the three download cards are translucent
/// glass panels rather than opaque ones, using [GlassCard]. The palette, radii
/// and buttons are unchanged, so the page still reads as the same family while
/// the download choice sits visibly above the page.
///
/// Three things were wrong with the previous version beyond its appearance:
///
///  * The download links were built from filenames that have never existed on a
///    release (`digital_saver_windows_setup.exe`, `digital_saver_linux_installer.run`,
///    `digital_saver_android_v1.0.1-beta.apk`), pinned to a hardcoded
///    `v1.0.1-beta` tag. Every one of them 404'd. They now point at the
///    version-independent `releases/latest/download/` aliases for the assets
///    that actually exist.
///
///  * The version shown was that same hardcoded fallback whenever the network
///    call failed, so an offline browser displayed a release that had never
///    happened. The tag is now shown only when it has genuinely been read.
///
///  * The Windows instructions described a ZIP that does not exist and told the
///    reader to extract it and run an executable inside. The offer is a setup
///    executable that installs itself.
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/github_services.dart';
import '../utils/download_helper.dart';
import '../widgets/glassmorphic_widgets.dart';

/// Where release assets live. The `latest` alias cannot go stale, which is why
/// no version number appears in any download URL.
const String _assets =
    'https://github.com/Cambric-software/Digital-saver/releases/latest/download/';

/// The repository, for the source, licence and issue links.
const String _repo = 'https://github.com/Cambric-software/Digital-saver';

/// The colour values, matching the Max Tools page's stylesheet exactly.
class _Tokens {
  const _Tokens({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.border,
    required this.text,
    required this.muted,
    required this.accent,
    required this.accent2,
  });

  final Color bg;
  final Color surface;
  final Color surface2;
  final Color border;
  final Color text;
  final Color muted;
  final Color accent;
  final Color accent2;

  /// Dark is the default; light follows the reader's system setting.
  static const _Tokens dark = _Tokens(
    bg: Color(0xFF0E1015),
    surface: Color(0xFF171A22),
    surface2: Color(0xFF1E222C),
    border: Color(0xFF2A2F3B),
    text: Color(0xFFE8EAF0),
    muted: Color(0xFF9AA3B5),
    accent: Color(0xFF5B8CFF),
    accent2: Color(0xFF7C5BFF),
  );

  static const _Tokens light = _Tokens(
    bg: Color(0xFFF6F7FB),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFF0F2F7),
    border: Color(0xFFE0E3EC),
    text: Color(0xFF171A22),
    muted: Color(0xFF5C6474),
    accent: Color(0xFF3F6FE0),
    accent2: Color(0xFF6A44E0),
  );

  /// Resolve for the current brightness.
  static _Tokens of(BuildContext context) =>
      MediaQuery.platformBrightnessOf(context) == Brightness.dark
          ? dark
          : light;
}

/// Corner radii, matching the Max Tools page.
const double _radiusCard = 14;
const double _radiusButton = 11;
const double _radiusPillar = 12;
const double _radiusChip = 6;

/// The public download page.
class WebLandingPage extends StatefulWidget {
  /// Create the page.
  const WebLandingPage({super.key});

  @override
  State<WebLandingPage> createState() => _WebLandingPageState();
}

class _WebLandingPageState extends State<WebLandingPage> {
  final GithubService _github = const GithubService();
  final GlobalKey _platformsKey = GlobalKey();

  /// The published tag, once read. Null until then, and null if it could not be
  /// read — in which case nothing is shown rather than a guess.
  String? _tag;

  @override
  void initState() {
    super.initState();
    _readTag();
  }

  Future<void> _readTag() async {
    final tag = await _github.fetchLatestVersion();
    if (!mounted) return;
    setState(() => _tag = tag);
  }

  void _open(String url) {
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  void _scrollToPlatforms() {
    final context = _platformsKey.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _Tokens.of(context);

    return Scaffold(
      backgroundColor: t.bg,
      body: SelectionArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _header(context, t),
                    _platforms(context, t),
                    _inside(context, t),
                    _requirements(context, t),
                    _verify(context, t),
                    _footer(context, t),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- header

  Widget _header(BuildContext context, _Tokens t) {
    return Container(
      padding: const EdgeInsets.only(top: 64, bottom: 40),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.border)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[t.accent.withValues(alpha: 0.14), Colors.transparent],
          stops: const <double>[0, 0.7],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _logo(t, 38),
              const SizedBox(width: 12),
              Text(
                'Cambric Software',
                style: TextStyle(
                  color: t.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Digital Saver',
            style: TextStyle(
              color: t.text,
              fontSize: 46,
              height: 1.15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Text(
              "Cambric's health companion for the Veyro watch. Heart rate, blood "
              'oxygen and activity read straight from the watch and kept on your '
              'device. A wellness tool, not a medical device.',
              style: TextStyle(color: t.muted, fontSize: 19, height: 1.6),
            ),
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              _button(
                t,
                label: _tag == null
                    ? 'Download for your platform'
                    : 'Download $_tag',
                primary: true,
                onTap: _scrollToPlatforms,
              ),
              _button(
                t,
                label: 'Choose a platform',
                onTap: _scrollToPlatforms,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text.rich(
            TextSpan(
              style: TextStyle(color: t.muted, fontSize: 13),
              children: <InlineSpan>[
                const TextSpan(text: 'Every download ships with a '),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: _code(t, '.sha256'),
                ),
                const TextSpan(text: ' file. Verify it before installing.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- platforms

  Widget _platforms(BuildContext context, _Tokens t) {
    return Container(
      key: _platformsKey,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _h2(t, 'Download for your platform'),
          _sub(t, 'Links always point at the newest published release — no '
              'version numbers to guess.'),
          _Grid(
            children: <Widget>[
              _platformCard(
                context,
                t,
                emoji: '🪟',
                title: 'Windows',
                chip: 'x64',
                body:
                    'Recommended: the setup executable installs Digital Saver '
                    'for your user account, adds a desktop and Start Menu '
                    'shortcut, and can update itself later. No admin rights '
                    'required, and your data is preserved across updates.',
                primary: _button(
                  t,
                  label: 'Download installer',
                  primary: true,
                  onTap: () => downloadFile(
                    '${_assets}DigitalSaver-Setup.exe',
                    'DigitalSaver-Setup.exe',
                  ),
                ),
                secondary: _checksumButton(
                  t,
                  '${_assets}DigitalSaver-Setup.exe.sha256',
                ),
                note: 'Prefer no install? The portable archive works too, but a '
                    'portable copy cannot update itself in place.',
                extra: <Widget>[
                  _button(
                    t,
                    label: 'Portable .zip',
                    onTap: () =>
                        downloadFile('${_assets}windows.zip', 'windows.zip'),
                  ),
                  _checksumButton(t, '${_assets}windows.zip.sha256'),
                ],
              ),
              _platformCard(
                context,
                t,
                emoji: '🐧',
                title: 'Linux',
                chip: 'x64',
                body:
                    'Recommended: the .deb installs into a versioned layout '
                    'under /usr/lib/digital-saver with a launcher entry, so '
                    'updates apply cleanly.',
                primary: _button(
                  t,
                  label: 'Download .deb',
                  primary: true,
                  onTap: () => downloadFile(
                    '${_assets}digital-saver.deb',
                    'digital-saver.deb',
                  ),
                ),
                secondary: _checksumButton(
                  t,
                  '${_assets}digital-saver.deb.sha256',
                ),
                note: 'Or extract the tarball and run digital_saver from the '
                    'bundle folder. A tarball copy cannot update itself in '
                    'place.',
                extra: <Widget>[
                  _button(
                    t,
                    label: 'Portable .tar.gz',
                    onTap: () => downloadFile(
                      '${_assets}linux.tar.gz',
                      'linux.tar.gz',
                    ),
                  ),
                  _checksumButton(t, '${_assets}linux.tar.gz.sha256'),
                ],
              ),
              _platformCard(
                context,
                t,
                emoji: '🤖',
                title: 'Android',
                chip: 'APK',
                body:
                    'Universal APK for phones and tablets. Enable installs from '
                    'unknown sources, then open the APK. Android installs '
                    'updates itself through the system installer rather than '
                    'silently.',
                primary: _button(
                  t,
                  label: 'Download .apk',
                  primary: true,
                  onTap: () =>
                      downloadFile('${_assets}android.apk', 'android.apk'),
                ),
                secondary:
                    _checksumButton(t, '${_assets}android.apk.sha256'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _platformCard(
    BuildContext context,
    _Tokens t, {
    required String emoji,
    required String title,
    required String chip,
    required String body,
    required Widget primary,
    required Widget secondary,
    String? note,
    List<Widget> extra = const <Widget>[],
  }) {
    return _Card(
      t: t,
      glass: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: t.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 10),
              _chip(t, chip),
            ],
          ),
          const SizedBox(height: 10),
          Text(body, style: TextStyle(color: t.muted, fontSize: 14.5, height: 1.55)),
          const SizedBox(height: 14),
          Wrap(spacing: 10, runSpacing: 10, children: <Widget>[primary, secondary]),
          if (note != null) ...<Widget>[
            const SizedBox(height: 14),
            Text(
              note,
              style: TextStyle(color: t.muted, fontSize: 13, height: 1.5),
            ),
          ],
          if (extra.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Wrap(spacing: 10, runSpacing: 10, children: extra),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- inside

  Widget _inside(BuildContext context, _Tokens t) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _h2(t, 'What is inside'),
          _sub(t, 'What the watch measures, shown as it measured it.'),
          _Grid(
            minWidth: 220,
            children: <Widget>[
              _pillar(
                t,
                'Reads the watch',
                'Heart rate, blood oxygen, activity and motion come from the '
                    'Veyro watch over Bluetooth. Figures the watch does not '
                    'report are left blank rather than estimated.',
              ),
              _pillar(
                t,
                'Keeps it local',
                'Readings are stored on your device. There is no account and '
                    'nothing is uploaded to run the app.',
              ),
              _pillar(
                t,
                'Emergency help',
                'An SOS you can dial with one press, using an emergency number '
                    'you choose, and fall detection you can switch off.',
              ),
              _pillar(
                t,
                'Honest by design',
                'A wellness tool. It does not diagnose, and it is not a '
                    'substitute for professional care.',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pillar(_Tokens t, String title, String body) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: t.surface2,
        border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(_radiusPillar),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
              color: t.text,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(body, style: TextStyle(color: t.muted, fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------- requirements

  Widget _requirements(BuildContext context, _Tokens t) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _h2(t, 'Requirements'),
          const SizedBox(height: 8),
          _Row(
            children: <Widget>[
              _Card(
                t: t,
                child: Column(
                  children: <Widget>[
                    _tableRow(t, 'Platform', 'Needs', header: true),
                    _tableRow(t, 'Windows', 'Windows 10 or newer, 64-bit, Bluetooth'),
                    _tableRow(t, 'Linux', 'glibc distribution, 64-bit, GTK 3, Bluetooth'),
                    _tableRow(t, 'Android', 'Android 5.0 (API 21) or newer, Bluetooth'),
                  ],
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: Text(
                  'The watch is read over Bluetooth Low Energy. Digital Saver '
                  'runs entirely on your machine; the only network calls it '
                  'makes are checking for updates and, if you choose to use the '
                  'assistant, the questions you send it.',
                  style: TextStyle(color: t.muted, fontSize: 13.5, height: 1.55),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tableRow(_Tokens t, String left, String right, {bool header = false}) {
    final style = TextStyle(
      color: header ? t.muted : t.text,
      fontSize: 14.5,
      fontWeight: header ? FontWeight.w600 : FontWeight.w400,
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(width: 120, child: Text(left, style: style)),
          Expanded(child: Text(right, style: style)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- verify

  Widget _verify(BuildContext context, _Tokens t) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _h2(t, 'Verify your download'),
          _sub(t, 'Checksums are published next to every artifact.'),
          _Grid(
            children: <Widget>[
              _Card(
                t: t,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _h3(t, 'Windows'),
                    const SizedBox(height: 10),
                    Text(
                      'Run this in PowerShell next to the downloaded files.',
                      style: TextStyle(color: t.muted, fontSize: 14.5, height: 1.55),
                    ),
                    const SizedBox(height: 10),
                    _code(t, r'Get-FileHash .\windows.zip -Algorithm SHA256'),
                    const SizedBox(height: 10),
                    Text.rich(
                      TextSpan(
                        style: TextStyle(color: t.muted, fontSize: 14.5),
                        children: <InlineSpan>[
                          const TextSpan(text: 'Compare the output with '),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: _code(t, 'windows.zip.sha256'),
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _Card(
                t: t,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _h3(t, 'Linux'),
                    const SizedBox(height: 10),
                    Text(
                      'Verify the archive you downloaded.',
                      style: TextStyle(color: t.muted, fontSize: 14.5, height: 1.55),
                    ),
                    const SizedBox(height: 10),
                    _code(t, 'sha256sum -c linux.tar.gz.sha256'),
                    const SizedBox(height: 10),
                    Text.rich(
                      TextSpan(
                        style: TextStyle(color: t.muted, fontSize: 14.5),
                        children: <InlineSpan>[
                          const TextSpan(text: 'A result of '),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: _code(t, 'OK'),
                          ),
                          const TextSpan(text: ' means the file is intact.'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- footer

  Widget _footer(BuildContext context, _Tokens t) {
    return Container(
      padding: const EdgeInsets.only(top: 28, bottom: 56),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: t.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _logo(t, 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: TextStyle(color: t.muted, fontSize: 14, height: 1.55),
                    children: <InlineSpan>[
                      const TextSpan(
                        text: '© 2026 Cambric Software. Digital Saver is '
                            'proprietary software — see the ',
                      ),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: _link(t, 'licence', '$_repo/blob/main/LICENSE'),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: <Widget>[
              _link(t, 'Source', _repo),
              Text('·', style: TextStyle(color: t.muted)),
              _link(t, 'All releases', '$_repo/releases'),
              Text('·', style: TextStyle(color: t.muted)),
              _link(t, 'Report an issue', '$_repo/issues'),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ primitives

  Widget _logo(_Tokens t, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.26),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: t.accent.withValues(alpha: 0.18),
            blurRadius: 0,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.26),
        child: Image.asset(
          'assets/cambric-icon-transparent.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(
            Icons.business_rounded,
            size: size * 0.6,
            color: t.accent,
          ),
        ),
      ),
    );
  }

  Widget _h2(_Tokens t, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: TextStyle(
            color: t.text,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  Widget _h3(_Tokens t, String text) => Text(
        text,
        style: TextStyle(
          color: t.text,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      );

  Widget _sub(_Tokens t, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Text(
          text,
          style: TextStyle(color: t.muted, fontSize: 15.5, height: 1.5),
        ),
      );

  Widget _button(
    _Tokens t, {
    required String label,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    return _HoverButton(t: t, label: label, primary: primary, onTap: onTap);
  }

  Widget _checksumButton(_Tokens t, String url) => _button(
        t,
        label: 'Checksum',
        onTap: () => downloadFile(url, url.split('/').last),
      );

  Widget _chip(_Tokens t, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          border: Border.all(color: t.border),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: t.muted,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  Widget _code(_Tokens t, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: t.surface2,
          border: Border.all(color: t.border),
          borderRadius: BorderRadius.circular(_radiusChip),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: t.text,
            fontSize: 13.5,
            fontFamily: 'monospace',
          ),
        ),
      );

  Widget _link(_Tokens t, String label, String url) => GestureDetector(
        onTap: () => _open(url),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Text(
            label,
            style: TextStyle(
              color: t.accent,
              fontSize: 14,
              decoration: TextDecoration.underline,
              decorationColor: t.accent.withValues(alpha: 0.4),
            ),
          ),
        ),
      );
}

// --------------------------------------------------------------- components

/// A surface card, matching the Max Tools card shape.
class _Card extends StatelessWidget {
  const _Card({required this.t, required this.child, this.glass = false});

  final _Tokens t;
  final Widget child;

  /// Draw the translucent panel from `glassmorphic_widgets.dart`.
  ///
  /// Only the three download cards use it. They are the page's one
  /// transactional surface, and the blur and lift make the download choice read
  /// as sitting above the page. Everything else stays on the opaque panel so the
  /// page still carries the same palette and card shape as Max Tools; the glass
  /// is a deliberate departure, not a change to the colour system.
  final bool glass;

  @override
  Widget build(BuildContext context) {
    if (glass) {
      return GlassCard(
        padding: const EdgeInsets.all(22),
        borderRadius: _radiusCard,
        backgroundColor: t.surface.withValues(alpha: 0.62),
        border: Border.all(color: t.border),
        child: child,
      );
    }

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(_radiusCard),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// A button that lifts on hover, as the page's buttons do.
class _HoverButton extends StatefulWidget {
  const _HoverButton({
    required this.t,
    required this.label,
    required this.primary,
    required this.onTap,
  });

  final _Tokens t;
  final String label;
  final bool primary;
  final VoidCallback onTap;

  @override
  State<_HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<_HoverButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final borderColor = _hovered && !widget.primary ? t.accent : t.border;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
          decoration: BoxDecoration(
            gradient: widget.primary
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[t.accent, t.accent2],
                  )
                : null,
            color: widget.primary ? null : t.surface,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(_radiusButton),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: widget.primary ? Colors.white : t.text,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// Lays children out in as many columns as fit, like the CSS auto-fit grid.
class _Grid extends StatelessWidget {
  const _Grid({required this.children, this.minWidth = 280});

  final List<Widget> children;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const double gap = 18;
        final available = constraints.maxWidth;
        var columns = (available / minWidth).floor();
        if (columns < 1) columns = 1;
        if (columns > children.length) columns = children.length;
        final width = (available - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: <Widget>[
            for (final child in children)
              SizedBox(
                width: width,
                child: IntrinsicHeight(child: child),
              ),
          ],
        );
      },
    );
  }
}

/// A row that becomes a column when there is not room for two.
class _Row extends StatelessWidget {
  const _Row({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth < 720) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (final child in children) ...<Widget>[
                child,
                const SizedBox(height: 18),
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: children.first),
            const SizedBox(width: 18),
            children.last,
          ],
        );
      },
    );
  }
}
