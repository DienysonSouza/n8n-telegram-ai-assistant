# Modulos

O repositorio instala dois workflows. Escolha um deles no primeiro acesso.

## AI Assistant Community

- gastos e faturas;
- orcamentos e relatorios;
- tarefas, prazos e recorrencias;
- notas e humor;
- lembretes e rotinas agendadas.

## AI Assistant Community Pro

Inclui as funcoes da versao comum e acrescenta:

- clientes e honorarios;
- processos e consulta ao DataJud;
- prazos juridicos;
- treinos e refeicoes.

Para consultas ao DataJud, preencha `CNJ_API_KEY` no `.env` antes de subir os
containers. Fitness nao exige servico externo.

## Regra de ativacao

Ative somente um workflow por token do Telegram. Os dois templates ja chegam
vinculados as credenciais criadas pelo bootstrap, mas permanecem desativados
ate o usuario escolher a edicao.

O schema completo e instalado nas duas edicoes. Tabelas nao utilizadas ficam
vazias e nao consomem recursos relevantes.
