-module(allocator).
-export([init/1,request/1,release/1]).

% initialize allocator with list of `Resources'
% register process under name allocator
init(Resources) ->
	Allocator = spawn(fun () -> allocator(Resources) end),
	register(allocator, Allocator).

% Allocator's event loop, holding list of `Resources'
allocator(Resources) ->
   % count how many resources are available
   Available = length(Resources),
   receive
     % serve requests if enough resources are available
     {request, From, Ref, N} when N =< Available ->
        % Granted ++ Remaining =:= Resources
        % length(Granted) =:= N
        {Granted, Remaining} = lists:split(N, Resources),
        % send resources to requesting process
        From ! {granted, Ref, Granted},
        % continue with Remaining resources
        allocator(Remaining);
     % serve releases
     {release, From, Ref, Released} ->
        % notify releasing process
        From ! {released, Ref},
        % continue with previous and released resources
        allocator(Resources ++ Released)
    end.

% get `N' resources from `allocator'; block if not available
request(N) ->
   Ref = make_ref(),
   allocator ! {request, self(), Ref, N},
   receive {granted, Ref, Granted} -> Granted end.

% release `Resources' to `allocator'
release(Resources) ->
   Ref = make_ref(),
   allocator ! {release, self(), Ref, Resources},
   receive {released, Ref} -> released end.
