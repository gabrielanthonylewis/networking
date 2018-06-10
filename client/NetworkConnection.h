#ifndef CONNECTION_H
#define CONNECTION_H

#include <SFML/Network.hpp>
#include <iostream>
#include <sstream>

#include "NetworkQueue.h"


class NetworkConnection
{
    public:
        NetworkConnection(NetworkQueue<std::string>& messageQueue);

        // Join the server
        bool Join(int port, std::string ipAddress);

        // Server Messages
        void Close();
        void RegisterNickname(std::string addresseeName);
        void SendMessageTo(std::string addresseeName, std::string message);
        void UnregisterNickname(std::string addresseeName);
        void UpdatePosition(int x, int y, std::string addresseeName);
        void ShowPositions(std::string addresseeName);
        void SetPosition(int x, int y, std::string addresseeName);
        void WaitingChallenge(std::string addresseeName);
        void CancelChallenge(std::string addresseeName);
        void Challenge(std::string addresseeName, std::string opponentName);
        void Choice(std::string addresseeName, int choice);
        void SendMessageGlobal(std::string chatMessageString, std::string addresseeName);
        void Initialisation(std::string userName);

        // Overload the () operator so that the Receive() function is called.
        // This is for the thread, to set it up this work around is needed.
        // (Receive is on the thread)
        void operator()() { Receive(); }

    private:
        // Receive loop on the thread to get messages
        // from the server, adding them to the queue.
        void Receive();

        // Helper function to send the message to the server.
        void TCPSend(std::string message);

    private:
        sf::TcpSocket* _tcpSocket;
        NetworkQueue<std::string>* _messageQueue;
};

#endif // CONNECTION_H
