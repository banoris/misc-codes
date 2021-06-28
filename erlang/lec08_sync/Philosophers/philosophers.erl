-module(philosophers).
-compile([export_all]).
-record(forks, {left, right}).

% set up table of `N' philosophers
init(N) ->
     % register random generator (name used in think/0 and eat/0)
   register(rng_philosophers, spawn(fun rand_int/0)),
     % spawn waiter process
   Waiter = spawn(fun () -> waiter(0, N-1) end),
   Ids = lists:seq(1,N), % [1, 2, ..., N]
     % spawn fork processes
   Forks = [spawn(fun fork/0) || _ <- Ids],
     % spawn philosopher processes
   Philosophers = [spawn(fun () ->
                    Left = lists:nth(I, Forks),
                    Right = lists:nth(1+(I rem N), Forks), % +1 mod N 1-based
                    philosopher(#forks{left=Left, right=Right},
                                Waiter) end)
                       || I <- Ids],
   Philosophers.

% a fork not held by anyone
fork() ->
   receive
     {get, From, Ref} ->
       From ! {ack, Ref},
       fork(From) % fork held
   end.

% a fork held by Owner
fork(Owner) ->
   receive
     {put, Owner, _Ref} ->
       fork()  % fork not held
   end.

% pick up `Fork'; block until available
get_fork(Fork) ->
    Ref = make_ref(),
    Fork ! {get, self(), Ref},
    receive {ack, Ref} -> ack end.

% put down `Fork'
put_fork(Fork) ->
    Ref = make_ref(),
    Fork ! {put, self(), Ref}.

% waiter event loop for `Eating' philosophers 
% out of `Seats' maximum seats at a time
waiter(Eating, Seats) ->
   receive
       % serve as long as seats are available
     {sit, From, Ref} when Eating < Seats ->
        io:format("~p eating (~p at table)~n", [From, Eating+1]),
        From ! {ok_to_sit, Ref},
        waiter(Eating+1, Seats);   % one more eating
       % can leave at any time
     {leave, From, Ref} ->
        io:format("~p leaving (~p at table)~n", [From, Eating-1]),
        From ! {ok_to_leave, Ref},
        waiter(Eating-1, Seats)    % one less eating
   end.

% ask `Waiter' to be seated; may wait
sit(Waiter) ->
   Ref = make_ref(),
   Waiter ! {sit, self(), Ref},
   receive {ok_to_sit, Ref} -> ok end.

% ask `Waiter' to leave
leave(Waiter) ->
   Ref = make_ref(),
   Waiter ! {leave, self(), Ref},
   receive {ok_to_leave, Ref} -> ok end.

% philosopher loop
% Forks: fork#{left, right} of fork pids
% Waiter: waiter process
philosopher(Forks, Waiter) ->
   think(),
   sit(Waiter),                 % ask to be seated
   get_fork(Forks#forks.left),  % pick up left fork
   get_fork(Forks#forks.right), % pick up right fork
   eat(),
   put_fork(Forks#forks.left),  % put down left fork
   put_fork(Forks#forks.right), % put down right fork
   leave(Waiter),               % notify leaving
   philosopher(Forks, Waiter).


think() ->
   timer:sleep(500 + get_rand(rng_philosophers, 500)).

eat() ->
   timer:sleep(get_rand(rng_philosophers, 100)).


% random integer generator event loop
rand_int() ->
   receive
		{rand, From, Req, N} -> From ! {res, Req, random:uniform(N)},
      rand_int()
   end.

% get a random integer between 1 and N
get_rand(Rng, N) ->
   Ref = make_ref(),
	Rng ! {rand, self(), Ref, N},
   receive {res, Ref, Random} -> Random end.
