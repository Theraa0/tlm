#!/bin/bash
# Copyright (C) 2022 Theraa0
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>. 
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
