https://github.com/dustyirwin/GameOne.jl#main

https://github.com/dustyirwin/PlaymatSimulator.jl#main







event_array = [Char(i) for i = event] = ['\0', '\x03', '\0', '\0', '_', '\u90', '\x01', '\0', '\x01', '\0', '\0', '\0', '\x01', '\0', '\0', '\0', 'à', '\0', '\0', '\0', 'à', '\0', '\0', '@', '@', '\x10', '\0', '\0', '\0', '\0', '\0', '\0', 'R', '\u97', 'o', '\u87', '\0', '\0', '\0', '\0', 'À', '×', 'Þ', '\a', '\0', '\0', '\0', '\0', '\0', '\x01', '\0', '\0', '\0', '\0', '\0', '\0']
event_array = [Char(i) for i = event] = ['\x01', '\x03', '\0', '\0', 'Ü', '\u90', '\x01', '\0', '\x01', '\0', '\0', '\0', '\0', '\0', '\0', '\0', 'à', '\0', '\0', '\0', 'à', '\0', '\0', '@', '\0', '\x10', '\0', '\0', '\0', '\0', '\0', '\0', 'R', '\u97', 'o', '\u87', '\0', '\0', '\0', '\0', 'À', '×', 'Þ', '\a', '\0', '\0', '\0', '\0', '\x01', '\x01', '\0', '\0', '\0', '\0', '\0', '\0']



"""
client_task = @async begin
    try
        WebSockets.open("ws://$SERVERIP:$HTTPPORT") do ws_client

            while !eof(ws_client)
                data, success = readguarded(ws_client)
                if success
                    println(" received:", String(data), " at $(now())")
                    push!(INBOUND, String(data))
                else
                    println("read ws failed.")
                end
            end
        end
    catch exc
        println(stacktrace())
        println(exc)
    end
end
"""




"""
function coroutine(thisws)
    while true
        if length(OUTBOUND) > 0
            writeguarded(thisws, popfirst!(OUTBOUND))
        end
        sleep(5)
    end

    nothing
end

function gatekeeper(req, ws)
    orig = WebSockets.origin(req)
    data = WebSockets.read(ws, String)


    if occursin(ALLOWEDIPS, orig) | occursin("", orig)
        coroutine(ws)
        println(data)
    else        
        @warn("Unauthorized websocket connection, $orig not approved by gatekeeper, expected $LOCALIP")
    end
    nothing
end

serverWS = WebSockets.ServerWS((req) -> WebSockets.Response(200), 
                                        gatekeeper)

push!(OUTBOUND, "hello world!")
"""