tell application "System Preferences"
activate
	tell application "System Events"
		delay 1
		set value of slider 1 of group 1 of tab group 1 of window 1 of process "System Preferences" to 0
		
	end tell
quit