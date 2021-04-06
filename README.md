# tic-80-stuff
TIC-80 games and experiments

## Games
- MOVEIT: Move-It, Man!  A Sokoban clone based on a DOS CGA mode game I made a couple years ago

## Comments
All games are fully commented.  When copied to the TIC-80 cart directory using repo_to_cart_dir.bat, the informative comments will all be removed to save code space.

## Workflow
The workflow I use is to only edit graphics and sound data in TIC-80, and only update code in an external editor (note that my setup requires TIC-80 Pro to do since carts are saved as Lua files). To facilitate this, there are two scripts in the _tools directory that can be used to move files around:

- cart_dir_to_repo.bat - copies the graphics data from the TIC-80 copy of the specified game into the source copy of the game
- repo_to_cart_dir.bat - strips all informative comments from the Lua file and copies the resulting file to the TIC-80 cart directory

So, my work will generally consist of making changes in my editor, sending the script back to the cart directory, test, repeat.  If I have to make changes to the graphics, I just send the updated script back from the cart directory to the repo, which keeps the annotated code and updated graphics together. **Note**: This setup doesn't copy changed *code* back from the cart directory to the repo, but that's acceptable - I only make code changes from an external editor anyway.  Just an FYI.

## License
All code is licensed under the MIT License.  See LICENSE for the license text.


