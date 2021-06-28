-module(math_server).
-export([start/0,factorial/2,status/1,stop/1]).

% start a server, return server's pid
start() ->
  spawn(fun () -> loop(0) end).

% event loop
loop(N) ->
  receive
      % `factorial' command
    {factorial, From, Ref, M} ->
      From ! {response, Ref, compute_factorial(M)},
      loop(N+1); % increment request number
      % `status' command
    {status, From, Ref} ->
      From ! {response, Ref, N},
      loop(N);   % don't increment request number
      % `stop' command
    {stop, _From, _Ref} ->
      ok
  end.

% compute factorial(M) on `Server'
factorial(Server, M) ->
  Ref = make_ref(),  % unique reference number
    % send request to server
  Server ! {factorial, self(), Ref, M}, 
    % wait for response, and return it
  receive {response, Ref, Result} -> Result end.

% return number of requests served so far by `Server'
status(Server) ->
  Ref = make_ref(), % unique reference number
    % send request to server
  Server ! {status, self(), Ref},
    % wait for response, and return it
  receive {response, Ref, Result} -> Result end.

% shutdown `Server'
stop(Server) ->
  Server ! {stop, self(), 0}, % Ref is not needed
  ok.


% tail-recursive factorial computation
compute_factorial(M)      -> compute_factorial(M, 1).
compute_factorial(0, Acc) -> Acc;
compute_factorial(M, Acc) -> compute_factorial(M-1, M*Acc).
