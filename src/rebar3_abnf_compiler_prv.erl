%%%
%%% Copyright 2020 RBKmoney
%%%
%%% Licensed under the Apache License, Version 2.0 (the "License");
%%% you may not use this file except in compliance with the License.
%%% You may obtain a copy of the License at
%%%
%%%     http://www.apache.org/licenses/LICENSE-2.0
%%%
%%% Unless required by applicable law or agreed to in writing, software
%%% distributed under the License is distributed on an "AS IS" BASIS,
%%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%%% See the License for the specific language governing permissions and
%%% limitations under the License.
%%%
-module(rebar3_abnf_compiler_prv).

-export([context/1]).
-export([needed_files/4]).
-export([dependencies/3]).
-export([compile/4]).
-export([clean/2]).

-behaviour(rebar_compiler).

-type extension() :: string().
-type out_mappings() :: [{extension(), file:filename()}].
-type rebar_dict() :: dict:dict().

-spec context(rebar_app_info:t()) ->
    #{
        src_dirs     => [file:dirname()],
        include_dirs => [file:dirname()],
        src_ext      => extension(),
        out_mappings => out_mappings()
    }.
context(AppInfo) ->
    Dir = rebar_app_info:dir(AppInfo),
    Mappings = [{".erl", filename:join([Dir, "src"])}],
    #{
        src_dirs => ["src"],
        include_dirs => [],
        src_ext => ".abnf",
        out_mappings => Mappings
    }.

-spec needed_files(digraph:graph(), [file:filename()], out_mappings(), rebar_app_info:t()) ->
    {{[file:filename()], term()}, % ErlFirstFiles (erl_opts global priority)
        {[file:filename()] | % [Sequential]
        {[file:filename()], [file:filename()]}, % {Sequential, Parallel}
            term()}}.
needed_files(_, FoundFiles, Mappings, AppInfo) ->
    FirstFiles = [],

    %% Remove first files from found files
    RestFiles = [Source || Source <- FoundFiles,
        not lists:member(Source, FirstFiles),
        rebar_compiler:needs_compile(Source, ".erl", Mappings)],

    Opts = rebar_opts:get(rebar_app_info:opts(AppInfo), abnf_opts, []),
    {{FirstFiles, Opts}, {RestFiles, Opts}}.

-spec dependencies(file:filename(), file:dirname(), [file:dirname()]) -> [file:filename()].
dependencies(_, _, _) ->
    [].

-spec compile(file:filename(), out_mappings(), rebar_dict(), list()) ->
    ok | {ok, [string()]} | {ok, [string()], [string()]}.
compile(Source, [{_, OutDir}], _, Opts) ->
    BaseName = filename:basename(Source, ".abnf"),
    FilteredOpts = filter_opts(Opts),
    AllOpts = [noobj, {mod, BaseName}, {o, OutDir} | FilteredOpts],
    case abnfc:file(Source, AllOpts) of
        ok ->
            ok;
        {ok, _AST, _Rest} ->
            ok;
        Error ->
            rebar_compiler:error_tuple(Source, [Error], [], AllOpts)
    end.

-spec clean([file:filename()], rebar_app_info:t()) -> _.
clean(AbnfFiles, _AppInfo) ->
    rebar_file_utils:delete_each(
        [rebar_utils:to_list(re:replace(F, "\\.abnf$", ".erl", [unicode]))
            || F <- AbnfFiles]).

filter_opts(Opts) ->
    lists:filter(
        fun (binary) -> true;
            (verbose) -> true;
            ({parser, abnfc_rfc4234}) -> true;
            ({parser, abnfc_rfc4234ext}) -> true;
            (_) -> false
        end,
        Opts
    ).
