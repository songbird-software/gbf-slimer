# gbf-slimer
An AHK newbie's solution to Granblue Fantasy's lack of a quest repeat

## About
Granblue Fantasy has been out for ten years now, and we still don't have an auto-repeat for simple quests like slimes.

Some people say its because the developers can't figure out how to make it work without setting the servers on fire, but noone seems to really know the real reason.
I got tired of my journey drops going to waste because I can't babysit a mobile game and press simple buttons like a monkey for several hours, so I made this project.

This project is currently aimed at English desktop users of GBF with a 1920x1080 or higher resolution playing on Bluestacks.
The 1920x1080 minimum requirement (as well as the English requirement) is entirely due to the usage of image search techniques in this script (thanks to MasterFocus and the rest of the GDIP team),
which is not being supported by supersampling or resize interpolation.

### What This Script Will Do
By default, this script will:
- Accept an input of hours to run, between 0 and 4, with decimals accepted
- Resize the Bluestacks window to the appropriate resolution
- Pick the first available support summon
- Start the quest
- Turn on auto use of charge-attack/SBA/ougi
- Turn off charge-attack/SBA/ougi animations
- Enable semi-auto battle mode
- Close quest results
- Close rank up notifications
- Close Gran/Djeeta EMP level up notifications
- Close party member EMP level up notifications
- Add the support summon player as a friend (if they were not already a friend)
- Close Skyscope quest notifications
- Close achievement notifications
- Restart the quest

This script is also capable of running with the client window unfocused, without interfering with normal mouse and keyboard input.

This is the baseline limit of the script, because my own intention for this script is not to completely remove any grind from the game.
I just want my journey drops to stop going to waste because I got distracted or had to take care of something.

That being said, for completeness I have included the following functionality.
It can also:
- Run for up to 2 billion hours (any more and signed integer storage overflows when calculating milliseconds)
- Auto-refill your AP when empty using half-elixirs

These functions are disabled by default since I consider them to be cheats, but you are free to enable them at your own discretion.

## Instructions
Usage is pretty straightforward:
1. Ensure you have AutoHotkey and Bluestacks installed
2. Install GBF on Bluestacks via QooApp or some other way
3. Download the gbf-slimer repository
4. Start GBF on Bluestacks and navigate to the quest you want to farm
5. Start the gbf-slimer.ahk script as administrator (if you start the script normally it will ask you for admin privileges)
6. ***Make sure you're on the support summon screen and Bluestacks is your active window***
7. Press `F1` to start the script
8. Type in how many hours you want the script to run, or how many hours your journey drop buffs will last (default is one hour, floating point decimals are accepted for partial hours)
9. You're already farming!
10. Use `F2` to pause the script and `F3` to shutdown the script
11. The script will auto shutdown after the input duration has elapsed, or once you have run out of AP (if cheats are disabled)

## Configuration
This script offers a handful of customizable feature flags near the top of the script file.
To change them, open the script file with any text editor and look for the section labeled "User Config". All of the flags are boolean, their values should only be set to true or false.
- enableCheats           --- This will enable/disable the additional functionality for unlimited quest time and automatic AP refill
- addSupportSummonFriend --- This will enable/disable whether the script will automatically add players as friends whose support summons you've used. True will send a friend request, false will skip sending a request.
- errorLogging           --- This will enable/disable logging to file. By default, logs are created in the "logs" subfolder. New log files are started on a day to day basis to prevent unmanageable log file size.
- skipWhileNotChecks     --- This will enable/disable the looping checks that wait until a button is available. This is a debug feature intended to skip image checks that we know to be functional in order to skip to other image checks that might be failing.

## Known Limitations
- 1920x1080 minimum resolution requirement: This is because this script uses image search to detect the presence of buttons and popups. Realistically you just need a display that can do 1015 pixels vertically, since I took the image samples with a client size of 549x1015.
- English client: Again, this is due to image searching. I play on an English client and so the image samples contain English text.
- System resources/connection speed: While I've tried to make this script as flexible as possible, some of the code still operates on timers and doesn't always handle delays in client rendering well. Resource-starved clients or slow connection speeds may require some of the timers to be adjusted.

## Feedback
Feedback and bug reports are welcome, and I will be making updates when possible, but please understand that this was a fun side project for me and that I don't have any time dedicated to the maintenance of this script.  If you like this script and want to modify it for your language, I'm happy to provide assistance. I have done my best to make the code as readable as possible, and left plenty of comments to ensure the script is well-documented, so if you do have to make changes, it will hopefully be fairly easy.

## Credits
tariqporter and mmikeww (and any others not listed as contributors) for their work on GDIP. MasterFocus, for their work on using GDIP as an image search tool. Without these libraries the project would be significantly less robust.
