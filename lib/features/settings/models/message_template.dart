import '../../../core/formatting/date_format.dart';
import '../../applications/models/application.dart';

/// Modelo de mensagem de acompanhamento (D-27, D-50). O app só gera o
/// texto para o usuário copiar; nada é enviado.
abstract final class MessageTemplate {
  /// Usado quando a candidatura não tem contato informado (D-59).
  static const fallbackContact = 'equipe de recrutamento';

  static const variables = {
    '{empresa}': 'Nome da empresa',
    '{vaga}': 'Título da vaga',
    '{data}': 'Data da candidatura (dd/mm/aaaa)',
    '{contato}': 'Contato da candidatura, ou "$fallbackContact"',
  };

  static const defaultText =
      'Olá, {contato}! Tudo bem?\n'
      '\n'
      'Candidatei-me à vaga de {vaga} na {empresa} em {data}. Tenho '
      '[X anos] de experiência com [stack ou produto relevante], incluindo '
      '[uma conquista com número].\n'
      '\n'
      'Tenho muito interesse na {empresa} e gostaria de saber sobre os '
      'próximos passos do processo.\n'
      '\n'
      'Obrigado pela atenção!\n'
      '[Seu nome] | [LinkedIn]';

  static bool isValid(String text) => text.trim().isNotEmpty;

  static String render(String template, Application application) {
    final d = application.details;
    return template
        .replaceAll('{empresa}', d.companyName)
        .replaceAll('{vaga}', d.jobTitle)
        .replaceAll('{data}', formatDate(d.applicationDate))
        .replaceAll('{contato}', d.contactName ?? fallbackContact);
  }
}
