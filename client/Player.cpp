#include "Player.h"

Player::Player()
{
    shape = sf::CircleShape(50.0f);
    shape.setFillColor(sf::Color::Green);
}


void Player::SetAsLocalPlayer()
{
    shape.setOutlineThickness(2.0f);
    shape.setOutlineColor(sf::Color::White);
}

sf::Vector2f Player::HandleInput(const int screenWidth, const int screenHeight)
{
    // Movement
    sf::Vector2f offset(0,0);

    // Note - Cannot move off screen

    if(sf::Keyboard::isKeyPressed(sf::Keyboard::A) && shape.getPosition().x > 0)
        offset.x--;

    if(sf::Keyboard::isKeyPressed(sf::Keyboard::D) && shape.getPosition().x + (2.0f *shape.getRadius()) < screenWidth)
        offset.x++;

    if(sf::Keyboard::isKeyPressed(sf::Keyboard::W) && shape.getPosition().y > 0)
        offset.y--;

    if(sf::Keyboard::isKeyPressed(sf::Keyboard::S) && shape.getPosition().y + (2.0f *shape.getRadius()) < screenHeight)
        offset.y++;

    // only move if necessary
    if(offset != sf::Vector2f(0,0))
        shape.move(offset);

    return offset;
}

void Player::Render(sf::RenderWindow& window, sf::Font& myFont)
{
    window.draw(shape);

    // Draw the player's name on their circle
    sf::Text playerNameText;
    playerNameText.setString(name);
    playerNameText.setCharacterSize(20);
    playerNameText.setPosition(shape.getPosition()
                               + sf::Vector2f(shape.getRadius() / 2.0f, shape.getRadius() / 2.0f)
                               - sf::Vector2f(name.length() , 0.0f));
    playerNameText.setFont(myFont);

    // White on Black so it can be seen no matter the colours behind the text
    playerNameText.setColor(sf::Color::White);
    //playerNameText.setOutlineColor(sf::Color::Black);
   // playerNameText.setOutlineThickness(1.0f);

    window.draw(playerNameText);
}

void Player::RenderScore(sf::RenderWindow& window, sf::Font& myFont, const int screenWidth)
{
    // Render the score at the top of the screen
    sf::Text scoreText;
    scoreText.setCharacterSize(35);
    scoreText.setPosition(screenWidth / 2.0f, 0);
    scoreText.setFont(myFont);

    // Convert int to string
    std::ostringstream ssScore;
    ssScore << score;

    scoreText.setString(ssScore.str());
    scoreText.setColor(sf::Color::White);

    window.draw(scoreText);
}

bool Player::CheckCollision(const sf::CircleShape& a, const sf::CircleShape& b)
{
    // http://cgp.wikidot.com/circle-to-circle-collision-detection
    sf::Vector2f aPos = a.getPosition();

    int x1 = aPos.x;
    int y1 = aPos.y;
    int radius1 = a.getRadius();

    sf::Vector2f bPos = b.getPosition();

    int x2 = bPos.x;
    int y2 = bPos.y;
    int radius2 = b.getRadius();

    int dx = x2 - x1;
    int dy = y2 - y1;
    int radii = radius1 + radius2;

    return (dx * dx) + (dy * dy) < (radii * radii);
}

void Player::ChangeState(PlayerState state)
{
    // Changes the colour to the corresponding colour and sets the state.
    // Green - Idle
    // Blue - Waiting for challenge
    // Red - In Challenge
    switch(_currentState)
    {
        case PlayerState::Idle:

            switch(state)
            {
                case PlayerState::Idle:
                    break;

                case PlayerState::WaitingForChallengeResponse:
                    shape.setFillColor(sf::Color::Blue);
                    break;

                case PlayerState::InChallenge:
                     shape.setFillColor(sf::Color::Red);
                    break;
            }
            break;

        case PlayerState::WaitingForChallengeResponse:

            switch(state)
            {
                case PlayerState::Idle:
                    shape.setFillColor(sf::Color::Green);
                    break;

                case PlayerState::WaitingForChallengeResponse:
                    break;

                case PlayerState::InChallenge:
                    shape.setFillColor(sf::Color::Red);
                    break;
            }
            break;

        case PlayerState::InChallenge:

            switch(state)
            {
                case PlayerState::Idle:
                    shape.setFillColor(sf::Color::Green);
                    break;

                case PlayerState::WaitingForChallengeResponse:
                    break;

                case PlayerState::InChallenge:
                    break;
            }

            break;
    }

    _currentState = state;
}
