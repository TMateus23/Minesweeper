%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%COMANDOS DE INICALIZAÇÃO E PRINTS%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

:- dynamic(board/1).
%Inicializa o programa, chama o predicado minesweeper
:- initialization(minesweeper).

minesweeper :- 
    randomize,
    write('Minesweeper'), nl,
    loop.

% Loop principal
loop :-
    read_token(user_input, Token), %Lê o primeiro token da entrada
    process_token(Token), %Processa o token
    loop. %Continua o loop

%Processa um token único
process_token(end_of_file) :- !, halt. %Acaba quando for o fim do ficheiro
process_token(done) :- done.
process_token(dump) :- dump.
process_token(dump1) :- dump1.

process_token(empty) :-
    read_token(user_input, NumToken), %Lê o próximo token
    token_to_number(NumToken, N), %Converte o token para número
    integer(N), %Verifica se é inteiro
    empty(N).

process_token(randomMines) :- 
    read_token(user_input, NumToken), %Lê o próximo token como entrada do utilizador
    token_to_number(NumToken, K), %Converte o token para número
    integer(K), %Verifica se o valor é um número inteiro
    randomMines(K). %Chama o predicado randomMines com o número lido

process_token(mine) :- 
    read_token(user_input, RowToken), %Lê o próximo token como a linha
    read_token(user_input, ColToken), %Lê o token seguinte como a coluna
    token_to_number(RowToken, R), %Converte a linha para número
    token_to_number(ColToken, C), %Converte a coluna para número
    integer(R),integer(C), %Verifica se ambos os valores são inteiros
    mine(R,C). %Chama o predicado mine com as coordenadas lidas

process_token(step) :- 
    read_token(user_input, RowToken), %Lê o próximo token como a linha
    read_token(user_input, ColToken), %Lê o token seguinte como a coluna
    token_to_number(RowToken, R), %Converte a linha para número
    token_to_number(ColToken, C), %Converte a coluna para número
    integer(R),integer(C), %Verifica se ambos os valores são inteiros
    step(R,C). %Chama o predicado step com as coordenadas lidas

process_token(mark) :- 
    read_token(user_input, RowToken), %Lê o próximo token como a linha
    read_token(user_input, ColToken), %Lê o token seguinte como a coluna
    token_to_number(RowToken, R), %Converte a linha para número
    token_to_number(ColToken, C), %Converte a coluna para número
    integer(R),integer(C), %Verifica se ambos os valores são inteiros
    mark(R,C). %Chama o predicado mark com as coordenadas lidas

process_token(_) :- 
    write('Invalid'),nl. 

%Converte o token para número, se for preciso
token_to_number(Token, Number) :-
    number(Token), !, %O token já é um número
    Number = Token.
token_to_number(Token, Number) :-
    atom(Token), !, %O token é um átomo
    atom_codes(Token, Codes), %Converte o átomo em códigos ASCII
    number_codes(Number, Codes). %Converte os códigos para número
token_to_number(_, _) :-
    fail. %Caso contrário, falha


%Predicado para printar o tabuleiro
dump :-
    board(Board), %Vai buscar o tabuleiro atual
    write('Tabuleiro:'), nl,  
    maplist(print_dump_row, Board). %Imprime cada linha do tabuleiro

%Para imprimir cada linha do tabuleiro no formato do enunciado
print_dump_row(Row) :-
    write('('),
    print_row(Row), %Chama a função para imprimir a linha
    write(')'), nl.

%Imprime uma linha do tabuleiro, sem as minas
print_row([]). %Caso base
print_row([H|T]) :- 
    (H = 'M' -> write('-');   write(H)), %O objetivo é esconder as Minas para que o jogador não tenha acesso onde estão
    print_row(T). %Recursivamente para o resto da linha

%Este dump é para quando o jogador perde, aparece o tabuleiro com as minas para ele saber onde estava,
%foi esse o objetivo :)
dump1 :- 
    board(Board),
    write('Tabuleiro'), nl,
    maplist(print_dump_row1, Board).

print_dump_row1(Row) :-
    write('('),
    print_row1(Row), %Chama a função para imprimir a linha
    write(')'), nl.

print_row1([]). %Caso base
print_row1([H|T]) :- write(H), print_row1(T). %Recursivamente para o resto da linha

%Para quando pisamos uma mina, o jogo acaba
game_over :-
    write('Boom'), nl,
    dump1, %Mostra o tabuleiro com as minas
    halt. %Fecha o programa

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%PARA INICIALIZAR O TABULEIRO EMPTY%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Inicializa um tabuleiro NxN inicialmente vazio
empty(N) :-
    length(Row,N), %Cria uma linha com N elementos
    maplist(=('-'),Row), %Preenche a linha com espaços
    length(Board,N), %Cria a lista do tabuleiro com N linhas
    maplist(=(Row),Board), %Preenche o tabuleiro com N linhas iguais a Row
    assertz(board(Board)), %Guarda o tabuleiro na base de dados
    assertz(board_size(N)), %Guarda também o tamanho do tabuleiro
    write('ok'), nl.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%PARA AS MINAS ALEATÓRIAS NO TABULEIRO RANDOM%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Mete K minas de forma aleatória no tabuleiro e guarda o tabuleiro inicial
randomMines(K) :-
    board_size(N), %Carrega o tamanho do tabuleiro criado anteriormente
    TotalCells is N * N,
    MaxMines is TotalCells - 1, %O número máximo de minas que podemos ter
    K =< MaxMines, %Se K é maior que o máximo permitido não deixa adicionar minas
    K > 0, %Se o K for maior que 1, também não deixa adicionar
    count_mines(CurrentMines), %Conta as minas atuais
    NewTotal is CurrentMines + K, %Total após a soma
    NewTotal =< MaxMines, %Verifica se a nova soma ultrapassa o máximo, caso ultrapasse dá erro
    place_mines(K, 0, N), %Adiciona as minas
    board(Board), %Atualiza o tabuleiro
    retractall(initial_board(_)), %Remove o estado inicial anterior, se existir
    assertz(initial_board(Board)), %Guarda o estado inicial
    !, %este cut é para o programa não fazer: true ? 
    write('ok'), nl.

%Conta quantas minas estão atualmente no tabuleiro
count_mines(Count) :-
    board(Board), %Usa o tabuleiro atual
    findall((Row,Col), (nth0(Row,Board,R), nth0(Col,R,'M')),Mines), %Encontra todas as minas com o prefixo nth0
    length(Mines,Count). %Conta o número de minas que foram encontradas

%Adiciona K minas ao tabuleiro
place_mines(K,K,_) :- !. %Caso base: já adicionou todas as K minas
place_mines(K,Count,N) :- random_position(N,Row,Col), % Gera uma posição aleatória
    (\+ mineExist(Row,Col) -> %Verifica se não existe mina nessa posição
    place_mine(Row,Col), %Adiciona a mina diretamente na base de dados
    NewCount is Count + 1, %Incrementa o contador de minas
    place_mines(K,NewCount,N); %Continua a adicionar minas
    place_mines(K,Count,N)). %Tenta outra vez caso a posição já esteja ocupada

%Cria uma posição aleatória no tabuleiro
random_position(N,Row,Col) :-
    random(0,N,Row0), %Gera uma linha aleatória (0 a N-1)
    random(0,N,Col0), %Gera uma coluna aleatória (0 a N-1)
    Row is Row0 + 1, %Ajusta para 1-index
    Col is Col0 + 1. %Ajusta para 1-index
    %Estas duas últimas linhas foi porque estava a dar a posição (0,0) então foi necessário ajustar

%Verifica se há uma mina na posição especifica
mineExist(Row,Col) :-
    board(Board), % Recupera o tabuleiro atual
    Row0 is Row - 1, % Ajusta para 0-index
    Col0 is Col - 1, % Ajusta para 0-index
    nth0(Row0,Board,R), %Obtém a linha correspondente
    nth0(Col0,R,'M'). % Verifica se há uma mina ('M') nessa posição

%Adiciona uma mina ao tabuleiro e atualiza a base de dados
place_mine(Row,Col) :-
    board(Board), % Recupera o tabuleiro atual
    Row0 is Row - 1, %Ajusta para 0-index
    Col0 is Col - 1, %Ajusta para 0-index
    nth0(Row0,Board,OldRow), %Obtém a linha correspondente
    replace(OldRow,Col0,'M',NewRow), %Substitui o espaço por uma mina na linha
    replace(Board,Row0,NewRow,UpdatedBoard), %Atualiza a linha no tabuleiro
    retract(board(Board)), %Remove o antigo tabuleiro da base de dados
    assertz(board(UpdatedBoard)). %Atualiza o tabuleiro diretamente na base de dados

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%PARA AS MINAS NA POS ESPECÍFICA MINE%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Adiciona uma mina na posição específica
mine(R,C) :-
    board_size(N), %Vai buscar o tamanho do tabuleiro
    %Faz as verificações para que as coordenadas inseridas sejam válidas dentro dos limites do tabuleiro
    (R > 0, R =< N, C > 0, C =< N,
    count_mines(CurrentMines), %Conta as minas atuais no tabuleiro
    TotalCells is N * N,
        MaxMines is TotalCells - 1, %Calcula o máximo de minas permitidas
        (CurrentMines < MaxMines -> %Verifica se ainda há espaço para mais minas
                (\+ mineExist(R,C) -> %Verifica se não há mina nessa posição
                        place_mine(R,C), %Adiciona a mina
                        update_initial_board, %Atualiza o estado inicial
                        !, % cut novamente para evitar o true ? 
                        write('ok'), nl; 
                write('Already'), nl)); %Já tem uma mina na posição
    write('Invalid'), nl). %Fora to tabuleiro ou máximo atingido

%Atualiza o estado inicial do tabuleiro com o estado atual
update_initial_board :-
    board(Board), %Vai buscar o tabuleiro atual
    retractall(initial_board(_)), %Remove o estado inicial antigo
    assertz(initial_board(Board)). %Guarda o novo estado inicial

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%PARA PISAR AS CASAS NA POS ESPECÍFICA STEP%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

step(R,C) :-
    board_size(N), %Verifica o tamanho do tabuleiro
    (R > 0, R =< N, C > 0, C =< N,
    (mineExist(R,C) -> game_over; %Verifica se há uma mina nessa posição, caso exista, o jogo acaba
    count_and_update(R,C));
    write('Out'), nl). %Fora do tabuleiro

%Conta as minas vizinhas e atualiza a casa com o número
count_and_update(R,C) :-
    setof((Row,Col), neighbor(R,C,Row,Col),Neighbors), %Encontra vizinhos únicos
    count_mines_in_neighbors(Neighbors,Count), %Conta as minas nas vizinhanças
    update_board_with_count(R,C,Count), %Atualiza a casa no tabuleiro
    !, %novamente o cut para evitar true ?
    write('count '), write(Count), write(' mina(s).'), nl.

%Atualiza a posição (R, C) com o número de vizinhos
update_board_with_count(R,C,Count) :-
    board(Board), %Recupera o tabuleiro atual
    Row0 is R - 1, %Ajusta para 0-index
    Col0 is C - 1, %Ajusta para 0-index
    nth0(Row0,Board,OldRow), %Obtém a linha correspondente
    (Count = 0 -> NewValue = ' '; NewValue = Count), %Define o novo valor
    replace(OldRow,Col0,NewValue,NewRow), %Substitui o espaço pelo número de vizinhos
    replace(Board,Row0,NewRow,UpdatedBoard), %Atualiza a linha no tabuleiro
    retract(board(Board)), %Remove o tabuleiro antigo da base de dados
    assertz(board(UpdatedBoard)). %Atualiza o tabuleiro diretamente na base de dados

%Verifica se a posição (Row, Col) é um vizinho de (R, C)
neighbor(R, C, Row, Col) :- 
    DeltaRow = [-1, 0, 1],
    DeltaCol = [-1, 0, 1],
    member(Dr, DeltaRow),
    member(Dc, DeltaCol),
    (Dr \= 0 ; Dc \= 0), %Garante que não estamos a contar com a própria célula
    Row is R + Dr,
    Col is C + Dc,
    board_size(N),
    Row >= 1, Row =< N,
    Col >= 1, Col =< N.

%Conta as minas nas células vizinhas
count_mines_in_neighbors([], 0). %Caso Base
count_mines_in_neighbors([(Row, Col) | Rest], Count) :-
    (mineExist(Row, Col) -> 
        count_mines_in_neighbors(Rest, NewCount), %Conta as outras minas
        Count is NewCount + 1; %Incrementa o contador
        marked(Row, Col) -> %Verifica se a célula está marcada
            count_mines_in_neighbors(Rest, NewCount), %Conta as outras
            Count is NewCount + 1; %Se a célula marcada é uma mina, incrementa 
            count_mines_in_neighbors(Rest, Count)). %Se não for mina, continua

%Substitui um elemento na lista
replace([_|T],0,E,[E|T]). %Substitui o primeiro elemento
replace([H|T],N,E,[H|R]) :- 
    N > 0, N1 is N - 1, replace(T, N1, E, R).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%PARA MARCAR AS CASAS COM # NA POS ESPECÍFICA MARK%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Marca a posição (R, C), julga que tem uma mina
mark(R,C) :-
    board_size(N), %Vai buscar o tamanho do tabuleiro
    (R > 0, R =< N, C > 0, C =< N,
    (\+ marked(R,C) -> %Verifica se a posição não foi marcada anteriormente
            place_mark(R,C), %Marca a posição
            !, %cut novamente para evitar true ?
            write('ok'), nl;   
        write('Already'), nl); %Posição já marcada
    write('Out'), nl). %Fora do tabuleiro

%Adiciona uma marca ao tabuleiro e atualiza a base de dados
place_mark(Row,Col) :-
    board(Board), %Vai buscar o tabuleiro atual
    Row0 is Row - 1, %Ajusta para 0-index
    Col0 is Col - 1, %Ajusta para 0-index
    nth0(Row0,Board,OldRow), %Obtém a linha correspondente
    replace(OldRow,Col0,'#',NewRow), %Substitui o espaço pela marca ('#') na linha
    replace(Board,Row0,NewRow,UpdatedBoard), %Atualiza a linha no tabuleiro
    retract(board(Board)), %Remove o antigo tabuleiro da base de dados
    assertz(board(UpdatedBoard)). %Atualiza o tabuleiro diretamente na base de dados

%Verifica se a posição (R, C) já foi marcada
marked(R, C) :-
    board(Board), %Vai buscar o tabuleiro atual
    Row0 is R - 1, %Ajusta para 0-index
    Col0 is C - 1, %Ajusta para 0-index
    nth0(Row0,Board,Row), %Obtém a linha correspondente
    nth0(Col0,Row,'#'). %Verifica se a posição está marcada com '#'

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%PARA QUANDO SE ACHA QUE AS MINAS JA ESTAO TODAS MARCADA DONE%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Verifica se todas as minas foram marcadas corretamente e se não há marcas erradas
done :-
    board(Board), %Estado atual do tabuleiro
    initial_board(InitialBoard), %Estado inicial do tabuleiro (com as minas)
    validate_done(Board,InitialBoard), %Verifica se o tabuleiro atual está correto
    write('Winner'), nl,
    dump1, 
    halt.
done :-
    write('fail'), nl.

%Valida o tabuleiro atual contra o estado inicial
validate_done([],[]).
validate_done([CurrentRow|CurrentRest], [InitialRow|InitialRest]) :-
    validate_done_row(CurrentRow,InitialRow),
    validate_done(CurrentRest,InitialRest).

%Valida uma linha do tabuleiro
validate_done_row([],[]).
validate_done_row([CurrentCell|CurrentRest], [InitialCell|InitialRest]) :-
    (InitialCell = 'M' -> %Se era uma mina no tabuleiro inicial
    CurrentCell = '#'; %Deve estar marcada como mina no tabuleiro atual
    InitialCell \= 'M' -> %Se não era uma mina no tabuleiro inicial
    CurrentCell \= '#'), %Não deve estar marcada como mina no tabuleiro atual
    validate_done_row(CurrentRest,InitialRest).
