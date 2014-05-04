-module(chat_client).
-export([client/1]).

client(Text) ->
    SomeHostInNet = "localhost", % to make it runnable on one machine
    {ok, Sock} = gen_tcp:connect(SomeHostInNet, 5678, 
                                 [binary, {packet, 0}]),
    ok = gen_tcp:send(Sock, Text),
    ok = gen_tcp:close(Sock).
