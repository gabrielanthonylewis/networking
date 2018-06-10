#include "ChatSystem.h"


void ChatSystem::NewMessage(const std::string message)
{
    // Push up each message so only the latest 4 are shown
    // (which includes our new message)
    if(_currentChatMessageToReplace == _CHAT_MESSAGES_MAX - 1)
    {
        _chatMessages[0] = _chatMessages[1];
        _chatMessages[1] = _chatMessages[2];
        _chatMessages[2] = _chatMessages[3];
    }
    // Increment (if < 3 then still messages to fill)
    else
        _currentChatMessageToReplace++;

    _chatMessages[_currentChatMessageToReplace] = message;
}

void ChatSystem::Render(sf::RenderWindow& window, sf::Font& myFont, const int screenHeight)
{
    // Display messages
    sf::Text enterChatMessageText;
    enterChatMessageText.setCharacterSize(20);
    enterChatMessageText.setPosition(0, screenHeight - enterChatMessageText.getCharacterSize() * 1.5f);
    enterChatMessageText.setFont(myFont);
    enterChatMessageText.setString("Press / to type > " + chatMessageString);
    window.draw(enterChatMessageText);

    sf::Text chatMessageText1;
    chatMessageText1.setCharacterSize(20);
    chatMessageText1.setPosition(enterChatMessageText.getPosition() - sf::Vector2f(0, chatMessageText1.getCharacterSize() * 1.5f));
    chatMessageText1.setFont(myFont);
    chatMessageText1.setString(_chatMessages[3]);
    window.draw(chatMessageText1);

    sf::Text chatMessageText2;
    chatMessageText2.setCharacterSize(20);
    chatMessageText2.setPosition(chatMessageText1.getPosition() - sf::Vector2f(0, chatMessageText2.getCharacterSize() * 1.5f));
    chatMessageText2.setFont(myFont);
    chatMessageText2.setString(_chatMessages[2]);
    window.draw(chatMessageText2);

    sf::Text chatMessageText3;
    chatMessageText3.setCharacterSize(20);
    chatMessageText3.setPosition(chatMessageText2.getPosition() - sf::Vector2f(0, chatMessageText3.getCharacterSize() * 1.5f));
    chatMessageText3.setFont(myFont);
    chatMessageText3.setString(_chatMessages[1]);
    window.draw(chatMessageText3);

    sf::Text chatMessageText4;
    chatMessageText4.setCharacterSize(20);
    chatMessageText4.setPosition(chatMessageText3.getPosition() - sf::Vector2f(0, chatMessageText4.getCharacterSize() * 1.5f));
    chatMessageText4.setFont(myFont);
    chatMessageText4.setString(_chatMessages[0]);
    window.draw(chatMessageText4);
}
