#ifndef CHATSYSTEM_H
#define CHATSYSTEM_H

#include <SFML/Graphics.hpp>

class ChatSystem
{
    public:
        inline ChatSystem() {}
        inline ~ChatSystem() {}

        // Render the messages (4 in this case)
        void Render(sf::RenderWindow& window, sf::Font& myFont, const int screenHeight);

        // Add a new message to the log, pushing all messages up once
        // so that only the newest 4 messages are visible.
        void NewMessage(const std::string message);

    public:
        // this is the string the user inputs
        std::string chatMessageString = "...";

    private:
        const static int _CHAT_MESSAGES_MAX = 4;
        std::string _chatMessages[_CHAT_MESSAGES_MAX];
        int _currentChatMessageToReplace = -1;
};

#endif // CHATSYSTEM_H
