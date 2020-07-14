# move downloaded shows to a Plex folder
#find . -type f -iname "*john.oliver*" \| grep -i 'avi$\|mkv$\|mp4$'

# set source for local testing and running on NAS, then select based on which env running
NASSOURCE="/volume1/Media/video/tv.incoming/"
NASDESTINATION="/volume1/Media/video/tv.streams/"
LOCALSOURCE="/mnt/x/video/tv.incoming/"
LOCALDESTINATION="/mnt/x/video/tv.streams/"
if [[ -d $NASSOURCE ]]
then
	SOURCE="$NASSOURCE"
	DESTINATION="$NASDESTINATION"
elif [[ -d $LOCALSOURCE ]]
then
	SOURCE="$LOCALSOURCE"
	DESTINATION="$LOCALDESTINATION"
else
	echo "CANNOT find any directories"
	exit -1
fi

deleteEXT=("nfo" "exe" "txt")
moviesEXT=("mkv" "avi" "mp4")
doCreatDirs="createDirs.do"
logfile="activity.log"

declare -A shows=(
["60_Minutes"]="*60.Minutes*"
["Broke"]="*Broke*"
["DCs_Legends_of_Tomorrow"]="*Legends.of.Tomorrow*"
["Doom_Patrol"]="*Doom.Patrol*"
["Harley_Quinn"]="*Harley.Quinn*"
["Holey_Moley"]="*Holey.Moley*"
["Hollywood_Game_Night"]="*Hollywood.Game.Night*"
["Last_Week_Tonight_with_John_Oliver"]="*Last.Week.Tonight*"
["Marvel's_Agents_of_S.H.I.E.L.D"]="*Marvels.Agents.of.S.H.I.E.L.D.*"
["Penn_&_Teller_Fool_Us"]="*Penn.And.Teller.Fool.Us*"
["Penny_Dreadful_City_of_Angels"]="*Penny.Dreadful.City.of.Angels*"
["Stargirl"]="*Stargirl*"
["The_Late_Show_with_Stephen_Colbert"]="*Late.Show.Colbert*"
["The_Late_Show_with_Stephen_Colbert"]="*Stephen.Colbert*"
)


# should not have to modify anything below here
LOGOUT="$SOURCE$logfile"
DOOUT="$SOURCE$doCreatDirs"
RAN=$(date '+%Y:%m:%d:%H:%M')
echo "$RAN" >> "$LOGOUT"

move_if_dir_exists () {
	file=$1
	dest=$2
	simpleFile="${file##*/}"

	#echo "File: $file  to $dest"
	if [[ -d $dest ]]
	then
       	echo "EXISTS! $dest"
		mv -v "$file" "$dest"
		echo "MOVED $simpleFile --> $dest" | tee -a "$LOGOUT"
	else
		echo "MISSING DIR: $dest"
		echo "Create Dir: $dest" >> "$DOOUT"
	fi
}

export -f move_if_dir_exists

# Remove todo list if exists
[ -f "$DOOUT" ] && rm "$DOOUT"

declare -A matchFull=()
for key in ${!shows[@]}; do 
	searchFor=${shows[$key]}; 
	outDir="$DESTINATION$key/"
	for ext in ${moviesEXT[@]}; do
		while IFS= read -r -d $'\0'; do
        		matchFull+=(["$REPLY"]="$outDir")
		done < <(find "$SOURCE" -type f -iname "$searchFor${ext}" -print0)
	done
done
echo "Possible # of shows to move: ${#matchFull[@]}"

for file in ${!matchFull[@]}; do
	DEST="${matchFull[$file]}"
	#echo "move_if_dir_exists ${file} $DEST"
	move_if_dir_exists "${file}" "$DEST"
done

echo "Delete extra files and empty directories..."
# remove non-video files
for badext in ${deleteEXT[@]}; do
	echo "Hi"
	find $SOURCE -type f -iname "*.${badext}" | xargs -I {} -n 1 rm -v "{}"
done
#find $SOURCE -type f -iname "*.txt" -o -iname "*.exe" -o -iname "*.nfo" | xargs -I {} -n 1 rm -v "{}"


# delete any empty dirs below SOURCE
find $SOURCE -mindepth 1 -type d -empty -print -delete
