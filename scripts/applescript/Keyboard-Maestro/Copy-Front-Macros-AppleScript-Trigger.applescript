use scripting additions
tell application \"Keyboard Maestro Engine\"
	do script \"" & uid & "\"
	-- or: do script \"" & uid & "\" with parameter \"Whatever\"
end tell
-- end ignoring"