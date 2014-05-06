-module(chat_server).
-export([server/0]).

server() ->
    {ok, LSock} = gen_tcp:listen(5678, [binary, {packet, 0}, 
                                        {active, false}]),
    ConnectioonManager = self(),
    spawn(fun() -> new_connections(ConnectioonManager, LSock) end),
    manage_connections([]),
    ok = gen_tcp:close(LSock).

new_connections(ConnectionManager, LSock) ->
    case gen_tcp:accept(LSock) of 
        {ok, Sock} -> 
            ConnectionManager ! {add_sock, Sock},
            new_connections(ConnectionManager, LSock);
        {error, closed} -> ok
    end.

handle_connection(ConnectionManager, MySock, Accum) ->
    case gen_tcp:recv(MySock, 0) of
        {ok, B} ->
            case binary:split(B, <<"\n">>) of
                [MsgEnd|Next] ->
                    Msg = binary_to_list(list_to_binary([Accum, MsgEnd])),
                    case Msg of
                        "/kill" -> 
                            ConnectionManager ! die;
                        _ ->
                            ConnectionManager ! {send_msg, self(), MySock, Msg},
                            handle_connection(ConnectionManager, MySock, [Next])
                    end;
                _ ->
                    handle_connection(ConnectionManager, MySock, [Accum, B])
            end;
        {error, closed} ->
            ConnectionManager ! {remove_sock, self(), MySock}
    end.

send(FormattedMsg, SenderSock, Socks) ->
    Recipients = lists:delete(SenderSock, Socks),
    lists:map(fun(Sock) -> gen_tcp:send(Sock, FormattedMsg) end, Recipients).

manage_connections(Socks) ->
    receive
        {add_sock, Sock} ->
            ConnectioonManager = self(),
            Joiner = spawn(fun() -> handle_connection(ConnectioonManager, Sock, []) end),
            send(io_lib:format("~p joins", [Joiner]), Sock, Socks),
            manage_connections([Sock|Socks]);
        {remove_sock, Leaver, Sock} -> 
            send(io_lib:format("~p leaves", [Leaver]), Sock, Socks),
            manage_connections(lists:delete(Sock, Socks));
        {send_msg, Sender, SenderSock, Msg} -> 
            send(io_lib:format("~p: ~p", [Sender, Msg]), SenderSock, Socks),
            manage_connections(Socks);
        die -> ok
    end.
