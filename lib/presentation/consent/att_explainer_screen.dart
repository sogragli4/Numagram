import 'package:flutter/material.dart';
import 'package:nonogram_daily/core/l10n_gen/app_localizations.dart';

/// Shown once, right before the system App Tracking Transparency prompt
/// on iOS — the Phase 4 spec's "shown after a short explainer screen,
/// not cold". Never shown on Android (ATT doesn't exist there).
class AttExplainerScreen extends StatelessWidget {
  const AttExplainerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.privacy_tip_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                l10n.attExplainerTitle,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(l10n.attExplainerBody, textAlign: TextAlign.center),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.attContinueButtonLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
