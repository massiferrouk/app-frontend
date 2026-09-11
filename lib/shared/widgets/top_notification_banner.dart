import 'package:flutter/material.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Bannière de notification qui descend du haut de l'écran, façon « heads-up »
/// (comme les applis grand public : Vinted, WhatsApp…) — APP-122.
///
/// Affichée dans l'overlay du `navigatorKey` global de Stacked : elle peut donc
/// être déclenchée depuis un ViewModel, sans BuildContext, et reste visible
/// quel que soit l'onglet ouvert. Tapable (ouvre les notifications), et se
/// referme seule après quelques secondes.
class TopNotificationBanner {
  const TopNotificationBanner._();

  /// Une seule bannière à l'écran à la fois — la précédente est retirée.
  static OverlayEntry? _current;

  static void show({
    required String title,
    String? body,
    VoidCallback? onTap,
    Duration duration = const Duration(seconds: 4),
  }) {
    final overlay = StackedService.navigatorKey?.currentState?.overlay;
    // Pas d'overlay (ex : tests, app pas encore montée) → on ne fait rien.
    if (overlay == null) return;

    _current?.remove();
    _current = null;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _BannerContent(
        title: title,
        body: body,
        duration: duration,
        onTap: onTap == null
            ? null
            : () {
                _remove(entry);
                onTap();
              },
        onDismiss: () => _remove(entry),
      ),
    );
    _current = entry;
    overlay.insert(entry);
  }

  static void _remove(OverlayEntry entry) {
    if (_current == entry) _current = null;
    if (entry.mounted) entry.remove();
  }
}

/// Contenu animé de la bannière — gère son entrée (glissement depuis le haut),
/// sa sortie et l'auto-fermeture. Privé : on passe toujours par
/// [TopNotificationBanner.show].
class _BannerContent extends StatefulWidget {
  final String title;
  final String? body;
  final Duration duration;
  final VoidCallback? onTap;
  final VoidCallback onDismiss;

  const _BannerContent({
    required this.title,
    required this.body,
    required this.duration,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_BannerContent> createState() => _BannerContentState();
}

class _BannerContentState extends State<_BannerContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _slide = Tween<Offset>(begin: const Offset(0, -1.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();

    // Auto-fermeture après [duration] si l'utilisateur n'a rien fait.
    Future<void>.delayed(widget.duration, _close);
  }

  Future<void> _close() async {
    if (_closing || !mounted) return;
    _closing = true;
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = widget.body;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slide,
        child: Material(
          color: Colors.transparent,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, 0),
              child: GestureDetector(
                onTap: widget.onTap,
                // Un swipe vers le haut ferme la bannière (geste attendu).
                onVerticalDragEnd: (details) {
                  if ((details.primaryVelocity ?? 0) < 0) _close();
                },
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusCard),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: AppColors.echange,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.notifications_rounded,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (body != null && body.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
