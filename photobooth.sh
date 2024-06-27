#Single devices often have multiple outputs, so if video0 is not desired, the next device may be video2 or higher
capture_device=/dev/video0
resolutions=("1024x576" "1280x720" "1920x1080" "2560x1440") 
capture_resolution=2 
 
terminal_window=$(xdotool getactivewindow)  
rm /tmp/gray.png 2> /dev/null 
rm /tmp/preview.png 2> /dev/null 
rm /tmp/monochrome.png 2> /dev/null 
 
fswebcam -d /$capture_device -r ${resolutions[$capture_resolution]} --crop 576x576 --greyscale --no-banner --png 0 /tmp/gray.png 2> /dev/null 
convert /tmp/gray.png -flop -remap pattern:gray50 /tmp/preview.png 

#This only updates if inotify is working on your computer /and/ the installed version of feh supports it
feh -F --zoom 250 --auto-reload --force-aliasing /tmp/preview.png 2> /dev/null &

feh_pid=$!
update_image=1 
xdotool windowfocus $terminal_window 
trap "kill $feh_pid 2> /dev/null" EXIT 

#while kill -s 0 $feh_pid 2> /dev/null; do 
while [ 1 ]; do 
	fswebcam -d $capture_device -r ${resolutions[$capture_resolution]} --crop 576x576 --greyscale --no-banner --png 0 /tmp/gray.png
	convert /tmp/gray.png -flop -remap pattern:gray50 /tmp/preview.png > /dev/null  
 
	#Capture focus and test for key presses 
	xdotool windowfocus $terminal_window 
	read -n 1 -t 0.5 -s key 
	if [[ $? -eq 0 ]]; then 
		if [[ $key == "q" ]]; then #close Feh and exit 
			kill $feh_pid 2> /dev/null 
			exit 
		fi 
		if [[ $key == 0 ]] || [[ $key == "" ]]; then #stop reading the camera input 
			convert /tmp/gray.png -remap pattern:gray50 /tmp/monochrome.png > /dev/null
			lpr /tmp/monochrome.png 
		fi 
		if [[ $key == "+" ]]; then # reprint
			lpr /tmp/monochrome.png 
		fi 
		if [[ $key == "5" ]]; then #  
			capture_resolution=2 
		fi 
		if [[ $update_image == 1 ]]; then 
			if [[ $key == "/" ]]; then 
				if [[ capture_resolution -gt 0 ]]; then 
					((capture_resolution-=1)) 
				fi 
			fi 
			if [[ $key == "*" ]]; then 
				if [[ capture_resolution -lt 3 ]]; then 
					((capture_resolution+=1)) 
				fi 
			fi 
		fi 
	fi 
done 
