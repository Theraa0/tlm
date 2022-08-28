#!/bin/bash
# Currently not allowed list names: "help", "manage", ("*.done") which works for now but probably wont with the restore function in place, ""
# TODO:
# check if the given arguments are valid
# - correct number of inputs
# - wether the input number is <= the length of the file
# - for 'swap' fix substrings
# - 'silent' flag
# - interactions with sublists

# CONFIG
path="/home/thera/Documents/Lists"

# Handle the input parameters
# offset is the number of modifiers to check
length=${#COMP_WORDS[@]}
inputArray=( "$@" )
offset=0
function sortInput {
	tmp=${inputArray[$offset]}
	firstCharacter=${tmp::1}
	if [[ "$firstCharacter" == "-" ]]
	then
		offset=$((offset+1))
		sortInput $@
	fi
}
sortInput $@
layer1=${inputArray[$offset+0]}
layer2=${inputArray[$offset+1]}
layer3=${inputArray[$offset+2]}
layer4=${inputArray[$offset+3]}

for (( i=0; i<$offset; i++ ))
do
	if [[ "${inputArray[$i]}" == "--silent" ]]
	then
		silent=True
	fi
done

# Function for sending the help message
function sendHelp {
	echo -e "tlm - Thera's List manager [version 1.¼]"
	echo -e "tlm is a bash script for creating and managing different lists, stored in a simple text file\nFor more detailed documentations, check the github page"
	echo -e "Usage: 	tlm [list] [command] [subject]\n	tlm help\n	tlm manage [add, remove, list]\n	------"
	echo -e "	[list] is the custom list\n	[command] is 'add', 'done', 'list', 'remove', 'replace' or 'swap'\n	[subject] is either the text to add or the needed element number"
	echo -e "	          you can use '=>' to point to a list when adding"
}

# Function to only echo when silent flag is not set
function sEcho {
	if ! [[ $silent ]] ; then echo -e $@; fi
}

# Commands for managing the different lists
function interact {
case $layer1 in
	"")
		sEcho "invalid use of command"
		sendHelp
		;;
	# Managing
	manage)
		case $layer2 in
			add)
				touch $path/$layer3
				sEcho "created list: $layer3"
				;;
			remove)
				if [[ $silent ]]
				then
					rm $path/$layer3 > /dev/null 2>&1
					rm $path/$layer3.done > /dev/null 2>&1
				else
					i=5
					echo -n "Remove list? [y/N] $i"
					while [ true ] ; do
						echo -e -n "\e[D$i"
						read -s -t 1 -n 1 k<&1
						((i=i-1))
						if [[ "$i" == "0" ]] || [[ "$k" == "n" ]] || [[ "$k" == "N" ]]
						then
							echo -e -n "\e[2K\e[0G"
							echo "No confirmation recieved, exiting."
							exit
						elif [[ "$k" == "y" ]] || [[ "$k" == "Y" ]]
						then
							rm $path/$layer3 > /dev/null 2>&1
							rm $path/$layer3.done > /dev/null 2>&1
							echo -e -n "\e[2K\e[0G"
							echo "removed list: $layer3"
							exit
						fi
					done
				fi
				;;
			list)
				pathContent=("$(ls $path)")
				no=$(ls $path | wc -w)
				for (( i=1; i<$no+1; i++ ))
				do
					echo $pathContent | cut -d " " -f $i
				done
				;;
			*)
				sEcho "invalid argument"
				;;
		esac
		;;
	# Help
	help)
		sendHelp
		;;
	*)
		list=$layer1
		commando=$layer2
		subject=$layer3
		subject2=$layer4
		if ! test -f "$path/$list";
		then
			sEcho "List: $list does not exist"
			exit
		fi

		case $commando in
			add)
				echo "$subject" >> $path/$list																#Append subject to list
				sEcho "added \"$subject\" to $list"														#Feedback
				;;
			done)
				sed -n "$subject"p $path/$list >> $path/$list.done						#Add subject to list.done
				sed -i $subject'd' $path/$list																#Remove subject
				sEcho "No.$subject from $list is done"												#Feedback
				;;
			list)
				norecursive=False																							#Check wether the "--no-recursive" Flag is set
				for (( i=0; i<$offset; i++ ))
				do
					if [[ "${inputArray[$i]}" == "--no-recursive" ]]
					then
						norecursive=True
					fi
				done
				for (( i=1; i<=$(wc -l < $path/$list); i++ ))									#For the number of lines in list do:
				do
					echo -n -e "\e[1;37m$i \e[0;37m"														#Echo number in bold white
					line=$(sed -n "$i"p $path/$list)														#Get single line from list
					if [[ "$line" == *"=>"* ]]																	#If a sublist link is found:
					then
						sublist=$(echo $line | sed 's/^[^=>]*=>//') 							#Cut everything before and including '=>'
						echo -n "$line" | sed 's/=>.*//' && echo ": ($sublist)" 	# Reformat for looks
						if [ $norecursive == False ]															#If "--no-recursive" Flag is not set do:
						then
							tlm --no-recursive $sublist list | sed -ne 's/.*/  &/p' #List the sublist and add inset per layer
						fi
					else
						echo $line																								#Echo the line
					fi
				done
				;;
			remove)
				sed -i $subject'd' $path/$list																#Remove the line
				sEcho "Removed No.$subject from $list"												#Feedback
				;;
			replace)
				sed -i "$subject d" $path/$list
				sed -i "$subject i $subject2" $path/$list
				sEcho "Changed No.$subject from $list to $subject2"
				;;
			swap)
				if (( $subject > $subject2 ))																																								#The larger number always has to be subject2
				then
					tempSubject=$subject
					subject=$subject2
					subject2=$tempSubject
				fi
				cat $path/$list | sed -r "$subject{:a;N;$subject2!ba;s/([^\n]*)(\n?.*\n)(.*)/\3\2\1/}" > $path/$list.swap		#Swap lines using sed and echo them into a new file
				mv $path/$list.swap $path/$list																																							#Move the new file over the old file
				sEcho "Swapped No.$subject and No.$subject2 from $list"																											#Feedback
				exit
				;;
			medit)
				$VISUAL $path/$list
				;;
			esac
		;;
esac
}

interact
