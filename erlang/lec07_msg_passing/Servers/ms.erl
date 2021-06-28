-module(ms).
-export([start/0,stop/1,factorial/2,status/1,new_handler/2]).


start() -> gserver:start(0, fun math_handler/2).
stop(Server) -> gserver:stop(Server).

math_handler(N, {factorial, M}) -> {reply, N+1, compute_factorial(M)};
math_handler(N, status) -> {reply, N, N}.

factorial(Server, M) -> gserver:request(Server, {factorial, M}).

status(Server) -> gserver:request(Server, status).

new_handler(N, Request={factorial, _M}) -> math_handler(N, Request);
new_handler(N, status) -> math_handler(N, status);
new_handler(N, {product, X, Y}) -> {reply, N+1, X*Y}.


% tail-recursive factorial computation
compute_factorial(M)      -> compute_factorial(M, 1).
compute_factorial(0, Acc) -> Acc;
compute_factorial(M, Acc) -> compute_factorial(M-1, M*Acc).
