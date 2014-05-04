-module(chat_server).
-export([server/0]).

server() ->
    {ok, LSock} = gen_tcp:listen(5678, [binary, {packet, 0}, 
                                        {active, false}]),
    spit(LSock).

spit(LSock) ->
    {ok, Sock} = gen_tcp:accept(LSock),
    {ok, Bin} = do_recv(Sock, []),
    case Bin of
        <<"exit">> ->
            ok;
        _ ->
            ok = gen_tcp:close(Sock),
            io:format(Bin),
            spit(LSock)
    end.

do_recv(Sock, Bs) ->
    case gen_tcp:recv(Sock, 0) of
        {ok, B} ->
            do_recv(Sock, [Bs, B]);
        {error, closed} ->
            {ok, list_to_binary(Bs)}
    end.
