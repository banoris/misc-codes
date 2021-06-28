-module(buffer).
-export([init_buffer/1,get/1,put/2]).

% initialize buffer with size `Bound'
% (use `infinity' for unbounded buffer)
init_buffer(Bound) ->
   spawn(fun () -> buffer([], 0, Bound) end).

% event loop of buffer with a `Content' list 
% of `Count' items and maximum size `Bound'
buffer(Content, Count, Bound) ->
   receive
     % serve gets when buffer not empty
     {get, From, Ref} when Count > 0 ->
        [First|Rest] = Content,       % match first item
        From ! {item, Ref, First},    % send it out
        buffer(Rest, Count-1, Bound); % remove it from buffer
     % serve puts when buffer not full
     {put, From, Ref, Item} when Count < Bound ->
        From ! {done, Ref},                       % send ack
        buffer(Content ++ [Item], Count+1, Bound) % add item to end
   end.

% get item from `Buffer'; block if empty
get(Buffer) ->
   Ref = make_ref(),
   Buffer ! {get, self(), Ref},
   receive {item, Ref, Item} -> Item end.

% put `Item' in `Buffer'; block if full
put(Buffer, Item) ->
   Ref = make_ref(),
   Buffer ! {put, self(), Ref, Item},
   receive {done, Ref} -> done end.
