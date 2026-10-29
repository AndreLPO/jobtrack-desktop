# JobTrack Desktop

Monitor local de candidaturas a vagas de emprego para Windows. Os dados
ficam só no seu computador: não há conta, backend nem integração com
sites de vagas.

- **Candidaturas:** cadastro, edição, busca, filtros, histórico de
  status e contatos.
- **Acompanhamentos:** o que está vencido, o que já pode ser encerrado,
  e a ação de adiar.
- **Mensagem de acompanhamento:** um modelo editável para copiar. Nada é
  enviado pelo app.
- **Quadro:** as candidaturas em colunas por status, para mover
  arrastando.
- **Dashboard:** candidaturas da semana, respostas e pendências.

Produto, regras e decisões: [`PROJECT.md`](PROJECT.md) e
[`specs/`](specs/README.md). Instruções para o Claude Code:
[`CLAUDE.md`](CLAUDE.md).

## Baixar

**[⬇ JobTrack para Windows (x64)](https://github.com/AndreLPO/jobtrack-desktop/releases/latest/download/JobTrack-windows-x64.zip)**.
As versões anteriores estão em [Releases](https://github.com/AndreLPO/jobtrack-desktop/releases).

1. Extraia o `.zip` em uma pasta, por exemplo
   `%LOCALAPPDATA%\Programs\JobTrack`.
2. Execute `jobtrack_desktop.exe`. Se quiser, crie um atalho para ele
   na área de trabalho.

O executável não é assinado, então o Windows SmartScreen pode avisar
na primeira execução. Para abrir mesmo assim, clique em **Mais
informações → Executar assim mesmo**. Se aparecer um erro de DLL
ausente (`MSVCP140.dll` ou `VCRUNTIME140.dll`), instale o
[Visual C++ Redistributable x64](https://aka.ms/vs/17/release/vc_redist.x64.exe)
da Microsoft.

Requer Windows 10 ou superior.

## Requisitos

- Flutter 3.47 / Dart 3.13 (verificado com Flutter 3.47.7).
- Windows 10 ou superior, com o Visual Studio 2022 ("Desktop development
  with C++") para compilar.

## Rodar e testar

```sh
flutter pub get
flutter run -d windows        # executa em modo debug
flutter test                  # testes de unidade, repositório, controllers e widgets
flutter analyze
dart format .
flutter build windows         # gera build\windows\x64\runner\Release
```

## Onde ficam os dados

```text
%APPDATA%\com.andre\jobtrack_desktop\data
```

O caminho exato também aparece em **Configurações → Dados locais**.
Para ter uma cópia de segurança, copie essa pasta com o aplicativo
fechado. Para restaurar, coloque a cópia de volta no mesmo lugar,
também com o aplicativo fechado.

## Estrutura

```text
lib/
├── app/          # app, rotas, bindings, tema (tokens) e shell de navegação
├── core/         # banco (Hive), datas, erros, formatação, widgets compartilhados
└── features/
    ├── applications/  # modelos e regras do domínio, repositório, listagem, formulário e detalhes
    ├── follow_ups/    # página de Acompanhamentos
    ├── dashboard/     # indicadores
    └── settings/      # prazo, limite de tentativas e modelo de mensagem
```

As regras de negócio (resposta, acompanhamento, semana e métricas)
ficam em `features/*/models`, como código Dart puro e testado. Cada
página tem o próprio controller GetX, que funciona como ViewModel, e só
os repositórios conhecem o Hive.
