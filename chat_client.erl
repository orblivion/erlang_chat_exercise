-module(chat_client).
-export([client/0]).

client() ->
    SomeHostInNet = "localhost", % to make it runnable on one machine
    {ok, Sock} = gen_tcp:connect(SomeHostInNet, 5678, 
                                 [binary, {packet, 0}, {active, false}]),
    spawn(fun() -> recv_loop(Sock, []) end),
    send_loop(Sock),
    ok = gen_tcp:close(Sock).

send_loop(Sock) ->
    Msg = io:get_line("Me >"),
    case Msg of
        "/end\n" -> ok;
        _ -> gen_tcp:send(Sock, Msg), send_loop(Sock)
    end.

recv_loop(Sock, Accum) ->
    case gen_tcp:recv(Sock, 0) of
        {ok, B} ->
            case binary:split(B, <<"\n">>) of
                [MsgEnd|Next] ->
                    io:format([Accum, MsgEnd]),
                    io:format("\n"),
                    recv_loop(Sock, [Next]);
                _ ->
                    recv_loop(Sock, [Accum, B])
            end;
        {error, closed} ->
            ok
    end.
