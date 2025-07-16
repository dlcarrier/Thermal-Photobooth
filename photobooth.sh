#Single devices often have multiple outputs, so if video0 is not desired, the next device may be video2 or higher
capture_device=/dev/video0
resolutions=("1024x576" "1280x720" "1920x1080" "2560x1440")
capture_resolution=2
update_image=1
current_tty=$(tty)
background_pid=null
rm /tmp/gray.png 2> /dev/null
rm /tmp/preview.png 2> /dev/null
rm /tmp/monochrome.png 2> /dev/null

wait_for_button_release () {
	while [ 1 ]; do
		read -n 256 -t 0.5 -s key
		if  [[ $key == "" ]]; then
			break
		fi			
	done
}

launch_webcam () {
	if [[ $background_pid -ne "null" ]]; then
		kill $background_pid
		sleep 1 #Wait for background_pid to release capture_device
	fi
	while [ 1 ]; do
		if [[ $update_image == 1 ]]; then
			fswebcam -q -d $capture_device -r ${resolutions[$capture_resolution]} --crop 576x576 --greyscale --no-banner --png 0 /tmp/gray.png
			convert /tmp/gray.png -flop -remap pattern:gray50 /tmp/preview.png > /dev/null &
			if [[ $XDG_SESSION_TYPE == "tty" ]]; then
				read WIDTH HEIGHT DEPTH < <(fbset | awk '/geometry/ { print $2, $3, $6 }')
				ffmpeg -loglevel error -i /tmp/preview.png -vf "scale=w=${WIDTH}:h=${HEIGHT}:force_original_aspect_ratio=decrease,pad=${WIDTH}:${HEIGHT}:(ow-iw)/2:(oh-ih)/2:color=black" -f rawvideo -pix_fmt bgra -y /dev/fb0 &
			fi
		fi
	done &
	background_pid=$!
	case $XDG_SESSION_TYPE in
		"x11")
			trap "stty echo ; kill $feh_pid ; kill $background_pid" EXIT
			;;
		"tty")
			trap "stty echo ; kill $background_pid 2> /dev/null" EXIT
			;;
	esac
}

#Take initial set of images before launching webcam process
fswebcam -d /$capture_device -r ${resolutions[$capture_resolution]} --crop 576x576 --greyscale --no-banner --png 0 /tmp/gray.png 2> /dev/null
convert /tmp/gray.png -flop -remap pattern:gray50 /tmp/preview.png
launch_webcam

case $XDG_SESSION_TYPE in
	"x11")	#Using x11 only works if inotify is working on your computer /and/ the installed version of feh supports it
		terminal_window=$(xdotool getactivewindow)
		feh --zoom 200 --auto-reload --force-aliasing /tmp/preview.png 2> /dev/null &
		feh_pid=$!
		stty -echo
		trap "stty echo ; kill $feh_pid ; kill $background_pid" EXIT
		;;
	"tty")	#Expects 1920x1080 resolution
		stty -echo
		trap "stty echo ; kill $background_pid 2> /dev/null" EXIT
		;;
	*)
		echo Requires a vtty or x11 with inotify
		exit
		;;
esac

while [ 1 ]; do
	#Capture focus and test for key presses
	if [[ $XDG_SESSION_TYPE == "x11" ]]; then
		xdotool windowfocus $terminal_window
	fi
	read -n 1 -s -t 1 key
	case "${key:0:1}" in
		"q")	#Quit
			exit
			;;
		"0")	#Print
			echo Printing -----------------------------------------------
			convert /tmp/gray.png -remap pattern:gray50 /tmp/monochrome.png > /dev/null
			#{lpr /tmp/monochrome.png}
			wait_for_button_release
			;;
		"+")	#Reprint
			echo Reprinting -----------------------------------------------
			#{lpr /tmp/monochrome.png}
			wait_for_button_release
			;;
		"5")	#Revert to default zoom
			capture_resolution=2
			launch_webcam
			;;
		"/")	#Zoom out
			if [[ $update_image == 1 ]]; then
				if [[ capture_resolution -gt 0 ]]; then
					((capture_resolution-=1))
					launch_webcam
				fi
			fi
			;;
		"*")	#Zoom in
			if [[ $update_image == 1 ]]; then
				if [[ capture_resolution -lt 3 ]]; then
					((capture_resolution+=1))
					launch_webcam
				fi
			fi
			;;
	esac

done
