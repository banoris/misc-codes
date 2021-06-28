-module(producer_consumer).
-export([producer_consumer/5]).

% initialize producer/consumer system
% use infinity for unbounded Produced/Consumer/BufferSize
producer_consumer(Producers, Produced, 
                  Consumers, Consumed, 
                  BufferSize) ->
   random:seed(now()),
   Rng = spawn(fun rand_int/0),
	Buffer = buffer:init_buffer(BufferSize),
   [spawn(fun () -> producer(0, Produced, Buffer, Rng) end) 
       || _ <- lists:seq(1, Producers)],
   [spawn(fun () -> consumer(0, Consumed, Buffer, Rng) end)
       || _ <- lists:seq(1, Consumers)],
   ok.


% producer of ToBeProduced random items
%  Produced: # items produced so far
%  Buffer: shared buffer pid
%  Rng: random generator server
producer(Produced, ToBeProduced, _, _)
   when Produced =:= ToBeProduced -> done;
producer(Produced, ToBeProduced, Buffer, Rng) ->
	timer:sleep(get_rand(Rng, 100)),
	Item = get_rand(Rng, 100),
   buffer:put(Buffer, Item),
	io:format("Producer ~p has put ~p~n", [self(), Item]),
   producer(Produced + 1, ToBeProduced, Buffer, Rng).

% consumer of ToBeConsumed items
%  Consumed: # items consumed so far
%  Buffer: shared buffer pid
%  Rng: random generator server
consumer(Consumed, ToBeConsumed, _, _) 
   when Consumed =:= ToBeConsumed -> done;
consumer(Consumed, ToBeConsumed, Buffer, Rng) ->
	timer:sleep(get_rand(Rng, 100)),
	Item = buffer:get(Buffer),
	io:format("Consumer ~p has got ~p~n", [self(), Item]),
   consumer(Consumed + 1, ToBeConsumed, Buffer, Rng). 


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
