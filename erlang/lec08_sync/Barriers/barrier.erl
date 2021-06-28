-module(barrier).
-export([init/1,wait/1]).

% initialize barrier for `Expected' processes
init(Expected) ->
   spawn(fun () -> barrier(0, Expected, []) end).

% event loop of barrier for `Expected' processes
%   Arrived: number of processes arrived so far
%   PidRefs: list of {Pid, Ref} of processes arrived so far
barrier(Arrived, Expected, PidRefs)
   when Arrived =:= Expected ->     % all processes arrived
     % notify all waiting processes
     [To ! {continue, Ref} || {To, Ref} <- PidRefs],
     % reset barrier
     barrier(0, Expected, []);
barrier(Arrived, Expected, PidRefs) -> 
   receive  % still waiting for some processes
      {arrived, From, Ref} ->
        % one more arrived: add {From, Ref} to PidRefs list
        barrier(Arrived+1, Expected, [{From, Ref}|PidRefs])
   end.

% block at `Barrier' until all processes have reached it
wait(Barrier) ->
   Ref = make_ref(),
     % notify barrier of arrival
   Barrier ! {arrived, self(), Ref},
     % wait for signal to continue
   receive {continue, Ref} -> through end. 
