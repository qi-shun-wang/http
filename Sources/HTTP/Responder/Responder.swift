//public protocol Responder {
//    func respond(to request: Request) throws -> Response
//}
import Dispatch

public protocol Responder {
    func respond(to request: Request, with writer: ResponseWriter) throws
}

extension Responder {
    public func respondSync(to request: Request) throws -> Response {
        let semaphore = DispatchSemaphore(value: 0)
        var res: Response!
        
        try respond(to: request) { response in
            res = response
            semaphore.signal()
        }
        semaphore.wait()
        
        return res
    }
}

public struct BasicSyncResponder: Responder {
    public typealias Closure = (Request) throws -> Response
    let closure: Closure
    
    public init(_ closure: @escaping Closure) {
        self.closure = closure
    }
    
    public func respond(to request: Request, with writer: ResponseWriter) throws {
        let res = try closure(request)
        try writer.write(res)
    }
}

public struct BasicResponder: Responder {
    public typealias Closure = (Request, ResponseWriter) throws -> ()
    let closure: Closure
    public init(_ closure: @escaping Closure) {
        self.closure = closure
    }
    
    public func respond(to request: Request, with writer: ResponseWriter) throws {
        try self.closure(request, writer)
    }
}

extension Responder {
    func respond(to request: Request, with closure: @escaping (Response) throws -> ()) throws {
        let writer = BasicResponseWriter(closure)
        try self.respond(to: request, with: writer)
    }
}

public protocol ResponseWriter {
    func write(_ response: Response) throws
}

extension ResponseWriter {
    public func write(_ response: ResponseRepresentable) throws {
        let res = try response.makeResponse()
        try write(res)
    }
}

import Transport

public struct BasicResponseWriter: ResponseWriter {
    public typealias Closure = (Response) throws -> ()
    
    let closure: Closure
    
    public init(_ closure: @escaping Closure) {
        self.closure = closure
    }
    
    public func write(_ response: Response) throws {
        try closure(response)
    }
}
