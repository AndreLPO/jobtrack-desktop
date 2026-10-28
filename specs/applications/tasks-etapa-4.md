# Tasks — applications / Etapa 4

- [x] T1 — Domínio:
  - `Interaction.summary` opcional (D-53; formato continua na
    `schemaVersion` 1);
  - `validateInteraction` sem resumo obrigatório e com a próxima data
    hoje ou futura (D-54);
  - `Application.removeInteraction` (D-55).
- [x] T2 — `ApplicationDetailsController`: carregar (pronta, não
  encontrada, erro), alterar status, validar e registrar contato,
  excluir contato e excluir candidatura. O estado só muda depois de a
  gravação terminar.
- [x] T3 — Página de detalhes:
  - cabeçalho com Editar e Excluir;
  - badge e "Alterar status";
  - seções Resumo, Vaga (só campos preenchidos, link copiável,
    descrição recolhível), Contatos e Histórico, lado a lado a partir
    de 900px.
- [x] T4 — Diálogos "Alterar status" e "Registrar contato", e
  confirmação para excluir contato.
- [x] T5 — Rota `/applications/:id/details`. Clicar na linha abre os
  detalhes e o menu "⋮" edita ou exclui (D-51). Voltar recarrega a
  listagem.
- [x] T6 — Testes: domínio (`removeInteraction`, validação, mapper com
  resumo nulo), controller de detalhes e fluxos de widget (seções,
  status, contato, validação, excluir contato, excluir e editar com
  retorno).
- [x] T7 — Verificação em 2026-10-28:
  - `dart format .`: sem pendências.
  - `flutter analyze`: "No issues found!".
  - `flutter test`: 176 testes, "All tests passed!".
  - App reiniciado com `flutter run -d windows` para acompanhamento
    visual pelo usuário.

## Observações

- O link da vaga é copiado, não aberto: abrir no navegador exigiria o
  pacote `url_launcher`, que fica para quando você decidir.
- O texto de ajuda da próxima data no contato explica o efeito de
  D-21a: se ficar em branco, o prazo padrão passa a contar a partir
  desse contato.
