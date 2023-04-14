
module Server

const SERVERIP = "127.0.0.1"
const HTTPPORT = UInt16(8081)

using HTTP
using JSON
using Images

@async HTTP.WebSockets.listen(SERVERIP, HTTPPORT) do ws
    while !eof(ws)
        recieved_message = readavailable(ws)
        isempty(recieved_message) ? break : nothing
        data = JSON.parse(String(recieved_message))
        say = rand() < 0.1 ? "bye" : "hello"
        send_message = Dict(:x => rand(), :y => say)
        jmessage = JSON.json(send_message)
        write(ws, jmessage)
    end
end

end # module