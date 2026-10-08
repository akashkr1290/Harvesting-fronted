import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/app_config.dart';
import '../../services/auth_service.dart';
import '../../services/localization_service.dart';
import '../../services/ui_mode_service.dart';
import '../../services/voice_service.dart';

/// Colours and sizes for Simple mode: high contrast, big type, big targets.
class SimpleColors {
  static const ground = Color(0xFFF7F4EC);
  static const ink = Color(0xFF1F2A1F);
  static const quiet = Color(0xFF4A5A4A);
  static const green = Color(0xFF1E6B3A);
  static const greenSoft = Color(0xFFE3EFE5);
  static const marigold = Color(0xFFE8A317);
  static const marigoldSoft = Color(0xFFFFF4D6);
  static const red = Color(0xFFB3261E);
  static const orange = Color(0xFFB45F06);
  static const line = Color(0xFFCFC8B6);
}

/// Speaker button: reads [text] aloud in the app language.
class SpeakButton extends StatelessWidget {
  final String Function() text;
  final double size;
  const SpeakButton({super.key, required this.text, this.size = 56});

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    final voice = context.watch<VoiceService>();
    return Semantics(
      button: true,
      label: loc.t('listen'),
      child: Material(
        color: SimpleColors.marigold,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => voice.isSpeaking ? voice.stop() : voice.speak(text(), language: loc.ttsLanguage),
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(voice.isSpeaking ? Icons.stop_rounded : Icons.volume_up_rounded,
                size: size * 0.5, color: SimpleColors.ink),
          ),
        ),
      ),
    );
  }
}

/// Header used on every Simple screen: back, title (+ small English-free subtitle), speaker.
class SimpleHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool showBack;
  final String Function()? speakText;
  final Widget? trailing;

  const SimpleHeader({super.key, required this.title, this.subtitle, this.showBack = true, this.speakText, this.trailing});

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          if (showBack)
            Semantics(
              button: true,
              label: loc.t('back'),
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(side: BorderSide(color: SimpleColors.line, width: 2)),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.of(context).maybePop(),
                  child: const SizedBox(
                      width: 52, height: 52, child: Icon(Icons.arrow_back_rounded, size: 28, color: SimpleColors.ink)),
                ),
              ),
            ),
          if (showBack) const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: SimpleColors.ink, height: 1.15)),
                if (subtitle != null)
                  Text(subtitle!, style: const TextStyle(fontSize: 15, color: SimpleColors.quiet)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
          if (speakText != null) ...[
            const SizedBox(width: 8),
            SpeakButton(text: speakText!),
          ],
        ],
      ),
    );
  }
}

/// Large tappable tile: picture/icon + 1-2 words. Used for home screens.
class BigActionTile extends StatelessWidget {
  final Widget icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool primary;
  final int? badge;
  final double height;
  final Widget? trailing;

  const BigActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.primary = false,
    this.badge,
    this.height = 140,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final fg = primary ? Colors.white : SimpleColors.ink;
    return Semantics(
      button: true,
      label: badge != null && badge! > 0 ? '$title, $badge' : title,
      child: Material(
        color: primary ? SimpleColors.green : Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Container(
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: primary ? null : Border.all(color: SimpleColors.line, width: 2),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      icon,
                      const SizedBox(height: 6),
                      Text(title,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: fg, height: 1.1)),
                      if (subtitle != null)
                        Text(subtitle!,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 15, color: primary ? Colors.white70 : SimpleColors.quiet)),
                      if (trailing != null) trailing!,
                    ],
                  ),
                ),
                if (badge != null && badge! > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 34),
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(color: SimpleColors.red, borderRadius: BorderRadius.circular(17)),
                      alignment: Alignment.center,
                      child: Text('$badge',
                          style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-width primary button, at least 64 px tall.
class BigButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color color;
  final bool outlined;
  final bool busy;

  const BigButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = SimpleColors.green,
    this.outlined = false,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = busy
        ? const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, size: 28), const SizedBox(width: 10)],
              Flexible(
                child: Text(label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              ),
            ],
          );
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(18));
    return SizedBox(
      width: double.infinity,
      height: 68,
      child: outlined
          ? OutlinedButton(
              onPressed: busy ? null : onPressed,
              style: OutlinedButton.styleFrom(
                  foregroundColor: color, side: BorderSide(color: color, width: 2), shape: shape, backgroundColor: Colors.white),
              child: child,
            )
          : ElevatedButton(
              onPressed: busy ? null : onPressed,
              style: ElevatedButton.styleFrom(
                  backgroundColor: color, foregroundColor: Colors.white, shape: shape, elevation: 0),
              child: child,
            ),
    );
  }
}

/// Calls the FPO / support helpline (set with --dart-define=HELPLINE_NUMBER). Hidden when not configured.
class HelpCallButton extends StatelessWidget {
  const HelpCallButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (AppConfig.helplineNumber.isEmpty) return const SizedBox.shrink();
    final loc = context.watch<LocalizationService>();
    return BigButton(
      label: loc.t('help_call'),
      icon: Icons.call_rounded,
      outlined: true,
      onPressed: () => launchUrl(Uri(scheme: 'tel', path: AppConfig.helplineNumber)),
    );
  }
}

/// Simple / Detailed switch, available on every home screen.
class ModeToggle extends StatelessWidget {
  final bool onDark;
  const ModeToggle({super.key, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    final modes = context.watch<UiModeService>();
    final role = context.watch<AuthService>().role;
    final simple = modes.isSimple(role);
    Widget pill(String label, bool active, UiMode mode) => Semantics(
          button: true,
          selected: active,
          label: label,
          child: GestureDetector(
            onTap: () => modes.setMode(mode),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? (onDark ? Colors.white : SimpleColors.green) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                    color: active
                        ? (onDark ? SimpleColors.green : Colors.white)
                        : (onDark ? Colors.white : SimpleColors.ink),
                  )),
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: onDark ? Colors.white24 : const Color(0xFFE7E1D2),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          pill(loc.t('simple_mode'), simple, UiMode.simple),
          pill(loc.t('detailed_mode'), !simple, UiMode.detailed),
        ],
      ),
    );
  }
}

/// Big -/+ stepper with quick-pick chips; [onVoice] fills the value by speech.
class QuantityStepper extends StatelessWidget {
  final double value;
  final double step;
  final double min;
  final String unitLabel;
  final String Function(double) format;
  final ValueChanged<double> onChanged;
  final List<double> quickPicks;
  final String Function(double)? quickLabel;
  final VoidCallback? onVoice;

  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    required this.unitLabel,
    this.step = 10,
    this.min = 0,
    this.quickPicks = const [],
    this.quickLabel,
    this.onVoice,
    String Function(double)? format,
  }) : format = format ?? _plain;

  static String _plain(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    Widget round(IconData icon, VoidCallback? onTap, bool filled, String label) => Semantics(
          button: true,
          label: label,
          child: Material(
            color: filled ? SimpleColors.green : Colors.white,
            shape: CircleBorder(side: BorderSide(color: SimpleColors.green, width: filled ? 0 : 2)),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox(
                  width: 64, height: 64, child: Icon(icon, size: 32, color: filled ? Colors.white : SimpleColors.green)),
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SimpleColors.line, width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              round(Icons.remove_rounded, value - step >= min ? () => onChanged(value - step) : null, false, '-'),
              Expanded(
                child: Column(
                  children: [
                    FittedBox(
                      child: Text(format(value),
                          style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800, color: SimpleColors.ink)),
                    ),
                    Text(unitLabel, style: const TextStyle(fontSize: 18, color: SimpleColors.quiet, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              round(Icons.add_rounded, () => onChanged(value + step), true, '+'),
            ],
          ),
          if (quickPicks.isNotEmpty || onVoice != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final q in quickPicks)
                  ChoiceChip(
                    label: Text(quickLabel?.call(q) ?? _plain(q),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    selected: value == q,
                    selectedColor: SimpleColors.greenSoft,
                    side: BorderSide(color: value == q ? SimpleColors.green : SimpleColors.line, width: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    onSelected: (_) => onChanged(q),
                  ),
                if (onVoice != null)
                  ActionChip(
                    avatar: const Icon(Icons.mic_rounded, color: SimpleColors.green),
                    label: Text(context.watch<LocalizationService>().t('speak_number'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    side: const BorderSide(color: SimpleColors.green, width: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    onPressed: onVoice,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// "Mandi today ₹30/kg" next to a price, with an up/down arrow showing the difference.
class MandiCompare extends StatelessWidget {
  final double? mandiPerKg;
  final double? pricePerKg;
  const MandiCompare({super.key, required this.mandiPerKg, this.pricePerKg});

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    if (mandiPerKg == null) {
      return Text(loc.t('mandi_unknown'), style: const TextStyle(fontSize: 15, color: SimpleColors.quiet));
    }
    if (pricePerKg == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: SimpleColors.marigoldSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SimpleColors.marigold, width: 2),
        ),
        child: Row(
          children: [
            const Icon(Icons.storefront_rounded, color: Color(0xFF8A5A00), size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Text(loc.tf('mandi_today', {'price': mandiPerKg!.toStringAsFixed(0)}),
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: SimpleColors.ink)),
            ),
          ],
        ),
      );
    }
    final diff = pricePerKg! - mandiPerKg!;
    final up = diff > 0.49;
    final down = diff < -0.49;
    final color = up ? SimpleColors.green : (down ? SimpleColors.red : SimpleColors.quiet);
    final text = up
        ? loc.tf('above_mandi', {'diff': diff.abs().toStringAsFixed(0)})
        : down
            ? loc.tf('below_mandi', {'diff': diff.abs().toStringAsFixed(0)})
            : loc.t('same_as_mandi');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(up ? Icons.arrow_upward_rounded : (down ? Icons.arrow_downward_rounded : Icons.drag_handle_rounded),
            color: color, size: 22),
        const SizedBox(width: 4),
        Flexible(child: Text(text, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: color))),
      ],
    );
  }
}

/// Step dots for wizards (current step is a long bar).
class StepDots extends StatelessWidget {
  final int current;
  final int total;
  const StepDots({super.key, required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    return Semantics(
      label: loc.tf('step_of', {'n': current + 1, 'total': total}),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < total; i++)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == current ? 28 : 10,
              height: 10,
              decoration: BoxDecoration(
                color: i <= current ? SimpleColors.green : SimpleColors.line,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
        ],
      ),
    );
  }
}

enum PillKind { good, waiting, bad, neutral }

/// Status shown by colour AND icon AND words, never colour alone.
class StatusPill extends StatelessWidget {
  final PillKind kind;
  final String text;
  const StatusPill({super.key, required this.kind, required this.text});

  @override
  Widget build(BuildContext context) {
    final (Color c, IconData i) = switch (kind) {
      PillKind.good => (SimpleColors.green, Icons.check_circle_rounded),
      PillKind.waiting => (SimpleColors.orange, Icons.schedule_rounded),
      PillKind.bad => (SimpleColors.red, Icons.cancel_rounded),
      PillKind.neutral => (SimpleColors.quiet, Icons.circle_outlined),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(i, size: 20, color: c),
          const SizedBox(width: 6),
          Flexible(child: Text(text, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c))),
        ],
      ),
    );
  }
}

/// Page frame for Simple screens: warm background, safe area, scrolling body, fixed bottom actions.
class SimplePage extends StatelessWidget {
  final Widget header;
  final List<Widget> children;
  final List<Widget> bottom;
  const SimplePage({super.key, required this.header, required this.children, this.bottom = const []});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SimpleColors.ground,
      body: SafeArea(
        child: Column(
          children: [
            header,
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: children,
              ),
            ),
            if (bottom.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  for (var i = 0; i < bottom.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    bottom[i],
                  ],
                ]),
              ),
          ],
        ),
      ),
    );
  }
}

/// Formats rupees the Indian way: 1,23,456.
String rupees(num value) {
  final s = value.round().abs().toString();
  if (s.length <= 3) return '₹${value < 0 ? '-' : ''}$s';
  final last3 = s.substring(s.length - 3);
  var rest = s.substring(0, s.length - 3);
  final parts = <String>[];
  while (rest.length > 2) {
    parts.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) parts.insert(0, rest);
  return '₹${value < 0 ? '-' : ''}${parts.join(',')},$last3';
}

/// Whether the logged-in user should see Simple screens.
bool useSimple(BuildContext context) =>
    context.watch<UiModeService>().isSimple(context.watch<AuthService>().role);
