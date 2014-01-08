%%%-------------------------------------------------------------------
%%% File    : pdag.erl
%%% Author  : Robert Dionne
%%%
%%% pdag is a simple persistent directed acyclic graph
%%%
%%% pdag is free software: you can redistribute it and/or modify
%%% it under the terms of the GNU General Public License as published by
%%% the Free Software Foundation, either version 3 of the License, or
%%% (at your option) any later version.
%%%
%%% pdag is distributed in the hope that it will be useful,
%%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%%% GNU General Public License for more details.
%%%
%%% You should have received a copy of the GNU General Public License
%%% along with Bitstore.  If not, see <http://www.gnu.org/licenses/>.
%%%
%%% Created :  07 Jan 2014 by Robert Dionne <dionne@dionne-associates.com>
%%%
%%% pdag, Copyright (C) 2014   Dionne Associates, LLC.
%%%-------------------------------------------------------------------
-module(pdag).
-author('dionne@dionne-associates.com').
%%
%%
%% {Links, References}
%%
%% where Links = [{arr1,[target_node_ids]}]
%% and references = [{arr1,[source_node_ids]}]
%%
%% API
-export([create_or_open_dag/2,
         add_edge/2,
         remove_edge/2,
         get_targets/2, get_targets/3,
         get_sources/2, get_sources/3,
         get_roots/2,
         path_exists/2,
         close_dag/1]).
%%
-include("pdag.hrl").
-import(bitcask, [open/2,get/2,put/3,fold/3,close/1]).

%%
create_or_open_dag(DbName, Refresh) ->
    case filelib:is_dir(DbName) of
    true ->
        case Refresh of
        true ->
            ?LOG(?DEBUG, "removing dag store for ~p ~n",[DbName]),
            os:cmd("rm -rf " ++ DbName);
        false ->
            ok
        end;
    false ->
        ok
    end,
    open(DbName, [read_write, {max_file_size, 100000000}]).
%%
%%
close_dag(Dag) ->
    close(Dag).
%%
%%
add_edge({Source, Arrow, Target},Dag) ->
    SourceNode = find_or_create_node(Source,Dag),
    TargetNode = find_or_create_node(Target,Dag),
    NewLinks = add_edge(Arrow,Target,get_targets(SourceNode)),
    NewRefs = add_edge(Arrow,Source,get_sources(TargetNode)),
    store_node(Source,{NewLinks,get_sources(SourceNode)},Dag),
    store_node(Target,{get_targets(TargetNode),NewRefs},Dag).
%%
%%
remove_edge({Source, Arrow, Target},Dag) ->
    SourceNode = find_or_create_node(Source,Dag),
    TargetNode = find_or_create_node(Target,Dag),
    NewLinks = remove_edge(Arrow,Target,get_targets(SourceNode)),
    NewRefs = remove_edge(Arrow,Source,get_sources(TargetNode)),
    store_node(Source,{NewLinks,get_sources(SourceNode)},Dag),
    store_node(Target,{get_targets(TargetNode),NewRefs},Dag).
%%
%%
get_targets(Source, Arrow, Dag) ->
    get_edge_targets(Source, Arrow, Dag, fun get_targets/1).

%%
get_sources(Target, Arrow, Dag) ->
    get_edge_targets(Target, Arrow, Dag, fun get_sources/1).
%%
get_edge_targets(Source, Arrow, Dag, Fun) ->
    case get_node(Source,Dag) of
    [] -> [];
    SourceNode ->
        Edges = proplists:lookup(Arrow, Fun(SourceNode)),
        case Edges of
        none ->
            [];
        {Arrow, Targets} -> Targets
        end
    end.
%%
get_targets(Source, Dag) ->
    get_edge_targets(Source, Dag, fun get_targets/1).

%%
get_sources(Target, Dag) ->
    get_edge_targets(Target, Dag, fun get_sources/1).

get_edge_targets(Source, Dag, Fun) ->
    case get_node(Source,Dag) of
    [] ->
        [];
    SourceNode ->
        Fun(SourceNode)
    end.
%%
%%
%%
get_roots(Arrow,Dag) ->
    fold(
      Dag,
      fun(K,V,Acc) ->
          Node = binary_to_term(V),
          Edges = proplists:lookup(Arrow,get_targets(Node)),
          case Edges of
          none ->
              InEdges = proplists:lookup(Arrow,get_sources(Node)),
              case InEdges of
              none -> Acc;
              _ -> Acc ++ [K]
              end;
          _ -> Acc
          end
      end,[]).
%%
path_exists({_Source,_Arrow,_Target},_Dag) ->
    ok.
%%
%% internal private functions
store_node(NodeId,Node,Dag) ->
    put(Dag,NodeId,term_to_binary(Node)).
%%
%%
get_targets({OutEdges, _InEdges}) ->
    OutEdges.
%%
%%
get_sources({_OutEdges, InEdges}) ->
    InEdges.
%%
%%
%%
get_node(NodeId, Dag) ->
    case get(Dag, NodeId) of
    not_found ->
        %% return empty if node doesn't exist, saves call
        [];
    {ok, Node} -> binary_to_term(Node)
    end.
%%
%%
find_or_create_node(NodeId,Dag) ->
    case get_node(NodeId, Dag) of
    [] ->
        NewNode = {[],[]},
        store_node(NodeId,NewNode,Dag),
        NewNode;
    Node -> Node
    end.
%%
%%
add_edge(EdgeId,NodeId,Edges) ->
    case proplists:lookup(EdgeId,Edges) of
    none ->
        lists:append([{EdgeId,[NodeId]}], Edges);
    {EdgeId, NodeList} ->
        case lists:member(NodeId,NodeList) of
        true ->
            Edges;
        _ ->
            NewEdges = proplists:delete(EdgeId,Edges),
            lists:append(NewEdges,[{EdgeId,lists:append(NodeList,[NodeId])}])
        end
    end.
%%
%%
remove_edge(EdgeId,NodeId,Edges) ->
    case proplists:lookup(EdgeId,Edges) of
    none ->
        Edges;
    {EdgeId, NodeList} ->
        NewEdges = proplists:delete(EdgeId,Edges),
        case length(NodeList) of
        1 ->
            NewEdges;
        _ ->
            lists:append(NewEdges,
                         [{EdgeId,lists:delete(NodeId,NodeList)}])
        end
    end.
