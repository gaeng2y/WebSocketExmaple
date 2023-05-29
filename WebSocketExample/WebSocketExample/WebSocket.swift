//
//  WebSocket.swift
//  WebSocketExample
//
//  Created by gaeng on 2023/05/29.
//

import Foundation

enum WebSocketError: Error {
    case invalidUrl
}

final class WebSocket: NSObject {
    static let shared = WebSocket()
    
    private override init() { }
    
    var url: URL?
    weak var delegate: URLSessionWebSocketDelegate?
    
    private var webSocketTask: URLSessionWebSocketTask? {
        didSet {
            guard let oldValue else { return }
            oldValue.cancel(with: .normalClosure, reason: nil)
        }
    }
      
    private var timer: Timer?
    
    func openWebSocket() throws {
        guard let url = url else { throw WebSocketError.invalidUrl }
        
        let urlSession = URLSession(
            configuration: .default,
            delegate: self,
            delegateQueue: OperationQueue()
        )
        let webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask.resume()
        
        self.webSocketTask = webSocketTask
    }
    
    func send(message: String) {
        self.send(message: message, data: nil)
    }
    
    func send(data: Data) {
        self.send(message: nil, data: data)
    }
    
    private func send(message: String?, data: Data?) {
        let taskMessage: URLSessionWebSocketTask.Message
        if let message {
            taskMessage = URLSessionWebSocketTask.Message.string(message)
        } else if let data {
            taskMessage = URLSessionWebSocketTask.Message.data(data)
        } else {
            return
        }
        
        print("Send message \(taskMessage)")
        self.webSocketTask?.send(taskMessage, completionHandler: { error in
            guard let error = error else { return }
            print("WebSOcket sending error: \(error)")
        })
    }
    
    func closeWebSocket() {
        self.webSocketTask = nil
        self.timer?.invalidate()
        self.delegate = nil
    }
    
    func receive() {
        self.webSocketTask?.receive(completionHandler: { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .data(let data):
                    print("Got data: \(data)")
                case .string(let message):
                    print("Got string: \(message)")
                @unknown default:
                    break
                }
            case .failure(let error):
                print("Receive error: \(error)")
            }
            
            self?.receive()
        })
    }
    
    private func startPing() {
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(
            withTimeInterval: 10,
            repeats: true,
            block: { [weak self] _ in self?.ping() }
        )
    }
    
    private func ping() {
        self.webSocketTask?.sendPing(pongReceiveHandler: { [weak self] error in
            guard let error = error else { return }
            print("Ping failed \(error)")
            self?.startPing()
        })
    }
}

extension WebSocket: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        self.startPing()
        self.receive()
        self.delegate?.urlSession?(session, webSocketTask: webSocketTask, didOpenWithProtocol: `protocol`)
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        self.delegate?.urlSession?(session, webSocketTask: webSocketTask, didCloseWith: closeCode, reason: reason)
    }
}
