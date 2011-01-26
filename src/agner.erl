-module(agner).
-include_lib("agner.hrl").
-export([start/0,stop/0]).
-export([main/1]).
%% API
-export([spec/1, spec/2, index/0, fetch/2, fetch/3, versions/1]).

start() ->
	inets:start(),
	ssl:start(),
	{ok, _Pid} = inets:start(httpc,[{profile, agner}]),
	application:start(agner).

stop() ->
    error_logger:delete_report_handler(error_logger_tty_h),
	application:stop(agner),
	inets:stop(),
	ssl:stop().

main(["spec"|Args]) ->
    OptSpec = [
               {package, undefined, undefined, string, "Package name"},
               {version, $v, "version", {string, "@master"}, "Version"}
              ],
	start(),
    {ok, {Opts, _}} = getopt:parse(OptSpec, Args),
    case proplists:get_value(package, Opts) of
        undefined ->
            io:format("ERROR: Package name required.~n");
        Package ->
            io:format("~p~n",[spec(Package,proplists:get_value(version, Opts))])
    end,
	stop();

main(["versions"|Args]) ->
    OptSpec = [
               {package, undefined, undefined, string, "Package name"}
              ],
	start(),
    {ok, {Opts, _}} = getopt:parse(OptSpec, Args),
    case proplists:get_value(package, Opts) of
        undefined ->
            io:format("ERROR: Package name required.~n");
        Package ->
            io:format("~s",[lists:map(fun (Version) ->
                                              io_lib:format("~s~n",[agner_spec:version_to_list(Version)])
                                      end,
                                      versions(Package))])
    end,
	stop();

main(["list"|Args]) ->
    OptSpec = [
              ],
	start(),
    {ok, {_Opts, _}} = getopt:parse(OptSpec, Args),
    io:format("~s",[lists:map(fun (Name) ->
                                        io_lib:format("~s~n",[Name])
                                end,index())
                     ]),
	stop();

main(["fetch"|Args]) ->
    OptSpec = [
               {package, undefined, undefined, string, "Package name"},
               {directory, undefined, undefined, string, "Directory to check package out to"},
               {version, $v, "version", {string, "@master"}, "Version"}
              ],
	start(),
    {ok, {Opts, _}} = getopt:parse(OptSpec, Args),
    case proplists:get_value(package, Opts) of
        undefined ->
            io:format("ERROR: Package name required.~n");
        Package ->
            io:format("~p~n",[fetch(Package,proplists:get_value(version, Opts),
                                    proplists:get_value(directory, Opts, Package))])
    end,
	stop();

main(_) ->
    OptSpec = [
               {command, undefined, undefined, string, "Command to be executed (e.g. spec)"}
               ],
    getopt:usage(OptSpec, "agner", "[options ...]").


%%%===================================================================
%%% API
%%%===================================================================
-spec spec(agner_spec_name()) -> agner_spec() | not_found_error().
-spec spec(agner_spec_name(), agner_spec_version() | string()) -> agner_spec() | not_found_error().

spec(Name) ->
	spec(Name, {branch, "master"}).

spec(Name, Version) when is_list(Version) ->
    spec(Name, agner_spec:list_to_version(Version));

spec(Name, Version) when is_atom(Name) ->
	spec(atom_to_list(Name),Version);

spec(Name, Version) ->
	gen_server:call(agner_server, {spec, Name, Version}).

-spec index() -> list(agner_spec_name()).

index() ->
    gen_server:call(agner_server, index).

-spec fetch(agner_spec_name(), directory()) -> ok | not_found_error().
-spec fetch(agner_spec_name(), agner_spec_version(), directory()) -> ok | not_found_error().

fetch(Name, Directory) ->
    fetch(Name, {branch, "master"}, Directory).

fetch(Name, Version, Directory) when is_list(Version) ->
    fetch(Name, agner_spec:list_to_version(Version), Directory);
fetch(Name, Version, Directory) ->
    gen_server:call(agner_server, {fetch, Name, Version, Directory}).

-spec versions(agner_spec_name()) -> list(agner_spec_version()).

versions(Name) ->
    gen_server:call(agner_server, {versions, Name}).
                      
                   
