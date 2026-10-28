# CLAUDE.md

Instruções operacionais para o Claude Code. O `PROJECT.md` é a fonte de
verdade sobre produto, arquitetura e restrições; este arquivo não o
repete, só define como trabalhar no repositório.

## Antes de qualquer alteração

1. Ler `PROJECT.md`, `specs/README.md` e a spec da feature afetada.
2. Consultar `specs/decisions.md`. Uma decisão com status **Pendente**
   não pode ser assumida: perguntar ao usuário ou registrar a dúvida.
3. Conferir em `specs/roadmap.md` em que etapa o projeto está. Não
   implementar etapas futuras nem itens fora do escopo aprovado.

## Fluxo SDD

- Nenhuma funcionalidade sem spec com status `Aprovada`.
- Antes de codar uma etapa: criar `specs/<feature>/plan.md` e
  `specs/<feature>/tasks.md` (ver `specs/README.md`) e pedir aprovação.
- Mudança de regra de negócio, de status/canais ou do schema Hive exige
  atualizar a spec **antes** do código.
- Ao concluir uma tarefa, marcar em `tasks.md` e reportar: arquivos
  alterados, testes executados com resultado real, decisões tomadas,
  limitações.

## Convenções de código

- Identificadores, arquivos e classes em inglês; textos da interface em
  português (pt-BR). Termos do domínio seguem a linguagem ubíqua do
  `PROJECT.md` (Application = Candidatura, FollowUp = Acompanhamento...).
- Controllers GetX são ViewModels: um por página, sufixo `Controller`.
- Regras de negócio (resposta recebida, elegibilidade de
  acompanhamento, semana atual) ficam em funções/classes puras do
  domínio, sem import de Flutter, GetX ou Hive.
- Views e controllers nunca importam Hive. Só a camada de dados importa.
- Data/hora "agora" deve ser injetável (ex.: `Clock`/função) para
  permitir testes de limites de semana, mês e ano.
- Valores visuais só via tokens em `lib/app/theme/`. Sem gradientes,
  sem sombras fortes (elevation 0 como padrão).
- Não criar pastas, camadas ou abstrações vazias "para o futuro".

## Dependências

- Não adicionar pacote sem justificar e sem verificar compatibilidade
  com o SDK local (`flutter --version`) via `flutter pub add` /
  `flutter pub get`. Registrar a escolha em `specs/decisions.md`.
- Proibido: pacotes de rede, backend, analytics ou integração com sites
  de vagas.

## Verificação obrigatória

```sh
dart format .
flutter analyze
flutter test
```

Nunca declarar testes como executados sem tê-los executado. Se algo
falhar e não for corrigido, reportar a saída.

## Dados locais

- Nunca alterar o formato persistido sem plano de migração na spec.
- Não apagar nem recriar boxes Hive do usuário para "corrigir" erros.
