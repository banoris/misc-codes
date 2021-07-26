-module(code_lock).
-behaviour(gen_statem).
-define(NAME, code_lock).

-export([start_link/1]).
-export([button/1, code_length/0]). % public API
-export([init/1,callback_mode/0,terminate/3]). % OTP behaviour

% Need to export state functions, in this door example.
% we have two states: locked and open
-export([locked/3,open/3]).

start_link(Code) ->
    gen_statem:start_link({local,?NAME}, ?MODULE, Code, []).

button(Button) ->
    gen_statem:cast(?NAME, {button,Button}).

code_length() ->
    gen_statem:call(?NAME, code_length).


init(Code) ->
    do_lock(),
    Data = #{code => Code, length => length(Code), buttons => []},
    {ok, locked, Data}.

callback_mode() ->
    state_functions.

% State1: locked
% Format: StateName(cast, Event, Data)
% Return Type:
%   {next_state, NewStateName, NewData} |
%   {next_state, NewStateName, NewData, Actions} |
%   https://erlang.org/doc/man/gen_statem.html#type-state_callback_result
%     super-long definitions. Eg type: {keep_state, NewData, Actions}
locked(cast, {button,Button},
        #{code := Code, length := Length, buttons := Buttons} = Data) ->
    NewButtons =
        if
            length(Buttons) < Length ->
                Buttons;
            true ->
                tl(Buttons)
        end ++ [Button],
        % NOTE: `end ++ [Button]` weird syntax? Appending an elem at the end.
        % Like C++ `buttons.push_back(button)`, or Python
        % `buttons.append(button)`
    if
        NewButtons =:= Code -> % Correct
            do_unlock(),
            % NOTE: when the unlock code is correct, the door remains
            %   unlocked for 10sec. How does it get locked after 10sec?
            %   Refer open(state_timeout, ...) below
                {next_state, open, Data#{buttons := []},
                    [{state_timeout,10000,lock}]}; % Time in milliseconds
        true -> % Incomplete | Incorrect
            {next_state, locked, Data#{buttons := NewButtons}}
    end;
locked(EventType, EventContent, Data) ->
    handle_common(EventType, EventContent, Data).

% State2: open
open(state_timeout, lock,  Data) ->
    do_lock(),
    {next_state, locked, Data};
open(cast, {button,_}, Data) ->
    {next_state, open, Data};
open(EventType, EventContent, Data) ->
    handle_common(EventType, EventContent, Data).

% Catch-all event handler
handle_common({call,From}, code_length, #{code := Code} = Data) ->
    {keep_state, Data,
     [{reply, From, length(Code)}]}.

do_lock() ->
    io:format("Lock~n", []).
do_unlock() ->
    io:format("Unlock~n", []).

terminate(_Reason, State, _Data) ->
    State =/= locked andalso do_lock(),
    ok.
