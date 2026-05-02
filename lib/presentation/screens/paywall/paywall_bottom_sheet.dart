import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:keklist/domain/constants.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

const _kOfferingId = 'lifetime_offer';

// ---------------------------------------------------------------------------
// Plan model
// ---------------------------------------------------------------------------

enum _PlanType { monthly, annual, lifetime }

class _Plan {
  final _PlanType type;
  final String label;
  final Package? package;

  const _Plan({required this.type, required this.label, this.package});

  String get priceString => package?.storeProduct.priceString ?? '—';
  bool get available => package != null;
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

final class PaywallBottomSheet extends StatefulWidget {
  const PaywallBottomSheet({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PaywallBottomSheet(),
    );
    return result ?? false;
  }

  @override
  State<PaywallBottomSheet> createState() => _PaywallBottomSheetState();
}

final class _PaywallBottomSheetState extends State<PaywallBottomSheet> {
  List<_Plan> _plans = const [
    _Plan(type: _PlanType.monthly, label: '30 DAYS'),
    _Plan(type: _PlanType.annual, label: '1 YEAR'),
    _Plan(type: _PlanType.lifetime, label: 'LIFETIME'),
  ];
  _Plan? _selected;
  bool _loading = true;
  bool _purchasing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Package? _find(List<Package> all, _PlanType type) => switch (type) {
    _PlanType.monthly => all.firstWhereOrNull((p) => p.packageType == PackageType.monthly),
    _PlanType.annual => all.firstWhereOrNull((p) => p.packageType == PackageType.annual),
    _PlanType.lifetime => all.firstWhereOrNull(
      (p) =>
          p.packageType == PackageType.lifetime ||
          p.identifier.toLowerCase().contains('lifetime') ||
          p.storeProduct.identifier.toLowerCase().contains('lifetime'),
    ),
  };

  Future<void> _loadOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      final offering = offerings.all[_kOfferingId] ?? offerings.current;
      final all = offering?.availablePackages ?? [];

      final plans = [
        _Plan(type: _PlanType.monthly, label: '30 DAYS', package: _find(all, _PlanType.monthly)),
        _Plan(type: _PlanType.annual, label: '1 YEAR', package: _find(all, _PlanType.annual)),
        _Plan(type: _PlanType.lifetime, label: 'LIFETIME', package: _find(all, _PlanType.lifetime)),
      ];

      setState(() {
        _plans = plans;
        _selected = plans.firstWhereOrNull((p) => p.available);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _purchase() async {
    final pkg = _selected?.package;
    if (pkg == null) return;
    setState(() => _purchasing = true);
    try {
      await Purchases.purchase(PurchaseParams.package(pkg));
      if (mounted) Navigator.of(context).pop(true);
    } on PurchasesError catch (e) {
      if (e.code != PurchasesErrorCode.purchaseCancelledError && mounted) {
        _showError(e.message);
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _purchasing = true);
    try {
      final info = await Purchases.restorePurchases();
      if (mounted) {
        if (info.entitlements.active.isNotEmpty) {
          Navigator.of(context).pop(true);
        } else {
          _showError('No active subscriptions found.');
        }
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Themes.dark;
    return Theme(
      data: theme,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🤝', style: TextStyle(fontSize: 48)),
                    const Gap(12),
                    const Text('keklist PRO', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const Gap(8),
                    Text('Unlock all features', style: TextStyle(fontSize: 15, color: Colors.grey.shade400)),
                    const Gap(8),
                    const Gap(12),
                    const _FeatureList(),
                    const Gap(28),
                    if (_loading)
                      const CircularProgressIndicator()
                    else if (_error != null)
                      Text(_error!, style: const TextStyle(color: Colors.redAccent))
                    else ...[
                      Row(
                        children: _plans.map((plan) {
                          final isSelected = _selected == plan;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                left: plan == _plans.first ? 0 : 6,
                                right: plan == _plans.last ? 0 : 6,
                              ),
                              child: _PlanCard(
                                plan: plan,
                                isSelected: isSelected,
                                onTap: plan.available ? () {
                  Haptics.vibrate(HapticsType.light);
                  setState(() => _selected = plan);
                } : null,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const Gap(20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: (_purchasing || _selected?.available != true) ? null : _purchase,
                          child: _purchasing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  _selected != null ? 'Subscribe · ${_selected!.priceString}' : 'Subscribe',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),
                      const Gap(12),
                      GestureDetector(
                        onTap: _purchasing ? null : _restore,
                        child: Text('Restore purchases', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                      ),
                      const Gap(16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _LegalLink(label: 'Privacy Policy', url: KeklistConstants.privacyURL),
                          Text('  ·  ', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                          _LegalLink(label: 'Terms of Use', url: KeklistConstants.termsOfUseURL),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Feature list
// ---------------------------------------------------------------------------

class _FeatureList extends StatelessWidget {
  const _FeatureList();

  @override
  Widget build(BuildContext context) {
    const features = [
      ('🙂', 'support our project'),
      ('☀️', 'weather per each day'),
      ('☁️', 'access to online features'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: features
          .map(
            (f) => Row(
              children: [
                Text(f.$1, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Text(f.$2, style: TextStyle(fontSize: 14, color: Colors.grey.shade300)),
              ],
            ),
          )
          .toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Plan card
// ---------------------------------------------------------------------------

class _PlanCard extends StatelessWidget {
  final _Plan plan;
  final bool isSelected;
  final VoidCallback? onTap;

  const _PlanCard({required this.plan, required this.isSelected, this.onTap});

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected ? Colors.white : Colors.grey.shade800;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: AspectRatio(
          aspectRatio: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                plan.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: isSelected ? Colors.white : Colors.grey.shade400,
                ),
              ),
              const Gap(8),
              Text(
                plan.priceString,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegalLink extends StatelessWidget {
  final String label;
  final String url;

  const _LegalLink({required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
    );
  }
}
