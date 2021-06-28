-module(rgserver).  % robust generic server
-export([start/2,start/3,request/2,update/2,stop/1]).

% start a server, return server's pid
start(InitialState, Handler) ->
  spawn(fun () -> loop(InitialState, Handler) end).

% event loop
loop(State, Handler) ->
  receive
      % a request from `From' with data `Request'
    {request, From, Ref, Request} ->
        % run handler on request
      case catch(Handler(State, Request)) of
          % in case of error
        {'EXIT', Reason} ->
            % the requester gets the exception
          From ! {error, Ref, Reason},
            % the server continues in the same state
          loop(State, Handler);
          % otherwise (no error): get handler's output
        {reply, NewState, Result} ->
            % the requester gets the result
          From ! {response, Ref, Result},
            % the server continues with the new state
          loop(NewState, Handler)
      end;
      % a request to swap `NewHandler' for `Handler'
    {update, From, Ref, NewHandler} ->
      From ! {ok, Ref},         % ack
        % the server continues with the new handler
      loop(State, NewHandler);
         {stop, _From, _Ref} -> ok;
      % discard unrecognized messages
    _ -> loop(State, Handler)
  end.

% issue a request to `Server'; return answer
request(Server, Request) ->
  Ref = make_ref(),  % unique reference number
   % send request to server
  Server ! {request, self(), Ref, Request},
   % wait for response, and return it
  receive
    {response, Ref, Result} -> Result
    % after 10 seconds, give up
  after 10000 -> timeout end.

% change `Server's handler to `NewHandler'
update(Server, NewHandler) ->
  Ref = make_ref(),  % send update request to server
  Server ! {update, self(), Ref, NewHandler},
  receive {ok, Ref} -> ok end.  % wait for ack


% start a server and register with `Name'
start(InitialState, Handler, Name) ->
  register(Name, start(InitialState, Handler)).

stop(Server) ->
  Server ! {stop, self(), 0}, % Ref is not needed
  ok.
