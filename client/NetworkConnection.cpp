#include "NetworkConnection.h"

NetworkConnection::NetworkConnection(NetworkQueue<std::string>& messageQueue)
{
    _messageQueue = &messageQueue;
    _tcpSocket = new sf::TcpSocket();
}


void NetworkConnection::TCPSend(std::string message)
{
    // Send message to the TCP server
    std::string buffer_out = message;
    if (_tcpSocket->send(buffer_out.c_str(), buffer_out.size()) != sf::Socket::Done)
        std::cerr << "sending failed" << std::endl;
}

void NetworkConnection::Close()
{
    TCPSend("CLOSE::\n");
}

void NetworkConnection::RegisterNickname(std::string name)
{
    TCPSend("REG::" + name + "::\n");
}

void NetworkConnection::UnregisterNickname(std::string name)
{
    TCPSend("UNREG::" + name + "::\n");
}

void NetworkConnection::UpdatePosition(int x, int y, std::string name)
{
    std::ostringstream ss;
    ss << "UPDATEPOS::" << x << "::" << y << "::" << name << "::\n";
    TCPSend(ss.str());
}

void NetworkConnection::SendMessageTo(std::string addresseeName, std::string message)
{
    TCPSend("SEND::" + addresseeName + "::" + message + "::\n");
}

void NetworkConnection::SendMessageGlobal(std::string chatMessageString, std::string addresseeName)
{
    TCPSend("SENDGLOBAL::" + addresseeName + "::" + chatMessageString + "::\n");
}

void NetworkConnection::ShowPositions(std::string addresseeName)
{
    TCPSend("SHOWPOSITIONS::" + addresseeName + "::\n");
}

void NetworkConnection::Initialisation(std::string userName)
{
    TCPSend("INITIALISATION::" + userName + "::\n");
}

void NetworkConnection::SetPosition(int x, int y, std::string addresseeName)
{
    std::ostringstream ss;
    ss << "SETPOS::" << x << "::" << y << "::" << addresseeName << "::\n";
    TCPSend(ss.str());
}

void NetworkConnection::WaitingChallenge(std::string addresseeName)
{
    TCPSend("WAITINGCHALLENGE::" + addresseeName + "::\n");
}

void NetworkConnection::CancelChallenge(std::string addresseeName)
{
    TCPSend("CANCELCHALLENGE::" + addresseeName + "::\n");
}

void NetworkConnection::Challenge(std::string addresseeName, std::string opponentName)
{
    TCPSend("CHALLENGE::" + addresseeName + "::" + opponentName + "::\n");
}

void NetworkConnection::Choice(std::string addresseeName, int choice)
{
    std::ostringstream ss;
    ss << "CHOICE::" << addresseeName << "::" << choice << "::\n";
    TCPSend(ss.str());
}

bool NetworkConnection::Join(int port, std::string ipAddress)
{
    // Try to connect to the TCP server
    sf::Socket::Status status = _tcpSocket->connect(ipAddress, port);
    if (status != sf::Socket::Done)
    {
        std::cerr << "connect failed\n";
        return false;
    }
    return true;
}

void NetworkConnection::Receive()
{
    std::cout << "Receive Thread Started!" << std::endl;

    char buffer_in[1024];
    std::size_t received;

    // TCP socket receive
    std::string message = "";
    while(message != "CLOSE")
    {
        if (_tcpSocket->receive(buffer_in, 100, received) != sf::Socket::Done)
            continue;

        message = buffer_in;

        // Push message onto the queue
        _messageQueue->push(message);
    }

    std::cout << "Closing Receive Thread..." << std::endl;

    delete _tcpSocket;
}
