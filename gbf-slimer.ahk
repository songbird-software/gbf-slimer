;============================================================================= Init
#Include libraries/Gdip_ImageSearch.ahk
#Include libraries/Gdip_All.ahk
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#SingleInstance Force
#InstallKeybdHook
SendMode Input
DetectHiddenWindows, On
SetKeyDelay , 50, 30,    ; 50ms is the default delay between presses, 30ms is the press length
Process, Priority,, High
CoordMode, Pixel, Window
CoordMode, Mouse, Window

;============================================================================= Globals
global millisPerHour := 3600000
global log_error := "ERROR"
global log_info := "INFO"

;these are an unfortunate limitation of searching by image, if you want a different size window, you will likely need to replace all of the images in the image folder, i wish you luck
global windowForceWidth := 549
global windowForceHeight := 1015

;============================================================================= User Config
global enableCheats                 := false                 ;whether to enable functionality that could be considered cheating, like automatically refilling AP or infinite quest time
global addSupportSummonFriend 		:= false 				;whether to add players as friends whose support summon you used
global errorLogging			        := false					;whether you want error messages to be logged, useful for debugging
global skipWhileNotChecks           := false                ;skips while loops that wait until a button is available, useful for debugging failed image searches later in the script without restarting the quest

;============================================================================= Code

if !A_IsAdmin
{
	Run *RunAs "%A_ScriptFullPath%"
	ExitApp
}

Exit

WriteLog(text, logLevel) {
    if (errorLogging) {
        logFileName := Format("logs\{1}-{2}-{3}-logfile.txt", A_YYYY, A_MM, A_DD)
        if (logLevel) {
            FileAppend, % Format("{1}: {2}: {3}`n", A_Now, logLevel, text), %logFileName%
        } else {
            FileAppend, % Format("{1}: {2}`n", A_Now, text), %logFileName%
        }
    }
    return
}

StartScriptTimer(timeToRunHours) {
    timeToRunMillis := 0
    if (!(enableCheats) AND timeToRunHours > 4) {
        WriteLog("User options set to disable cheats, timer is over four hours, defaulting to four hours", log_info)
        timeToRunMillis := 4 * millisPerHour
    } else if (enableCheats AND timeToRunHours > 2000000000) {
        WriteLog("User options set to enable cheats, timer is at risk of overflowing signed integer buffer, defaulting to 2 billion hours", log_info)
        timeToRunMillis := 2000000000 * millisPerHour
    } else if (timeToRunHours <= 0) {
        WriteLog("User input was less than zero, exiting app", log_error)
        ExitApp
    } else {
        timeToRunMillis := timeToRunHours * millisPerHour
    }

    WriteLog("Starting timer with millis: " . timeToRunMillis, log_info)
    SetTimer, AutoQuestDuration, %timeToRunMillis%
    return
}

;there is an additional error display flag here, because sometimes we check for an image and expect it to be missing, or because we're looping over the search until we find the image
ImageSearchWrapper(byref foundCoords, winHandle, x1Search, x2Search, y1Search, y2Search, logError, imageFileName) {
    gdipToken := Gdip_Startup()
    imageFileLocation := "images/" . imageFileName

    bmpHaystack := Gdip_BitmapFromHWND(winHandle)
    bmpNeedle := Gdip_CreateBitmapFromFile(imageFileLocation)

    returnValue := Gdip_ImageSearch(byref bmpHaystack, byref bmpNeedle, foundCoords, x1Search, y1Search, x2Search, y2Search, 20)

    ;if the return value from gdip is less than zero then something went wrong
	if (returnValue < 0) {
		WriteLog("Something went wrong with image search", log_error)
        ShutdownGdip(bmpHaystack, bmpNeedle, gdipToken)
		return false
	}
    ;if return value is zero then we found no instances of the image
	else if (returnValue = 0) {
		Sleep, 500

        ;retry with higher variation allowance
        if (logError) {
            WriteLog(Format("Retry finding image {1}. Search area (x1 y1 x2 y2): {2} {3} {4} {5}", imageFileName, x1Search, y1Search, x2Search, y2Search), log_error)
        }
		returnValue := Gdip_ImageSearch(bmpHaystack, bmpNeedle, foundCoords, x1Search, y1Search, x2Search, y2Search, 40)

		if (returnValue = 0) {
            if (logError) {
                WriteLog(Format("Error finding image {1}. Search area (x1,y1,x2,y2): {2},{3},{4},{5}", imageFileName, x1Search, y1Search, x2Search, y2Search), log_error)
            }
            ShutdownGdip(bmpHaystack, bmpNeedle, gdipToken)
			return false
		}
	}
    WriteLog(Format("Found image {1}, at coords: {2}", imageFileName, foundCoords), log_info)
    ShutdownGdip(bmpHaystack, bmpNeedle, gdipToken)
	return true
}

ShutdownGdip(byref bmpHaystack, byref bmpNeedle, byref gdipToken) {
    Gdip_DisposeImage(bmpHaystack)
    Gdip_DisposeImage(bmpNeedle)
    Gdip_Shutdown(gdipToken)
    return true
}

ClickHandler(clickCoords, sleepTime, winID) {
	;take our image search result and add 5 to each coord since the original result is the top left corner
    splitCoords := StrSplit(clickCoords, ",")
    modifiedX := splitCoords[1] + 5
	modifiedY := splitCoords[2] + 5
	coordInput := "X" . modifiedX . " Y" . modifiedY
	SetControlDelay -1
	ControlClick, %coordInput%, ahk_id %winID%, , , , NA
    WriteLog("Clicking at coords: " . coordInput, log_info)
	if (ErrorLevel) {
		Sleep, 1000
		ControlClick, %coordInput%, ahk_id %winID%, , , , NA
	}

	Sleep, %sleepTime%
}


F1::
    winID := WinExist("A")
    WinGetActiveStats, winTitle, winWidth, winHeight, winXPos, winYPos
    WinMove, ahk_id %winID%, , winXPos, winYPos, windowForceWidth, windowForceHeight

    if (errorLogging) {
        FileCreateDir, logs
    }

	foundCoords := 0
	winWidth := 0
	winHeight := 0
	WinGetActiveStats, winTitle, winWidth, winHeight, winXPos, winYPos
	ToolTip % winID, 0, 0 ; Displays a windowID in top left, put a semicolon in front of this line to disable
    timeToRunMillis := 0

    WriteLog("=============================================================================", "")
    WriteLog(Format("Window width: {1}, window height: {2}", winWidth, winHeight), log_info)
	
	;-------- Frequently used computations
	halfWinWidth := winWidth // 2
	halfWinHeight := winHeight // 2	
	tenthWinWidth := winWidth // 10
	tenthWinHeight := winHeight //10

    ;get script run duration
    InputBox, timeToRunHours, "Autorun Duration", "Enter Number Of Hours To Run (decimals ok)", , , , , , Locale, 3600, 1
    if (timeToRunHours is not number) {
        WriteLog("Input was not a number, exiting app", log_error)
        ExitApp
    } else {
        WriteLog("Took timer input of hours: " . timeToRunHours, log_info)
        StartScriptTimer(timeToRunHours)
    }
    Sleep 500

	Loop
	{
		;vyrn and his element picker take up about a third of the screen, so the first available summon should be in the top right quadrant of the screen
		ImageSearchWrapper(foundCoords, winID, halfWinWidth, winWidth, halfWinHeight-tenthWinHeight, halfWinHeight+tenthWinHeight, true, "support_summon_arrow.png")
		ClickHandler(foundCoords, 2000, winID)

		;click OK in the bottom right quadrant of screen
		ImageSearchWrapper(foundCoords, winID, halfWinWidth, winWidth, winHeight//3, winHeight, true, "ok.png")
		ClickHandler(foundCoords, 2000, winID)

        ;wait for quest to load, this is on a while loop because of variations in connection speed and system power
        while (!(skipWhileNotChecks) AND !(ImageSearchWrapper(foundCoords, winID, halfWinWidth, winWidth, halfWinHeight-tenthWinHeight, halfWinHeight+tenthWinHeight, false, "attack.png"))) {
            Sleep, 2000
        }

		;first check if charge animation is on, turn it off if it is on
		if (ImageSearchWrapper(foundCoords, winID, halfWinWidth, winWidth, winHeight//3, winHeight, false, "charge_anim_on.png")) {
			ClickHandler(foundCoords, 2000, winID)
		}

		;check if auto charge is on, turn it on if it is off
		if (ImageSearchWrapper(foundCoords, winID, halfWinWidth, winWidth, winHeight//3, winHeight, false, "charge_hold.png")) {
			ClickHandler(foundCoords, 2000, winID)
		}

		;click Attack in middle of right half, basic height math here to search a center percentage of the y axis
		ImageSearchWrapper(foundCoords, winID, halfWinWidth, winWidth, halfWinHeight-tenthWinHeight, halfWinHeight+tenthWinHeight, true, "attack.png")
		ClickHandler(foundCoords, 2000, winID)

		;click Semi auto, same maths as above but on the left half of screen, then wait for duration of quest
        ;idk why the script has such a hard time finding this one, but that's why its on a loop until it does find it
		while(!(skipWhileNotChecks) AND !(ImageSearchWrapper(foundCoords, winID, 0, halfWinWidth, halfWinHeight-tenthWinHeight, halfWinHeight+tenthWinHeight, false, "semi_repeat.png"))) {
            Sleep, 500
        }
		ClickHandler(foundCoords, 100, winID)

        ;loop and wait until the quest finishes
		while (!(skipWhileNotChecks) AND !(ImageSearchWrapper(foundCoords, winID, 0, winWidth, 0, tenthWinHeight*2, false, "quest_results.png"))) {
			Sleep, 3000
		}
        Sleep, 500

		;click OK in the bottom half of screen for quest results
		ImageSearchWrapper(foundCoords, winID, 0, winWidth, halfWinHeight, winHeight, true, "ok2.png")
		ClickHandler(foundCoords, 1000, winID)

		;click middle of screen to skip exp bar animation
		ClickHandler((halfWinWidth . "," . halfWinHeight), 2000, winID)

		;check to see if we have rank up notification, click ok if we do
		if (ImageSearchWrapper(foundCoords, winID, 0, winWidth, 0, halfWinHeight, false, "rank_up.png")) {
            ImageSearchWrapper(foundCoords, winID, 0, winWidth, halfWinHeight, winHeight, true, "rank_up_ok.png")
			ClickHandler(foundCoords, 2000, winID)
		}

        ;check to see if we have player emp level up notifications, click ok if we do
		if (ImageSearchWrapper(foundCoords, winID, 0, winWidth, 0, halfWinHeight, false, "emp_level_up.png")) {
            ImageSearchWrapper(foundCoords, winID, 0, winWidth, halfWinHeight, winHeight, true, "emp_level_up_ok.png")
			ClickHandler(foundCoords, 2000, winID)
		}

		;check to see if we have party member EMP level up notifications, click through them if we do
		while ImageSearchWrapper(foundCoords, winID, halfWinWidth-tenthWinWidth, halfWinWidth+tenthWinWidth, halfWinHeight-tenthWinHeight, halfWinHeight+tenthWinHeight, false, "emp_up.png") {
			ClickHandler(foundCoords, 3000, winID)
		}

		;click play again, center vertical, left half
		ImageSearchWrapper(foundCoords, winID, 0, halfWinWidth, halfWinHeight-tenthWinHeight, halfWinHeight+tenthWinHeight, true, "play_again.png")
		ClickHandler(foundCoords, 2000, winID)

        ;check to see if we have trophy notifications, click close if we do
		if (ImageSearchWrapper(foundCoords, winID, 0, winWidth, 0, halfWinHeight, false, "trophy_achieved.png")) {
            ImageSearchWrapper(foundCoords, winID, 0, winWidth, halfWinHeight, winHeight, true, "close.png")
			ClickHandler(foundCoords, 2000, winID)
		}

        ;check for skyscope mission notifications, click close if we do
        if (ImageSearchWrapper(foundCoords, winID, 0, winWidth, 0, halfWinHeight, false, "skyscope.png")) {
            ImageSearchWrapper(foundCoords, winID, 0, winWidth, halfWinHeight, winHeight, true, "skyscope_close.png")
			ClickHandler(foundCoords, 2000, winID)
        }

		;check for friend request prompt
		if (ImageSearchWrapper(foundCoords, winID, 0, winWidth, 0, halfWinHeight, false, "friend.png")) {
			if (addSupportSummonFriend) {
                WriteLog("User options set to add friend, adding new friend", log_info)
				ImageSearchWrapper(foundCoords, winID, halfWinWidth, winWidth, halfWinHeight, winHeight, true, "friend_ok.png")
				ClickHandler(foundCoords, 2000, winID)

				ImageSearchWrapper(foundCoords, winID, 0, winWidth, halfWinHeight, winHeight, true, "friend_ok2.png")
				ClickHandler(foundCoords, 2000, winID)

			} else {
                WriteLog("User options set to skip adding new friends, skipping new friend", log_info)
				ImageSearchWrapper(foundCoords, winID, 0, halfWinWidth, halfWinHeight, winHeight, true, "friend_cancel.png")
				ClickHandler(foundCoords, 2000, winID)
			}
		}

        ;check if out of AP
        if (ImageSearchWrapper(foundCoords, winID, 0, winWidth, 0, halfWinHeight, false, "no_ap.png")) {
            if (enableCheats) {
                WriteLog("User options set to enable cheats, user is out of AP, refilling AP", log_info)
                ImageSearchWrapper(foundCoords, winID, halfWinWidth, winWidth, halfWinHeight-tenthWinHeight, halfWinHeight+halfWinHeight//2, true, "dropdown_selector.png")
                ClickHandler(foundCoords, 1000, winID)

                ;five page down inputs will max out AP to 999
                index := 1
                while (index <= 5) {
                    ControlSend, , {PgDn}, ahk_id %winID%
                    index++
                    Sleep, 50
                }

                ImageSearchWrapper(foundCoords, winID, halfWinWidth, winWidth, halfWinHeight, winHeight, true, "use_elixir.png")
                ClickHandler(foundCoords, 2000, winID)

                ImageSearchWrapper(foundCoords, winID, 0, winWidth, halfWinHeight, halfWinHeight+halfWinWidth, true, "elixir_ok.png")
                ClickHandler(foundCoords, 1000, winID)
            } else {
                WriteLog("User options set to disable cheats, user is out of AP, exiting app", log_info)
                ExitApp
            }
        }

        Sleep, 3000
	}	
	
return

F2::Pause,Toggle

F3::ExitApp

AutoQuestDuration:
WriteLog("AutoQuestDuration timer expired, exiting app", log_info)
ExitApp