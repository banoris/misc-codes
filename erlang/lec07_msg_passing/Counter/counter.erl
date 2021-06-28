-module(counter).
-export([base_counter/1,increment_twice/0,
         wait_and_hope/0,
         counter/2,increment_and_monitor/0,monitor_counter/1]).

base_counter(N) ->
  receive {From, Command} -> case Command of
      increment -> base_counter(N+1);        % increment counter
      count     -> From ! {self(), N},       % send current value
                   base_counter(N);          % do not change value
      U         -> io:format("? ~p~n", [U])  % unrecognized command
  end end.

increment_twice() ->
  Counter = spawn(counter, base_counter, [0]), % counter initially 0
    % function sending message `increment' to Counter
  FCount  = fun () -> Counter ! {self(), increment} end,
  spawn(FCount), spawn(FCount), % two processes running FCount
  Counter ! {self(), count},    % send message `count'
    % wait for response from Counter and print it
  receive {Counter, N} -> io:format("Counter is: ~p~n", [N]) end.

wait_and_hope() ->
  Counter = spawn(counter, base_counter, [0]), % counter initially 0
  FCount  = fun () -> Counter ! {self(), increment} end,
  spawn(FCount), spawn(FCount), % two processes running FCount
  timer:sleep(100), % wait for `increment' to be delivered
  Counter ! {self(), count},    % send message `count'
  receive {Counter, N} -> io:format("Counter is: ~p~n", [N]) end.

counter(N, Log) -> receive
  {_, increment} -> % send notification, update count
     Log ! {self(), N+1}, counter(N+1, Log);
  {From, count} ->  % send count, next message
     From ! {self(), N}, counter(N, Log) end.

% set up counter and incrementers; then start monitor
increment_and_monitor() ->
  Counter = spawn(?MODULE, counter, [0, self()]),
  FCount  = fun () -> Counter ! {self(), increment} end,
  spawn(FCount), spawn(FCount),
  monitor_counter(Counter).  % start monitor

monitor_counter(Counter) ->
    receive {Counter, N} ->
        io:format("Counter is: ~p~n", [N])
    end,
    monitor_counter(Counter).
