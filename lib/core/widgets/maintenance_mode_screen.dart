import 'package:flutter/material.dart';

class MaintenanceModeScreen extends StatelessWidget {
  const MaintenanceModeScreen({
    super.key,
    this.message,
    this.onSignIn,
    this.onLogout,
  });

  final String? message;
  final VoidCallback? onSignIn;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    final text = (message ?? '').trim().isEmpty
        ? 'System under maintenance\n\nPlease try again later.'
        : message!.trim();

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.construction_rounded, size: 56),
                    const SizedBox(height: 10),
                    Text(
                      'Maintenance',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      text,
                      style: const TextStyle(color: Colors.black54, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        if (onSignIn != null)
                          FilledButton.icon(
                            onPressed: onSignIn,
                            icon: const Icon(Icons.login_rounded),
                            label: const Text('Sign in'),
                          ),
                        if (onLogout != null)
                          OutlinedButton.icon(
                            onPressed: onLogout,
                            icon: const Icon(Icons.logout_rounded),
                            label: const Text('Logout'),
                          ),
                      ],
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
