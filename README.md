# godot-project-fall2025
A capstone project involving the development of a Tetris-inspired role-playing game (RPG). 

Technical Manual:
- This game is developed for Windows 10 and Windows 11 using Godot Engine 4.5.1.
- You control the Tetromino units positioned at the bottom of the board.
- Use the WASD keys to move and the Spacebar to rotate the selected shape.
- You can select any friendly shape to move it individually. To select a different friendly shape, left-click on it; doing so will automatically deselect the previously selected shape.
- The game is turn-based: after each of your moves, the enemy AI will also take a turn.
- When one of your shapes collides with an enemy shape, you can right-click to initiate combat. An attack panel will appear, displaying health values and options for light and heavy attacks.
- Each shape starts with 100 health points (HP).
- A Light Attack will defeat an enemy in four successful hits; a Heavy Attack will defeat an enemy in two successful hits.
- When you complete a level, you may click Restart to proceed to the next level, or Menu to return to the main menu.
- Each subsequent level introduces additional obstacle(s) in the middle of the board.
- The player is limited to 25 turns. If all 25 turns are used and the objective is not completed, the game ends in a loss.
- At any time during gameplay, you can press the Esc key to pause the game.

Installation Guide:
- Download the zipped file or GitHub's repository. Link is provided at the bottom of the Project Proposal document. 
- Extract the contents to a desired location on your Windows 10/11 system.
- Open the exe folder and run TetrisRPG.exe to start the game.
- You can view or edit the project’s scripts and assets using tools such as Godot Engine (view and edit), Visual Studio Code (view ONLY), or GitHub (view ONLY).
