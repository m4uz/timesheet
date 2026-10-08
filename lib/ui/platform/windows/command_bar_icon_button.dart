import 'package:fluent_ui/fluent_ui.dart';

/// Icon button used in Windows page-header command bars.
///
/// Every command bar uses this control so the hit target and padding match.
/// [FluentIcons.cloud_upload] only fills 75% of the em height, so that glyph
/// is scaled to the same ink height as the other toolbar icons.
class CommandBarIconButton extends StatelessWidget {
  const CommandBarIconButton({
    super.key,
    required this.message,
    required this.icon,
    required this.onPressed,
  });

  final String message;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final glyph = icon == FluentIcons.cloud_upload
        ? Transform.scale(scale: 4 / 3, child: Icon(icon))
        : Icon(icon);

    return Tooltip(
      message: message,
      child: IconButton(icon: glyph, onPressed: onPressed),
    );
  }
}
