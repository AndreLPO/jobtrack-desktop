/// Tipo de contato registrado na candidatura (D-15).
enum InteractionType {
  /// Conta como tentativa para o limite de acompanhamentos (D-25).
  followUpSent,
  messageReceived,
  call,

  /// Base da sugestão de agradecimento em 1 dia (D-22).
  interview,
  thankYouSent,
  other,
}
