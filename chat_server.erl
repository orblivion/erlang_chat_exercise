-module(chat_server).
-export([server/0]).

server() ->
    {ok, LSock} = gen_tcp:listen(5678, [binary, {packet, 0}, 
                                        {active, false}]),
    ConnectioonManager = self(),
    spawn(fun() -> new_connections(ConnectioonManager, LSock) end),
    manage_connections([]).

new_connections(ConnectionManager, LSock) ->
    {ok, Sock} = gen_tcp:accept(LSock),
    ConnectionManager ! {add_sock, Sock},
    new_connections(ConnectionManager, LSock).

handle_connection(ConnectionManager, Sock, Bs) ->
    case binary:split(Bs, <<"\n">>) of
        [Msg|Next] ->
            io:format(">~p", [Msg]),
            ConnectionManager ! {send_msg, self(), Sock, Msg},
            handle_connection(ConnectionManager, Sock, Next);
        _ ->
            case gen_tcp:recv(Sock, 0) of
                {ok, B} ->
                    handle_connection(ConnectionManager, Sock, [Bs, B]);
                {error, closed} ->
                    ConnectionManager ! {remove_sock, Sock},
                    {ok, list_to_binary(Bs)}
            end
    end.

manage_connections(Socks) ->
    receive
        {add_sock, Sock} ->
            ConnectioonManager = self(),
            spawn(fun() -> handle_connection(ConnectioonManager, Sock, []) end),
            manage_connections([Sock|Socks]);
        {remove_sock, Sock} -> 
            manage_connections(lists:delete(Sock, Socks));
        {send_msg, Sender, SenderSock, Msg} -> 
            FormattedMsg = lists:flatten(io_lib:format("~p: ~p", [Sender, Msg])),
            Recipients = lists:delete(SenderSock, Socks),
            lists:map(fun(Sock) -> gen_tcp:send(Sock, FormattedMsg) end, Recipients)
    end.

%spit(LSock) ->
%    {ok, Sock} = gen_tcp:accept(LSock),
%    {ok, Bin} = do_recv(Sock, []),
%    case Bin of
%        <<"exit">> ->
%            ok;
%        _ ->
%            ok = gen_tcp:close(Sock),
%            io:format(Bin),
%            spit(LSock)
%    end.
%

