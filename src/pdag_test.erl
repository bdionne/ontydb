-module(pdag_test).

-include_lib("eunit/include/eunit.hrl").

-import(pdag, [create_or_open_dag/2,
         add_edge/2,
         remove_edge/2,
         get_targets/3,
         get_sources/3,
         get_targets/2,
         get_sources/2,
         get_roots/2,
         path_exists/2,
         close_dag/1]).

add_edge_test() ->
    Dag = create_or_open_dag("onty",true),
    add_edge({<<"001">>,<<"002">>,<<"003">>},Dag),
    ?assert(length(get_targets(<<"001">>,Dag)) == 1),
    close_dag(Dag).


remove_edge_test() ->
    Dag = create_or_open_dag("onty",true),
    add_edge({<<"001">>,<<"002">>,<<"003">>},Dag),
    ?assert(length(get_targets(<<"001">>,Dag)) == 1),
    remove_edge({<<"001">>,<<"002">>,<<"003">>},Dag),
    ?assert(length(get_targets(<<"001">>,Dag)) == 0),
    close_dag(Dag).
%%
get_edge_targets_test() ->
    Dag = create_or_open_dag("onty",true),
    add_edge({<<"001">>,<<"002">>,<<"003">>},Dag),
    ?assert(length(get_targets(<<"001">>,Dag)) == 1),
    ?assert(length(get_targets(<<"001">>,<<"002">>,Dag)) == 1),
    [<<"003">>] = get_targets(<<"001">>,<<"002">>,Dag),
    close_dag(Dag).
%%
get_edge_sources_test() ->
    Dag = create_or_open_dag("onty",true),
    add_edge({<<"001">>,<<"002">>,<<"003">>},Dag),
    ?assert(length(get_sources(<<"003">>,Dag)) == 1),
    ?assert(length(get_sources(<<"003">>,<<"002">>,Dag)) == 1),
    [<<"001">>] = get_sources(<<"003">>,<<"002">>,Dag),
    close_dag(Dag).
%%
get_targets_test() ->
    Dag = create_or_open_dag("onty",true),
    add_edge({<<"001">>,<<"002">>,<<"003">>},Dag),
    ?assert(length(get_targets(<<"001">>,Dag)) == 1),
    [{<<"002">>,[<<"003">>]}] = get_targets(<<"001">>,Dag),
    close_dag(Dag).
%%
get_sources_test() ->
    Dag = create_or_open_dag("onty",true),
    add_edge({<<"001">>,<<"002">>,<<"003">>},Dag),
    ?assert(length(get_sources(<<"003">>,Dag)) == 1),
    [{<<"002">>,[<<"001">>]}] = get_sources(<<"003">>,Dag),
    close_dag(Dag).
%%
get_roots_test() ->
    Dag = create_or_open_dag("onty",true),
    add_edge({<<"001">>,<<"002">>,<<"003">>},Dag),
    ?assert(length(get_roots(<<"002">>,Dag)) == 1),
    [<<"003">>] = get_roots(<<"002">>,Dag),
    close_dag(Dag).
%%
get_multiple_roots_test() ->
    Dag = create_or_open_dag("onty",true),
    add_edge({<<"001">>,<<"002">>,<<"003">>},Dag),
    add_edge({<<"004">>,<<"002">>,<<"001">>},Dag),
    add_edge({<<"001">>,<<"002">>,<<"005">>},Dag),
    ?assert(length(get_roots(<<"002">>,Dag)) == 2),
    Roots = get_roots(<<"002">>,Dag),
    ?assert(lists:member(<<"003">>,Roots)),
    ?assert(lists:member(<<"005">>,Roots)),
    close_dag(Dag).
%%
