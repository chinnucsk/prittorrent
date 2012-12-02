-module(hasher_recheck).

-export([start_link/0, loop/0]).


start_link() ->
    {ok, spawn_link(fun loop/0)}.

loop() ->
    case model_enclosures:to_recheck() of
	nothing ->
	    %% Idle 5..10s
	    Delay = 5000 + random:uniform(5000),
	    receive
	    after Delay ->
		    ok
	    end;
	{ok, URL, Length, ETag, LastModified} ->
	    io:format("Recheck ~s~n", [URL]),
	    case storage:resource_info(URL) of
		{ok, _Type, ContentLength, ContentETag, ContentLastModified}
		  when Length == ContentLength,
		       ETag == ContentETag,
		       LastModified == ContentLastModified ->
		    nothing_changed;

		{ok, _Type, ContentLength, ContentETag, ContentLastModified} ->
		    io:format("Need recheck: ~s~n", [URL]),
		    io:format("\tLength: ~p /= ~p~n", [Length, ContentLength]),
		    io:format("\tETag: ~p /= ~p~n", [ETag, ContentETag]),
		    io:format("\tLast-Modified: ~p /= ~p~n", [LastModified, ContentLastModified]),
		    hasher_sup:recheck(URL);

		{error, E} ->
		    io:format("Recheck ~s failed:~n~p~n", [URL, E])

	    end
    end,
    
    ?MODULE:loop().
	  
