import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/models/accord_summary.dart';
import 'home_alternant_viewmodel.dart';

/// Dashboard alternant — onglet Accueil du shell.
/// [onSeeMatches] permet de basculer sur l'onglet Matches du shell.
class HomeAlternantView extends StackedView<HomeAlternantViewModel> {
  final VoidCallback? onSeeMatches;

  const HomeAlternantView({super.key, this.onSeeMatches});

  @override
  Widget builder(
    BuildContext context,
    HomeAlternantViewModel viewModel,
    Widget? child,
  ) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: viewModel.load,
        color: AppColors.echange,
        child: _buildBody(context, viewModel),
      ),
    );
  }

  Widget _buildBody(BuildContext context, HomeAlternantViewModel viewModel) {
    if (viewModel.isBusy && viewModel.dashboard == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.echange),
      );
    }

    if (viewModel.errorMessage != null && viewModel.dashboard == null) {
      return _ErrorState(
        message: viewModel.errorMessage!,
        onRetry: viewModel.load,
      );
    }

    final dash = viewModel.dashboard!;
    final prochain = dash.prochainAccords.isNotEmpty
        ? dash.prochainAccords.first
        : null;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Bonjour 👋',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            Badge(
              label: Text('${viewModel.unreadCount}'),
              isLabelVisible: viewModel.unreadCount > 0,
              backgroundColor: AppColors.error,
              child: IconButton(
                tooltip: 'Notifications',
                onPressed: viewModel.goToNotifications,
                icon: const Icon(Icons.notifications_outlined, size: 26),
              ),
            ),
          ],
        ),
        Text('Voici où tu en es', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppSpacing.lg),

        // ─── Ton alternance cette semaine (APP-117) ─────────────
        // Toujours présente si le calendrier est chargé : l'accueil n'est
        // plus jamais vide, même pour un compte tout neuf.
        if (viewModel.semaineAAfficher != null) ...[
          _cetteSemaineCard(context, viewModel),
          const SizedBox(height: AppSpacing.lg),
        ],

        // ─── KPIs ───────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _StatCard(
                value: '${dash.economiesEstimees.toStringAsFixed(0)} €',
                label: 'économisés',
                valueColor: AppColors.echange,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _StatCard(
                value: '${dash.nbAccordsTermines}',
                label: dash.nbAccordsTermines > 1
                    ? 'échanges terminés'
                    : 'échange terminé',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // ─── Prochain échange / Premières étapes (APP-117) ──────
        if (prochain != null) ...[
          Text('Prochain échange',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          _AccordTile(
            accord: prochain,
            onTap: () => viewModel.goToAccordDetail(prochain),
          ),
          const SizedBox(height: AppSpacing.lg),
        ] else if (viewModel.isNouveau) ...[
          // Compte neuf : une carte avec UNE action claire, au lieu du vide.
          _bienvenueCard(context, viewModel),
          const SizedBox(height: AppSpacing.lg),
        ] else ...[
          Text('Prochain échange',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          const _EmptyCard(
            text: 'Aucun échange programmé.\nTrouve ton prochain match !',
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // ─── Accords en attente ─────────────────────────────────
        if (dash.accordsEnAttente.isNotEmpty) ...[
          Text(
            'En attente de réponse',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          ...dash.accordsEnAttente.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _AccordTile(
                accord: a,
                showCountdown: true,
                onTap: () => viewModel.goToAccordDetail(a),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // ─── Actions rapides ────────────────────────────────────
        ElevatedButton.icon(
          onPressed: onSeeMatches,
          icon: const Icon(Icons.swap_horiz),
          label: const Text('Voir mes matches'),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: viewModel.goToCalendrier,
          icon: const Icon(Icons.calendar_month_outlined),
          label: const Text('Mon calendrier d\'alternance'),
        ),
      ],
    );
  }

  // Carte « cette semaine » : ville courante + semaine prochaine. L'info ville
  // n'est jamais portée par la seule couleur (règle OPQUAST) : nom de ville en
  // texte + libellé école/entreprise ; la pastille n'est que décorative.
  Widget _cetteSemaineCard(BuildContext context, HomeAlternantViewModel vm) {
    final semaine = vm.semaineAAfficher!;
    final commencee = vm.alternanceCommencee;
    final prochaine = vm.semaineProchaine;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.place_outlined,
                  size: 16, color: AppColors.textTertiary),
              const SizedBox(width: 6),
              Text(commencee ? 'CETTE SEMAINE' : 'PROCHAINEMENT',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: AppColors.textTertiary)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _villeDot(vm.estEcole(semaine)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(vm.villeDe(semaine),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700)),
              ),
              Text(vm.estEcole(semaine) ? 'école' : 'entreprise',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          // Alternance en cours : on montre la semaine suivante.
          if (commencee && prochaine != null) ...[
            const Divider(height: AppSpacing.lg),
            Row(
              children: [
                _villeDot(vm.estEcole(prochaine)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text('Semaine prochaine · ${vm.villeDe(prochaine)}',
                      style: Theme.of(context).textTheme.bodySmall),
                ),
                Text(vm.estEcole(prochaine) ? 'école' : 'entreprise',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ]
          // Pas encore commencée : on indique la date de démarrage.
          else if (!commencee) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('Ton alternance démarre le '
                '${DateFormat('dd/MM/yyyy').format(semaine.semaine)}',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }

  Widget _villeDot(bool ecole) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ecole ? AppColors.villeA : AppColors.villeB,
        ),
      );

  // Carte d'accueil pour un compte neuf : UNE seule action, choisie selon
  // l'état réel — publier son logement d'abord (c'est ce qui active les
  // échanges), sinon explorer les matches.
  Widget _bienvenueCard(BuildContext context, HomeAlternantViewModel vm) {
    final doitPublier = !vm.hasPublishedLogement;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.echangeLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(doitPublier ? Icons.add_home_outlined : Icons.swap_horiz,
              size: 28, color: AppColors.echange),
          const SizedBox(height: AppSpacing.sm),
          Text(doitPublier ? 'Active tes échanges' : 'Trouve ton match',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
              doitPublier
                  ? 'Publie ton logement pour que les alternants au rythme '
                      'inverse puissent te proposer un échange.'
                  : 'Des alternants au rythme inverse peuvent échanger leur '
                      'logement avec le tien.',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            onPressed: doitPublier ? vm.goToGererLogements : onSeeMatches,
            icon:
                Icon(doitPublier ? Icons.add_home_outlined : Icons.swap_horiz),
            label:
                Text(doitPublier ? 'Publier mon logement' : 'Voir mes matches'),
          ),
        ],
      ),
    );
  }

  @override
  HomeAlternantViewModel viewModelBuilder(BuildContext context) =>
      HomeAlternantViewModel();

  @override
  void onViewModelReady(HomeAlternantViewModel viewModel) => viewModel.load();
}

// ─── Widgets internes ─────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;

  const _StatCard({
    required this.value,
    required this.label,
    this.valueColor = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _AccordTile extends StatelessWidget {
  final AccordSummary accord;
  final bool showCountdown;
  final VoidCallback? onTap;

  const _AccordTile({
    required this.accord,
    this.showCountdown = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dates =
        '${DateFormat('dd/MM').format(accord.dateDebut)} → '
        '${DateFormat('dd/MM/yyyy').format(accord.dateFin)}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.echangeLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        ),
        child: Row(
          children: [
            const Icon(Icons.swap_horiz, color: AppColors.echange),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    accord.type.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(dates, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            if (showCountdown && accord.heuresAvantExpiration != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.chevauchementLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
                ),
                child: Text(
                  '${accord.heuresAvantExpiration}h restantes',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.chevauchement,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String text;

  const _EmptyCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        const SizedBox(height: 120),
        const Icon(
          Icons.cloud_off_outlined,
          size: 48,
          color: AppColors.textTertiary,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: TextButton(onPressed: onRetry, child: const Text('Réessayer')),
        ),
      ],
    );
  }
}
