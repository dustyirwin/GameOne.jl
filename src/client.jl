
module Client

using HTTP
using JSON
using Random


HTTP.WebSockets.open("ws://127.0.0.1:8081") do ws
    running = true
    
    while running
        send_message = Dict(:x => 0.34, :y => "hello")
        data = JSON.json(send_message)
        write(ws, data)
        recieved_message = readavailable(ws)
        message = JSON.parse(String(recieved_message))
        println(message)
        running = message["y"] == "bye" ? false : true
    end

    println("Exiting...\n")
end


"""
@async HTTP.WebSockets.open("ws://192.168.1.140:8081") do ws
    send_message = Dict(:id => 1, :y => img)
    data = JSON.json(send_message)
    write(ws, data)
    recieved_message = readavailable(ws)
    message = JSON.parse(String(recieved_message))
    println(message)
end
"""

end # module
