#!/bin/bash
tput sc
savePath="/home/thera/projects/theralist/saves/"
list=$(ls $savePath | grep -v ".done" | gum filter --placeholder "Select List")
if ! [[ $list ]]
then
	exit
fi
exitVar=false
function run {
	tput rc
	tlm $list list
	input=$(gum input)
	case $input in
		add*)
			input=${input:4}
			tlm $list add $input
			tput rc
			tlm $list list
			;;
		done)
			tput rc
			items=$(cat $savePath/$list | gum choose --height 100 --no-limit)
			nums=$(cat $savePath/$list | grep -n "$items" | cut -d : -f 1)
			exitVar=true
			;;
		remove)
			echo remove
			items=$(cat $savePath/$list | gum choose --no-limit)
			;;
		swapp)
			echo swap
			items=$(cat $savePath/$list | gum choose --limit 2)
			;;
		replace)
			echo replace
			;;
		exit)
			exitVar=true
			;;
	esac
}
while [[ $exitVar != true ]]
do
	run
done
echo $nums
