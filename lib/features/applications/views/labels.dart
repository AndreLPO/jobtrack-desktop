import '../models/application_channel.dart';
import '../models/application_details.dart';
import '../models/application_status.dart';
import '../models/application_validation.dart';
import '../models/work_mode.dart';

/// Textos em pt-BR dos códigos do domínio (D-06, D-47).
extension ApplicationStatusLabel on ApplicationStatus {
  String get label => switch (this) {
    ApplicationStatus.applied => 'Aplicada',
    ApplicationStatus.responseReceived => 'Resposta recebida',
    ApplicationStatus.interview => 'Entrevista',
    ApplicationStatus.technicalTest => 'Teste técnico',
    ApplicationStatus.offerReceived => 'Proposta recebida',
    ApplicationStatus.rejected => 'Reprovada',
    ApplicationStatus.withdrawn => 'Desisti',
    ApplicationStatus.closedWithoutResponse => 'Encerrada sem resposta',
  };
}

extension ApplicationChannelLabel on ApplicationChannel {
  String get label => switch (this) {
    ApplicationChannel.linkedIn => 'LinkedIn',
    ApplicationChannel.gupy => 'Gupy',
    ApplicationChannel.companyWebsite => 'Site da empresa',
    ApplicationChannel.email => 'E-mail',
    ApplicationChannel.referral => 'Indicação',
    ApplicationChannel.other => 'Outro',
  };
}

extension WorkModeLabel on WorkMode {
  String get label => switch (this) {
    WorkMode.onSite => 'Presencial',
    WorkMode.hybrid => 'Híbrido',
    WorkMode.remote => 'Remoto',
  };
}

/// Canal para exibição; em "Outro", mostra a descrição informada.
String channelDisplay(ApplicationDetails details) =>
    details.channel == ApplicationChannel.other && details.channelOther != null
    ? details.channelOther!
    : details.channel.label;

extension ValidationCodeMessage on ValidationCode {
  String get message => switch (this) {
    ValidationCode.required => 'Campo obrigatório.',
    ValidationCode.futureDate => 'A data não pode ser futura.',
    ValidationCode.invalidUrl =>
      'Informe um endereço começando com http:// ou https://.',
    ValidationCode.pastDate => 'Escolha hoje ou uma data futura.',
  };
}
