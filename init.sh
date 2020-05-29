#!/usr/bin/env bash

echo "Starting to link files to $HOME"
#ln -si $PWD/.oh-my-zsh $HOME
#ln -si $PWD/.zshrc $HOME

#echo $([ -d "$HOME/config" ])

if [ -d "$HOME/.config" ]; then
		echo "Backing up existing $HOME/.config to $HOME/config-backup.."
		cp -r "$HOME/.config" "$HOME/config-backup"
fi

for file in $(find); do
		if [ "$file" != "." ] && [ "$file" != ".." ]; then
			echo	
				#echo $file
				#ln -si $PWD/
		fi
done
