#ifndef PLAYER_H
#define PLAYER_H

#include <SFML/Graphics.hpp>
#include <sstream>

// The three possible states the player can be in
enum PlayerState
{
    Idle = 0,
    WaitingForChallengeResponse = 1,
    InChallenge = 2
};

class Player
{
    public:
        Player();


        void ChangeState(PlayerState state);

        // Takes keyboard input to move the player
        // Note that the player cannot move off screen.
        // Players may collide with each other, this is a design decision as there may be
        // many players. The player is rendered on top at all times so you will always see yourself.
        sf::Vector2f HandleInput(const int screenWidth, const int screenHeight);

        bool CheckCollision(const sf::CircleShape& a, const sf::CircleShape& b);

        // Renders the shape with the player's name on it
        void Render(sf::RenderWindow& window, sf::Font& myFont);
        void RenderScore(sf::RenderWindow& window, sf::Font& myFont, const int screenWidth);

        // Changes the shape so that the user can see themselves easier
        void SetAsLocalPlayer();

        // Getters
        inline PlayerState GetState() const { return _currentState; };

    public:
        int score = 0;
        std::string name;
        sf::CircleShape shape;
        std::string currentOpponent;
        int currentChoice = 0; // Rock = 0, Paper = 1, Scissors = 2
        bool choiceLocked = false;

    private:
       PlayerState _currentState = PlayerState::Idle;


};

#endif // PLAYER_H
