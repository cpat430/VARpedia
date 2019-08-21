#!/bin/bash

# creates the directories to store the creations and production files
mkdir ./production 2> /dev/null
mkdir ./creations 2> /dev/null

# does not produce an error message if they already exist
touch ./production/output_text.txt
touch ./production/temp_audio.wav
touch ./production/temp_video.mp4

#menu function
menu() {

	echo "=============================================================="
	echo "Welcome to the Wiki-Speak Authoring Tool"
	echo "=============================================================="
	echo "Please select from one of the following options"
	echo "	1. (l)ist existing creations"
	echo "	2. (p)lay an existing creation"
	echo "	3. (d)elete an existing creation"
	echo "	4. (c)reate a new creation"
	echo "	5. (q)uit authoring tool"
	echo "Enter a selection [1/2/3/4/5]"
}

# function to sort sentences to have a number and printed per line
sort_sentences() {
	input=$1
	count=1
	
	# Displays the searched paragraph into numbered lines 
	IFS='.' read -ra sentences <<< "$input"    #Convert string to array

	#Print all names from array
	for i in "${sentences[@]}" ; 
	do	
		echo "$count $i"
		count=$(($count+1))
	done
}

#list function
list() {
	
	# counts the number of files (not directories) in the directory
	COUNT=`ls -l creations | grep -c '^-'`

	if [ $COUNT -le 0 ]  ; 
	then
		echo "Error: There are no existing files to list"
	else
		echo "There are a total of $COUNT creations created"
		echo "`ls -1 creations | sed -e 's/\..*$//'`"

	fi		
}

#delete function
delete() {
	if [ "$COUNT" -le 0 ] ;
	then 
		echo "There are no existing files to delete"		
		return
	else
		list
		echo "Which file would you like to delete? "
		read FILE
		FILE=./creations/$FILE.mp4

		if [ -e "$FILE" ] ;
		then 
			read -p "Are you sure you want to delete `basename $FILE `? [y/n] " delete
			
			if [[ "$delete" == [yY] ]] ;
			then 
				rm "$FILE" && echo "`basename $FILE` deleted"
			else
				echo "`basename $FILE` was not deleted"
			fi
		else 
			echo "`basename $FILE` does not exist"
			echo "Bad! Sending you back to menu "
		fi
	fi
}

# function to play the files
play() {

	list	
	
	COUNT=`ls -l creations | grep -c '^-'`

	if [ "$COUNT" -le 0 ] ;
	then
		echo "Exiting to main menu..." 
		return
	fi

	# checks to make sure the inputted name is valid and not pre-existing
	valid="n"
	while [[ "$valid" == [nN] ]] ;
	do
		# Take the input into play which corresponds to the name inputted
		read -p "Which creation would you like to play? " play

		# checks if the file exists
		if [ -e ./creations/$play.mp4 ] ;
		then
			valid="y"
		else 
			if [ "$play" == "" ] ;
			then
				echo "File name cannot be blank"
			else
				echo "`basename $play` doesn't exist, Please try again" 2> /dev/null
			fi
		fi
	done

	play=./creations/$play
	
	# plays the file
	ffplay -autoexit $play.mp4 &> /dev/null

}

# function to create the creations
create_creation() {	
	
	again="y"

	# Gets a valid wiki search 
	while [[ "$again" == [yY] ]] ;
	do
		read -p "What would you like to search from Wikipedia? " search

		output="$(wikit $search)"
		
		
		if [[ "$output" =~ ":^(" ]] ; # If a term is not found offer a new search of back to menu 
		then 
			echo "$search was not found."
			read -p "Would you like to search for another term? [y/n] " again

			if [[ "$again" != [yY] ]] ;
			then
				again="x"
			fi 
		else
			sort_sentences "$output"
			again="n"
		fi
	done

	# if they do not want to search for another term, returns to main menu
	if [[ "$again" == [xX] ]] ;
	then
		echo "Returning you to main menu. "
		return
	fi

	#====================================
	# Ask how many sentences to display

	read -p "How many sentences would you like to hear? " sentences

	output="$(echo $output | cut -d'.' -f 1-$sentences)"
	output="$output."

	echo "$output" > ./production/output_text.txt

	# save the espeak output to a temporary audio file (wav)
	espeak -f ./production/output_text.txt -w ./production/temp_audio.wav -s 130
	audio_length=`soxi -D ./production/temp_audio.wav`
	audio_length=`echo "$audio_length+1.5" | bc` # add an extra 1.5 seconds to avoid any abrupt finish

	#===================================
	# Ask for a name for the creation
	
	valid_name="n"
	while [[ $valid_name == [nN] ]] ;
	do
		read -p "What would you like to name your creation? " creation_name

		# check if the creation name exists
		creation_name=./creations/$creation_name.mp4
		
		if [ -e $creation_name ] || [ $creation_name == "" ] ;
		then
			echo "Sorry that name already exists, enter a unique name please "
		else	
			valid_name="y"
		fi
	done
	
	#===================================
	# Creates the video of the word + the audio clip

	ffmpeg -y -f lavfi -i color=c=blue:s=320x240:d=$audio_length -vf "drawtext=fontfile:fontsize=30: fontcolor=white:x=(w-text_w)/2:y=(h-text_h)/2:text='$search'" ./production/temp_video.mp4 2> /dev/null
	ffmpeg -i ./production/temp_video.mp4 -i ./production/temp_audio.wav -c:v copy -c:a aac -strict experimental $creation_name &> /dev/null
	echo "`basename $creation_name` has been created."
}

quit() {
	#if quit is called, then the program exits
	exit 1
}

main() {
	menu 

	# case statement to select between the different modes
	read -p "What would you like to do: " action

	case $action in

		[1] | [lL] | [lL][iI][sS][tT])
			list
		;;
		[2] | [pP] | [pP][lL][aA][yY])
			play
		;;
		[3] | [dD] | [dD][eE][lL])
			delete
		;;
		[4] | [cC] | [cC][rR][eE][aA][tT][eE])
			create_creation
		;;
		[5] | [qQ] | [qQ][uU][iI][tT] )
			quit
		;;
		*)
			echo "Please enter a valid value [1/2/3/4/5] "
		;;
	esac

		read -p "Please enter a key to go back to menu: " exit 
}

#==============================================================
#the actual script

# Automaton to run the main
while true;
do
	main
done


