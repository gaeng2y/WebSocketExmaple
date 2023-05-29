//
//  ViewController.swift
//  WebSocketExample
//
//  Created by gaeng on 2023/05/29.
//

import UIKit

class ViewController: UIViewController {
    private let textField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.placeholder = "메세지를 입력해주세요."
        return textField
    }()
    
    private let sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("전송", for: .normal)
        return button
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("소켓 연결 해제", for: .normal)
        return button
    }()
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        setLayout()
        setAction()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        WebSocket.shared.url = URL(string: "ws://localhost:1337/")
        do {
            try WebSocket.shared.openWebSocket()
        } catch {
            guard let webSocketError = error as? WebSocketError,
                  webSocketError == .invalidUrl else {
                let alert = UIAlertController(title: nil, message: "웹소켓 주소를 확인해주세요.", preferredStyle: .alert)
                self.present(alert, animated: true)
                return
            }
        }
        
        WebSocket.shared.delegate = self
        // UserName
        WebSocket.shared.send(message: "iOS")
    }
    
    private func setLayout() {
        [textField, sendButton, closeButton].forEach {
            self.view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 200),
            textField.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 50),
            textField.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            textField.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        NSLayoutConstraint.activate([
            sendButton.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 50),
            sendButton.widthAnchor.constraint(equalToConstant: 100),
            sendButton.heightAnchor.constraint(equalToConstant: 50),
            sendButton.centerXAnchor.constraint(equalTo: textField.centerXAnchor)
        ])
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: sendButton.bottomAnchor, constant: 50),
            closeButton.widthAnchor.constraint(equalToConstant: 100),
            closeButton.heightAnchor.constraint(equalToConstant: 50),
            closeButton.centerXAnchor.constraint(equalTo: textField.centerXAnchor)
        ])
    }
    
    private func setAction() {
        sendButton.addTarget(self, action: #selector(onClickSend(_:)), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(onClickClose(_:)), for: .touchUpInside)
    }
    
    @objc private func onClickSend(_ sender: UIButton) {
        guard let message = textField.text else { return }
        
        WebSocket.shared.send(message: message)
        textField.text = nil
    }
    
    @objc private func onClickClose(_ sender: UIButton) {
        WebSocket.shared.closeWebSocket()
    }
}

extension ViewController: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("WebSocket did open")
    }
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("WebSocket did close")
    }
}
