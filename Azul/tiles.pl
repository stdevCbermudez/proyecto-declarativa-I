% tile(color, cantidad_de_fichas).
% This format is solely for bag building process
:- (dynamic bag/1, center/1, factory/2).
:- [utils].

% Tile types and totals
% To play a different Azul modify this data XD (dev is no hold of any responsibility for problems occurred by doing so)
tile(rojo, 20).
tile(azul, 20).
tile(negro, 20).
tile(amarillo, 20).
tile(blanco, 20).

getTypes([rojo, azul, negro, amarillo, blanco]).

% Add tiles to the bag
addTileType(B, _, 0, B) :- !.
addTileType(B, T, C, [T|R]) :-
    C1 is C-1,
    addTileType(B, T, C1, R).

% Build bag in statement bagAzul this should only be done once per play
buildBagFrom(A, [], A) :- !.
buildBagFrom(A, [(T, C)|R], B) :-
    addTileType(A, T, C, R1), !,
    buildBagFrom(R1, R, B).
buildFirstBag(B) :-
    findall((T, C), tile(T, C), R),
    buildBagFrom([], R, B),
    assert(bag(B)).
buildBag(B) :-
    retract(bag(_)), !,
    buildFirstBag(B).

:- buildFirstBag(_). % Bag is build

% Remove random tile from bag
getTile(T) :-
    bag(B),
    length(B, L),
    L1 is L+1,
    random(1, L1, P),
    getIndex(P, B, T, BR),
    retract(bag(B)),
    assert(bag(BR)).

% Build a factory in factory(I, [ F1, F2, F3, F4]) of with less tiles.
buildFact(_, []) :-
    bag([]),
    !.
buildFact(FactId, Bag) :-
    bag(Bag),
    length(Bag, L),
    L < 4,
    L > 0,
    assert(factory(FactId, Bag)),
    retract(bag(Bag)),
    assert(bag([])),
    !.
buildFact(I, [F1, F2, F3, F4]) :-
    getTile(F1),
    getTile(F2),
    getTile(F3),
    getTile(F4),
    assert(factory(I, [F1, F2, F3, F4])),
    !.

% Build N factories
buildFacts(0) :- !.

buildFacts(N) :- N1 is N - 1, buildFacts(N1), buildFact(N, _), !.


% Build Center. It also serve as a center rebuild.
buildFirstCenter :- assert(center([especial])).

buildCenter :- retract(center(_)), buildFirstCenter().

addCenter(L) :- retract(center(A)), concatList(A,L,R), assert(center(R)).

% Build discarted tiles
buildFirstDiscarted :- assert(discarted([])).
buildDiscarted :- retract(discarted(_)), buildFirstDiscarted.

:- buildFirstCenter.
:- buildFirstDiscarted.

% Add discarted Tiles
discardTiles(ToDiscardTiles) :-
    retract(discarted(ActualDiscarted)),
    concatList(ActualDiscarted, ToDiscardTiles, NewDiscarted),
    assert(discarted(NewDiscarted)),
    !.

% Move and getMoves from factory
getMovesFactory(I, L) :- 
    factory(I, T), 
    reduce(T, L).

moveFactory(I, T, C) :- 
    factory(I, L), 
    reduce(L, R), 
    removeList((T, C), R, R1),  
    expand(R1, D), 
    addCenter(D), 
    retract(factory(I, _)), 
    !. 

% Print all Factories
print_factories :-
    findall(("Factoria #~a : [~a,~a,~a,~a].~n",[I,T1,T2,T3,T4]),factory(I,[T1,T2,T3,T4]), ToPrint),
    write_lines(ToPrint),
    !.

% Move and getMoves from center
getMovesCenter(R) :-
    center(L),
    not(member(especial, L)),
    reduce(L, R).
getMovesCenter(R) :- 
    center(L), 
    removeList(especial, L, R1), 
    reduce(R1, R).

checkEsp(L, si, NL) :- 
    member(especial, L), 
    removeList(especial, L, NL),
    !.

checkEsp(L, no, L) :- 
    not(member(especial, L)), 
    !.

moveCenter(T, C, F) :- 
    not(T=especial),
    center(L), 
    checkEsp(L, F, NL), 
    reduce(NL, R), 
    removeList((T, C), R, R1), 
    expand(R1, D), 
    retract(center(L)), 
    assert(center(D)), 
    !.

% Print Center
print_center :-
    center([]),
    format("Centro [].~n", _),
    !.
print_center :-
    center([First|Center]),
    format("Centro [~a", [First]),
    findall((",~a", [X]), member(X,Center), Elems),
    write_lines(Elems),
    format("].~n", _),
    !.

% Get moves from factories in format (I, T, C) where
% I is the factory number
% T is the tile type
% C is the number of tiles to get
getAllFactMoves(R) :-
    findall((I, T, C), (getMovesFactory(I, L), member((T, C), L)) , R1),
    flatten(R1, R),
    !.

% Get all posible moves if move is (T, C) is a center move otherwise is a factory move
getAllMoves(R) :-
    getMovesCenter(C),
    getAllFactMoves(F),
    concatList(C,F,R),
    !.

% Make a generic move X and F is `si` if X includes taking the special tile
moveTile((T, C), F) :-
    moveCenter(T, C, F),
    !.
moveTile((I, T, C), no) :-
    moveFactory(I, T, C),
    !.
