set inputFile to choose file with prompt "Select the input text file:" of type {"public.text"}
tell application "Finder"
	-- set pathFile to selection as text
	set pathFile to get POSIX path of pathFile
	set the clipboard to pathFile
end tell
