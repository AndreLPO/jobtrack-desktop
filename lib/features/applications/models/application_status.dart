/// Status da candidatura (D-10). A classificação fica centralizada aqui
/// e não deve ser repetida nas telas (RN-04).
enum ApplicationStatus {
  applied(isActive: true, indicatesResponse: false),
  responseReceived(isActive: true, indicatesResponse: true),
  interview(isActive: true, indicatesResponse: true),
  technicalTest(isActive: true, indicatesResponse: true),
  offerReceived(isActive: true, indicatesResponse: true),
  rejected(isActive: false, indicatesResponse: true),
  withdrawn(isActive: false, indicatesResponse: false),
  closedWithoutResponse(isActive: false, indicatesResponse: false);

  const ApplicationStatus({
    required this.isActive,
    required this.indicatesResponse,
  });

  /// Processo em andamento. Os demais status são encerrados.
  final bool isActive;

  /// O status por si só indica que a empresa deu retorno (D-11).
  final bool indicatesResponse;

  bool get isClosed => !isActive;
}
