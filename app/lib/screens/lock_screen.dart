/// The app lock, shown before anything else when a PIN is set.
///
/// [AppLock] has been able to set, verify, throttle and clear a PIN since it was
/// written, and nothing ever asked it to. Settings offered "Set a PIN", the PIN
/// was stored correctly, and the app then opened with no lock at all - a control
/// that looked like protection and provided none. The only honest options were
/// to remove the feature or to ask for the PIN, and this is the asking.
///
/// [LockGate] wraps the app rather than sitting inside a screen, so there is no
/// route around it: the shell is not built while the lock is shut.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/app_lock.dart';
import '../theme/design_tokens.dart';
import '../widgets/ds_widgets.dart';

/// Shows [child] unless a PIN is set and not yet entered.
class LockGate extends StatelessWidget {
  /// Wrap the app.
  const LockGate({super.key, required this.child});

  /// What to show once the lock is open.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final AppLock lock = context.watch<AppLock>();

    // Reading the stored hash is a disk read; showing the app before it
    // finishes would flash the contents the PIN is meant to cover.
    if (!lock.ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!lock.hasLock || lock.unlocked) return child;
    return const LockScreen();
  }
}

/// The PIN screen itself.
class LockScreen extends StatefulWidget {
  /// Create the screen.
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final TextEditingController _pin = TextEditingController();
  final FocusNode _focus = FocusNode();

  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _focus.requestFocus();
  }

  @override
  void dispose() {
    _pin.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String pin = _pin.text.trim();
    if (pin.length != 6) {
      setState(() => _error = 'The PIN is six digits.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final AppLock lock = context.read<AppLock>();
    final bool opened = await lock.unlock(pin);
    if (!mounted) return;

    setState(() {
      _busy = false;
      if (!opened) {
        final Duration? wait = lock.lockoutRemaining;
        _error = wait == null
            ? 'That PIN is not right.'
            : 'Too many attempts. Try again in ${wait.inSeconds + 1}s.';
        _pin.clear();
      }
    });

    if (!opened) _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Space.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: DsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 32,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: Space.md),
                    Text(
                      'Digital Saver is locked',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: Space.xs),
                    Text(
                      'Enter your six-digit PIN to continue.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: Space.xl),
                    TextField(
                      controller: _pin,
                      focusNode: _focus,
                      autofocus: true,
                      enabled: !_busy,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: Type.metricSmall,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(
                        labelText: 'PIN',
                        counterText: '',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (_error != null) ...<Widget>[
                      const SizedBox(height: Space.sm),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: Space.lg),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Unlock'),
                    ),
                    const SizedBox(height: Space.md),
                    Text(
                      'The PIN is checked on this device. There is no account '
                      'and no way to recover it: if you forget it, the app lock '
                      'can only be cleared by reinstalling, which removes the '
                      'stored data.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
