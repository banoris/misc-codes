-module(gserver). % generic server
-export([start/2,request/2,stop/1]).

% start a server, return server's pid
start(InitialState, Handler) ->
  spawn(fun () -> loop(InitialState, Handler) end).

% event loop
loop(State, Handler) ->
  receive
      % a request from `From' with data `Request'
    {request, From, Ref, Request} ->
        % run handler on request
      case Handler(State, Request) of
          % get handler's output
        {reply, NewState, Result} ->
            % the requester gets the result
          From ! {response, Ref, Result},
            % the server continues with the new state
          loop(NewState, Handler)
      end;
    {stop, _From, _Ref} -> ok
  end.

% issue a request to `Server'; return answer
request(Server, Request) ->
  Ref = make_ref(),  % unique reference number
    % send request to server
  Server ! {request, self(), Ref, Request},
    % wait for response, and return it
  receive {response, Ref, Result} -> Result end.

stop(Server) ->
  Server ! {stop, self(), 0}, % Ref is not needed
  ok.
