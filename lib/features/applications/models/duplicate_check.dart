import 'application.dart';

/// Procura candidatura com a mesma empresa e vaga, sem diferenciar
/// maiúsculas, minúsculas e espaços nas pontas (RN-APP-11). Serve só
/// para avisar; salvar continua permitido (D-13).
///
/// [excludingId] evita que a própria candidatura seja apontada na edição.
Application? findPossibleDuplicate({
  required String companyName,
  required String jobTitle,
  required Iterable<Application> existing,
  String? excludingId,
}) {
  final company = _normalize(companyName);
  final job = _normalize(jobTitle);
  for (final application in existing) {
    if (application.id == excludingId) continue;
    if (_normalize(application.details.companyName) == company &&
        _normalize(application.details.jobTitle) == job) {
      return application;
    }
  }
  return null;
}

String _normalize(String value) => value.trim().toLowerCase();
