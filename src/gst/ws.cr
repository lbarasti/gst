require "uuid"

module WS
  Sockets = {} of UUID => HTTP::WebSocket
  InvalidRoute = {"error": "invalid route"}.to_json
  TooManyConnections = {"error": "too many open connections"}.to_json
  MaxConnections = 20 # TODO: read from config

  def self.status_update(job_id : UUID, status : JobStatus, bytes : UInt64 | Nil = nil)
    if Sockets[job_id]?
      Sockets[job_id].send(
        {"job_id": job_id, "status": status.to_s.downcase, "bytes": bytes}.to_json)
      if !status.active?
        Sockets[job_id].close()
        Sockets.delete(job_id)
      end
    end
  end

  def self.init(id : UUID, socket : HTTP::WebSocket)
    if Sockets.size >= WS::MaxConnections
      socket.send(WS::TooManyConnections)
      socket.close()
    else
      Sockets[id] = socket
      socket.on_close { |msg|
        log "#{id}: socket closed"
        Sockets.delete(id)
      }
    end
  rescue ArgumentError
    socket.close(WS::InvalidRoute)
  end

  def self.active_sockets
    Sockets.size
  end
end
