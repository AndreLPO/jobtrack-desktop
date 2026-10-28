import 'package:flutter/material.dart';

import 'theme/app_spacing.dart';
import 'theme/app_theme.dart';

/// Executa a inicialização (Hive) antes de montar o app. Se ela falhar,
/// mostra uma tela de erro com "Tentar novamente" em vez de encerrar o
/// app (RN-08).
class Bootstrap extends StatefulWidget {
  const Bootstrap({
    super.key,
    required this.initialize,
    required this.appBuilder,
  });

  final Future<void> Function() initialize;
  final WidgetBuilder appBuilder;

  @override
  State<Bootstrap> createState() => _BootstrapState();
}

enum _BootstrapStatus { loading, ready, failed }

class _BootstrapState extends State<Bootstrap> {
  var _status = _BootstrapStatus.loading;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    setState(() => _status = _BootstrapStatus.loading);
    try {
      await widget.initialize();
      if (mounted) setState(() => _status = _BootstrapStatus.ready);
    } catch (error, stackTrace) {
      debugPrint('Falha ao inicializar os dados locais: $error\n$stackTrace');
      if (mounted) setState(() => _status = _BootstrapStatus.failed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return switch (_status) {
      _BootstrapStatus.ready => widget.appBuilder(context),
      _BootstrapStatus.loading => _StandaloneScreen(
        child: const CircularProgressIndicator(),
      ),
      _BootstrapStatus.failed => _StandaloneScreen(
        child: _InitializationError(onRetry: _run),
      ),
    };
  }
}

class _StandaloneScreen extends StatelessWidget {
  const _StandaloneScreen({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JobTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: Scaffold(body: Center(child: child)),
    );
  }
}

class _InitializationError extends StatelessWidget {
  const _InitializationError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Não foi possível abrir os dados locais',
            style: textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Seus registros não foram alterados. Tente novamente; se o '
            'problema continuar, reinicie o aplicativo.',
            style: textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: onRetry,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}
