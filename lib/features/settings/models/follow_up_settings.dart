/// Configurações de acompanhamento (RF-10, D-25, D-40).
class FollowUpSettings {
  const FollowUpSettings({
    this.intervalDays = defaultIntervalDays,
    this.maxAttempts = defaultMaxAttempts,
  }) : assert(
         intervalDays >= minIntervalDays && intervalDays <= maxIntervalDays,
       ),
       assert(maxAttempts >= minMaxAttempts && maxAttempts <= maxMaxAttempts);

  static const defaultIntervalDays = 7;
  static const minIntervalDays = 1;
  static const maxIntervalDays = 90;

  static const defaultMaxAttempts = 3;
  static const minMaxAttempts = 1;
  static const maxMaxAttempts = 10;

  /// Prazo em dias corridos (D-20).
  final int intervalDays;

  /// Acompanhamentos sem resposta antes de "sugerido encerrar".
  final int maxAttempts;

  static bool isValidIntervalDays(int value) =>
      value >= minIntervalDays && value <= maxIntervalDays;

  static bool isValidMaxAttempts(int value) =>
      value >= minMaxAttempts && value <= maxMaxAttempts;
}
