-module(bsync).
-export([bsync/2]).

% initialize barrier synchronization system
% for #`Processes' and #`Rounds'
bsync(Processes, Rounds) ->
   random:seed(now()),
	Rng = spawn(fun rand_int/0), 
	Barrier = barrier:init(Processes),
	[spawn(fun () -> barrierito(0, Rounds, Barrier, Rng) end)
      || _ <- lists:seq(1, Processes)],
   ok.

barrierito(Done, Rounds, _Barrier, _Rng) 
   when Done =:= Rounds -> done;
barrierito(Done, Rounds, Barrier, Rng) ->
	timer:sleep(get_rand(Rng, 100)),
	barrier:wait(Barrier),
   io:format("Process ~p has passed the barrier!~n", [self()]),
   barrierito(Done+1, Rounds, Barrier, Rng).


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
