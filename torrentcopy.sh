# Program to copy torrented files from torrent server to NAS device with
# an easy user interface. This program depends on rsync.

# Todo:

# Give user ability to name outputted file. (Just tack it on the end of rsync).
# Support unzipping of music archives.

# Directories to use.
torrentDirectory="/mnt/torrents/" # The root directory where torrents are downloaded to.
commonDirectory="/mnt/mybooklive3/" # The root directory where all torrents will be sorted.
destinationDirectory="Software/torrents/" # The default directory for unsorted torrents.

clear

printf 'Welcome to torrent copy!'
printf '\nHere is the list of downloaded torrents.\n'

# List files currently on torrent server
let count=1
fileArray=()
for f in "$torrentDirectory"*
do
    printf "\n["$count"] $(basename "$f")"
    let count=count+1
    fileArray+=("$(basename "$f")")
done
printf " "

# Ask user for which one to copy over.
printf "\n\nType the number of the file you wish to copy followed by [ENTER]:\n> "
read fileChoice

let fileChoice=fileChoice-1 # Subtract choice by 1 to fit array standard of starting from 0.

chosenFile=${fileArray["$fileChoice"]}

if [[ "$chosenFile" == "" ]]; then
    printf "\nYou didn't choose a correct number!\n"
    exit
fi

# Ask user torrent filetype

printf "\nWhat type of media is this torrent? Type a number and hit [ENTER]:\n"
printf "[1] Movie\n[2] TV Show\n[3] Music\n[4] Game\n[5] eBook\n[6] Other\n> "
read fileChoice

# Copy file over.
filePath="$torrentDirectory$chosenFile";

copyMovie() {
	destinationDirectory="Shared Videos/Movies/" # Set the directory for movies

	printf "\n***Copying files over. Please do not close the connection until this has finished.***\n\n"

	SAVEIFS=$IFS
	IFS=$(echo -en "\n\b")
	files=("$filePath"/*)
	for f in ${files[*]} # For every mkv/mp4 in the directory
	do
		# Check if the file is greater than 75MB. Copy if it isn't.
	    if [[ $(find $f -type f -size +75000000c 2>/dev/null) ]]; then
	    	rsync -rvh --progress $f "$commonDirectory$destinationDirectory";
		fi
	done
	IFS=$SAVEIFS
}

copyTv() {
    destinationDirectory="Shared Videos/Tv Shows/" # Set the directory for Tv Shows

    # Todo:

    # Ask user which Tv Show to store the file in, if their Tv Show isn't available,
    # ask them to enter the name for a new one.

    printf "\nEnter the name of the Tv Show (Example: Law and Order)\n> "
    read showName

    # Create show directory if it doesn't exist.
    if [[ ! -d "$commonDirectory$destinationDirectory$showName/" ]]; then
            mkdir "$commonDirectory$destinationDirectory$showName/";
    fi

    # Add support for downloading multiple episodes at once.

    # Ask user which season the episode is on.
    printf "\nWhich Season does this episode belong to? Enter a single number.\n> "
    read seasonNum

    printf "\n***Copying files over. Please do not close the connection until this has finished.***\n\n"

    files=("$filePath"/*)
    SAVEIFS=$IFS
	IFS=$(echo -en "\n\b")
    for f in ${files[*]} # For every mkv/mp4 in the directory
    do
        # Check if the file is greater than 75MB. Copy if it isn't.
        if [[ $(find $f -type f -size +75000000c 2>/dev/null) ]]; then
            # echo "Found suitable tv show >75MB, file is $f"
            rsync -rvh --progress "$f" "$commonDirectory$destinationDirectory$showName/$seasonNum/";
        fi
    done
    IFS=$SAVEIFS
}

# Does not support extracting music files from an archive yet.
copyMusic() {
	destinationDirectory="Shared Music/" # Set the directory for Music

	printf "\nEnter the name of the artist. (Example: Coldplay)\n> "
    read artistName

    # Create show directory if it doesn't exist.
    if [[ ! -d "$commonDirectory$destinationDirectory$artistName/" ]]; then
            mkdir "$commonDirectory$destinationDirectory$artistName/";
    fi

    # Add support for downloading multiple episodes at once.

    # Ask user which season the episode is on.
    printf "\nEnter the name of the album. (Example: Parachutes)\n> "
    read albumName

    printf "\n***Copying files over. Please do not close the connection until this has finished.***\n\n"

	SAVEIFS=$IFS
	IFS=$(echo -en "\n\b")
	files=("$filePath"/*)
    for f in ${files[*]} # For every mkv/mp4 in the directory
    do
        # Check if the file is greater than 75MB. Copy if it isn't.
        if [[ $(find $f -type f -size +1000000c 2>/dev/null) ]]; then
            # echo "Found suitable tv show >75MB, file is $f"
            rsync -rvh --progress "$f" "$commonDirectory$destinationDirectory$artistName/$albumName/";
        fi
    done
    IFS=$SAVEIFS
}

copyGame () {
	destinationDirectory="Software/Games/" # Set the directory for Games
	printf "\nEnter a name for the game directory (Example: Call of Duty 4)\n> "
	read gameName

	printf "\n***Copying files over. Please do not close the connection until this has finished.***\n\n"
	rsync -rvh --progress $filePath "$commonDirectory$destinationDirectory$gameName"
}

# Typical formats: .pdf, .epub, .rar, .zip, .7z
copyBook () {
	destinationDirectory="Software/Books/" # Set the directory for eBooks
	printf "\nEnter the name of the author (Example: Shakespeare)\n> "
	read authorName

	# Create author directory if it doesn't exist.
	[[ ! -d "$commonDirectory$destinationDirectory/$authorName/" ]] && mkdir "$commonDirectory$destinationDirectory/$authorName/" ]]

	printf "\nEnter the name of the book (Example: Hamlet)\n"
	read bookName

	printf "\n***Copying files over. Please do not close the connection until this has finished.***\n\n"

	for f in "$filePath/*.epub" # For every epub in the directory
	do
	    if [[ ! "$f" == *"sample"* ]]; then # Check if the file string contains "sample". Copy if it doesn't.
			printf "\nFound media without \"sample\"\n> ";
			rsync -rvh --progress $f "$commonDirectory$destinationDirectory$authorName/$bookName/"
		fi
	done
}

copyOther () {
	destinationDirectory="Software/torrents/" # Set the directory for default torrents

	printf "\n***Copying files over. Please do not close the connection until this has finished.***\n\n"

	rsync -rvh --progress $f "$commonDirectory$destinationDirectory$authorName/$bookName/"

}

case $fileChoice in
	1)
		copyMovie
		;;
	2)
		copyTv
		;;
	3)
		copyMusic
		;;
	4)
		copyGame
		;;
	5)
		copyBook
		;;
	*)
		copyOther
		;;
esac

printf "\nCopying finished.\n"

# Ask user if they want to remove the file from the torrent server
# after copying.
printf "\nDo you want to remove the file from the server?(y/n):\n"
read removeChoice

# Delete the file based or user's previous response.
if [[ "$removeChoice" == "y" || "$removeChoice" == "Y" ]]; then
    # Remove file from server
    printf "\nRemoving file from server..."
    rm -r "/mnt/torrents/$chosenFile"
    printf "\nFinished.\n\n"
fi


