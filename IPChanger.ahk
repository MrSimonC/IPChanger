global version := "1.0"

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

;===Customised Settings===
#SingleInstance force		;stops complaint message when reloading this file

; run as admin
full_command_line := DllCall("GetCommandLine", "str")

if not (A_IsAdmin or RegExMatch(full_command_line, " /restart(?!\S)"))
{
    try
    {
        if A_IsCompiled
            Run *RunAs "%A_ScriptFullPath%" /restart
        else
            Run *RunAs "%A_AhkPath%" /restart "%A_ScriptFullPath%"
    }
    ExitApp
}

; Menu
Menu, Tray, add, &Go DHCP, godhcp
Menu, Tray, add, &Go Static, gostatic
Menu, Tray, Add, E&xit, ^+Esc
Menu, Tray, NoStandard	;Remove the standard complied hotkey menus: "Exit, Suspend Hotkeys, Pause Script"
Menu, Tray, Tip, IP Changer: Version %version%

; Script Control
^+Esc::ExitApp	;kills application dead when pressing Ctrl+Esc. Note: This line will stop any auto-exec code underneath.
^Esc::	;Reload the script / kill it if there is a problem
	Reload
	Sleep 1000 ;if successful, Reload will close this instance during the Sleep, so the line below will never be reached.
	ExitApp
Return

;=====================

godhcp:
	output := RunWaitMany("
	(
	netsh interface ip set address Ethernet dhcp
	netsh interface ip set dns Ethernet dhcp
	)")
	output := RegexReplace(output, "\R")  ; replace enters
	If (output != "")
		MsgBox % "Tried. Output was:`r`n" . output
	Else
	{
		TrayTipShow("DHCP Active")
	}
return

gostatic:
	If (InStr(A_IPAddress1, "192"))
		ip := A_IPAddress1
	Else If (InStr(A_IPAddress2, "192"))
		ip := A_IPAddress2
	If (InStr(A_IPAddress3, "192"))
		ip := A_IPAddress3
	Else If (InStr(A_IPAddress4, "192"))
		ip := A_IPAddress4
	output := RunWaitMany("
	(
	netsh interface ip set dns name=Ethernet static 192.168.101.123
	netsh interface ip add dns name=Ethernet 192.168.101.109 index=2
	netsh interface ip set address name=Ethernet static " ip " 255.255.255.0 192.168.101.253
	)")
	output := RegexReplace(output, "\R")  ; replace enters
	If (output != "")
		MsgBox % "Tried. Output was:`r`n" . output
	Else
	{
		TrayTipShow("Static IP Active on " . ip)
	}
return

TrayTipShow(message) {
    TrayTip, %message%, %message%
	Sleep 3000
	TrayTip  ; Attempt to hide it the normal way.
    if SubStr(A_OSVersion,1,3) = "10." {
        Menu Tray, NoIcon
        Sleep 200
        Menu Tray, Icon
    }
}

RunWaitMany(commands) {
    shell := ComObjCreate("WScript.Shell")
    ; Open cmd.exe with echoing of commands disabled
    exec := shell.Exec(ComSpec " /Q /K echo off")
    ; Send the commands to execute, separated by newline
    exec.StdIn.WriteLine(commands "`nexit")  ; Always exit at the end!
    ; Read and return the output of all commands
    return exec.StdOut.ReadAll()
}