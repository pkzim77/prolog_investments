:- use_module(library(csv)).
:- dynamic acao/13.

carregar_csv :-
    (   exists_file('acoes.csv')
    ->  csv_read_file(
            'acoes.csv',
            Linhas,
            [functor(linha), separator(44)]
        ),
        maplist(assert_acao, Linhas),
        writeln('CSV carregado com sucesso!')
    ;   writeln('ERRO: Arquivo acoes.csv nao encontrado!'),
        writeln('Por favor, coloque o arquivo CSV no diretorio:'),
        working_directory(Dir, Dir),
        format('~w~n', [Dir]),
        fail
    ).

assert_acao(linha(Papel, Cotacao, Empresa, Setor, Subsetor, ValorMercado, 
DivYield, ROE, DivPorPatrim, MargLiquida, RentabilidadeDozeMeses, P_L, CresRec5a)) :- 
    assertz(acao(Papel, Cotacao, Empresa, Setor, Subsetor, ValorMercado, 
                 DivYield, ROE, DivPorPatrim, MargLiquida, RentabilidadeDozeMeses, P_L, CresRec5a)).

limpar_acoes :-
    retractall(acao(_,_,_,_,_,_,_,_,_,_,_,_,_)).

% =========================================
% Sistema Especialista de Investimentos
% Analise Fundamentalista
% =========================================

% -----------------------------------------
% Perfis de investidor
% -----------------------------------------

perfil(1, tipo1).  
perfil(2, tipo2).  

% -----------------------------------------
% Pontuacao por PL Modelo de Qualidade (Quality Investing)
% -----------------------------------------

pl_score(PL, 5) :- PL =< 15, !.
pl_score(PL, 2.5) :- PL > 15, PL =< 25, !.
pl_score(_, 0).

% -----------------------------------------
% Pontuacao por PL versao Benjamin Graham (Value Investing) 
% -----------------------------------------

pl_score2(PL, 30) :- PL =< 10, !.
pl_score2(PL, 20) :- PL > 10, PL =< 15, !.
pl_score2(PL, 10) :- PL > 15, PL =< 20, !.
pl_score2(_, 0).

% -----------------------------------------
% Pontuacao por ROE Modelo de Qualidade (Quality Investing)
% -----------------------------------------

roe_score(ROE, 30) :-  ROE >= 20, !.
roe_score(ROE, 20) :- ROE >= 15, ROE < 20, !.
roe_score(ROE, 10) :- ROE >= 10, ROE < 15, !.
roe_score(_, 0).

% -----------------------------------------
% Pontuacao por ROE versao Benjamin Graham (Value Investing) 
% -----------------------------------------

roe_score2(ROE, 15) :-  ROE >= 15, !.
roe_score2(ROE, 7) :- ROE >= 10, ROE < 15, !.
roe_score2(_, 0).

% -----------------------------------------
% Pontuacao por Dividend Yield
% -----------------------------------------

div_score(DivYield, 20) :- DivYield >= 6, !.
div_score(DivYield, 14) :- DivYield >= 4, DivYield < 6, !.
div_score(DivYield, 7) :- DivYield >= 2, DivYield < 4, !.
div_score(_, 0).

% -----------------------------------------
% Pontuacao por Endividamento Modelo de Qualidade (Quality Investing)
% -----------------------------------------

divida_score(DivPorPatrim, 15) :- DivPorPatrim =< 0.5, !.
divida_score(DivPorPatrim, 10) :- DivPorPatrim =< 1, !.
divida_score(DivPorPatrim, 5) :- DivPorPatrim =< 2, !.
divida_score(_, 0).

% -----------------------------------------
% Pontuacao por Endividamento versao Benjamin Graham (Value Investing) 
% -----------------------------------------

divida_score2(DivPorPatrim, 25) :- DivPorPatrim =< 0.5, !.
divida_score2(DivPorPatrim, 16) :- DivPorPatrim =< 1, !.
divida_score2(DivPorPatrim, 8) :- DivPorPatrim =< 2, !.
divida_score2(_, 0).

% -----------------------------------------
% Pontuacao por Margem Liquida Modelo de Qualidade (Quality Investing)
% -----------------------------------------

margemLiq_score(MargLiquida, 25) :- MargLiquida >= 20, !.
margemLiq_score(MargLiquida, 16) :- MargLiquida >= 15,  MargLiquida < 20, !.
margemLiq_score(MargLiquida, 8) :- MargLiquida >= 10,  MargLiquida < 15, !.
margemLiq_score(_, 0).

% -----------------------------------------
% Pontuacao por Margem Liquida versao Benjamin Graham (Value Investing) 
% -----------------------------------------

margemLiq_score2(MargLiquida, 10) :- MargLiquida >= 15, !.
margemLiq_score2(MargLiquida, 5) :- MargLiquida >= 10,  MargLiquida < 15, !.
margemLiq_score2(_, 0).

% -----------------------------------------
% Pontuacao por Crescimento de receita em 5 anos
% -----------------------------------------

cres_Rec_5a_score(CresRec5a, 25) :- CresRec5a >= 10, !.
cres_Rec_5a_score(CresRec5a, 16) :- CresRec5a >= 7, CresRec5a < 10, !.
cres_Rec_5a_score(CresRec5a, 8) :- CresRec5a >= 5, CresRec5a < 7, !.
cres_Rec_5a_score(_, 0).


% =====================================================
% PONTUACAO DIFERENTE PARA CADA PERFIL (PARTE PRINCIPAL)
% =====================================================

% -------- PERFIL TIPO 1 --------
% Foco: ROE alto, divida controlada e ação em queda de maximo 5%
pontuacao(Papel, tipo1, Total) :-
    acao(Papel, _, _, _, _, _, _, ROE, DivPorPatrim, MargLiquida, _, P_L, CresRec5a),
    roe_score(ROE, P1),
    divida_score(DivPorPatrim, P2),
    margemLiq_score(MargLiquida, P3),
    cres_Rec_5a_score(CresRec5a, P4),
    pl_score(P_L, P5),
    Total is P1 + P2 + P3 + P4 + P5.

% -------- PERFIL Tipo 2 --------
% Foco: Dividendos + seguranca
pontuacao(Papel, tipo2, Total) :-
    acao(Papel, _, _, _, _, _, DivYield, ROE, DivPorPatrim, MargLiquida, _, P_L, _),
    div_score(DivYield, P1),
    pl_score2(P_L, P2),
    divida_score2(DivPorPatrim, P3),
    margemLiq_score2(MargLiquida, P4),
    roe_score2(ROE, P5),
    Total is P1 + P2 + P3 + P4 + P5.

% -----------------------------------------
% Ranking de acoes
% -----------------------------------------

ranking(Perfil, ListaOrdenada) :-
    findall(
        Pontos-Acao,
        pontuacao(Acao, Perfil, Pontos),
        Lista
    ),
    sort(Lista, ListaOrdenada).

% -----------------------------------------
% Melhor acao
% -----------------------------------------

melhor_acao(Perfil, Acao, Pontos) :-
    ranking(Perfil, Lista),
    last(Lista, Pontos-Acao).

% -----------------------------------------
% Top N acoes
% -----------------------------------------

top_acoes(Perfil, N, TopN) :-
    ranking(Perfil, Lista),
    reverse(Lista, ListaDesc),
    length(Prefix, N),
    append(Prefix, _, ListaDesc),
    TopN = Prefix.

top_acoes(Perfil, N, Lista) :-
    ranking(Perfil, ListaCompleta),
    reverse(ListaCompleta, ListaDesc),
    length(ListaDesc, Len),
    Len < N,
    Lista = ListaDesc.

% -----------------------------------------
% Explicacao detalhada
% -----------------------------------------

explicar(Papel) :-
    acao(Papel, Cotacao, Empresa, Setor, Subsetor, _ValorMercado,
         DivYield, ROE, DivPorPatrim, MargLiquida, RentabilidadeDozeMeses, P_L, CresRec5a),
    nl,
    format('Empresa: ~w~n', [Empresa]),
    format('Setor: ~w / ~w~n', [Setor, Subsetor]),
    format('Cotacao: ~2f~n', [Cotacao]),
    format('P/L: ~2f~n', [P_L]),
    format('ROE: ~2f%~n', [ROE]),
    format('Dividend Yield: ~2f%~n', [DivYield]),
    format('Divida/Patrimonio: ~2f~n', [DivPorPatrim]),
    format('Margem Liquida: ~2f%~n', [MargLiquida]),
    format('Crescimentod e receita nos ultimos 5 anos: ~2f%~n', [CresRec5a]),
    format('Variacao 12 meses: ~2f%~n', [RentabilidadeDozeMeses]).

% -----------------------------------------
% Mostrar top N
% -----------------------------------------

mostrar_top([], _).
mostrar_top([Pontos-Acao|Resto], N) :-
    format('~w. ~w (Pontuacao: ~w)~n', [N, Acao, Pontos]),
    explicar(Acao),
    nl,
    N1 is N + 1,
    mostrar_top(Resto, N1).

% -----------------------------------------
% Menu
% -----------------------------------------

menu :-
    limpar_acoes,
    nl,
    writeln('===================================='),
    writeln(' Sistema Especialista de Investimentos'),
    writeln('===================================='),
    (   carregar_csv
    ->  nl,
        writeln('Escolha seu perfil:'),
        writeln('1 - Modelo de Qualidade (Quality Investing)'),
        writeln('2 - Método de Benjamin Graham (Value Investing)'),
        write('Opcao: '),
        read(Op),
        executar(Op)
    ;   writeln('Sistema nao pode iniciar sem o arquivo CSV.'),
        writeln('Encerrando...')
    ).

executar(Op) :-
    perfil(Op, Perfil),
    nl,
    writeln('Deseja ver:'),
    writeln('1 - Apenas a melhor acao'),
    writeln('2 - Top 5 acoes'),
    writeln('3 - Top 10 acoes'),
    write('Opcao: '),
    read(OpVis),
    mostrar_resultado(Perfil, OpVis),
    repetir.

executar(_) :-
    writeln('Opcao invalida.'),
    menu.

mostrar_resultado(Perfil, 1) :-
    melhor_acao(Perfil, Acao, Pontos),
    nl,
    format('>>> Melhor acao recomendada: ~w~n', [Acao]),
    format('>>> Pontuacao total: ~w~n', [Pontos]),
    explicar(Acao).

mostrar_resultado(Perfil, 2) :-
    top_acoes(Perfil, 5, Top),
    nl,
    writeln('>>> TOP 5 ACOES RECOMENDADAS:'),
    writeln('===================================='),
    mostrar_top(Top, 1).

mostrar_resultado(Perfil, 3) :-
    top_acoes(Perfil, 10, Top),
    nl,
    writeln('>>> TOP 10 ACOES RECOMENDADAS:'),
    writeln('===================================='),
    mostrar_top(Top, 1).

mostrar_resultado(_, _) :-
    writeln('Opcao invalida de visualizacao.').

% -----------------------------------------
% Repetir
% -----------------------------------------

repetir :-
    nl,
    writeln('Deseja fazer outra consulta? (s/n)'),
    read(R),
    ( R == s -> menu ; writeln('Sistema encerrado.') ).

% -----------------------------------------
% Inicializacao
% -----------------------------------------

:- initialization(menu).

iniciar :- menu.