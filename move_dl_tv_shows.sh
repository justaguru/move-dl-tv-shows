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

deleteEXT=("nfo" "exe" "txt" "jpg")
moviesEXT=("mkv" "avi" "mp4")
doCreatDirs="createDirs.do"
logfile="activity.log"
createDir=1
createFileInDir=1	# because Plex deletes empty folders, so keep a .txt file if you want the folder to stay
emptyFileName="donotdelete.txt"

# List of show search patterns, with what folder to put them in. Can have multiple pattern lines per show.
declare -A shows=(
["*60.Minutes*"]="60_Minutes_(73290)"
["*All.Rise*"]="All_Rise"
["*American.Ninja.Warrior*"]="American_Ninja_Warrior"
["*Batwoman*"]="Batwoman"
["*Black-ish*"]="Blackish"
["*Blackish*"]="Blackish"
["*Bob.Hearts.Abishola*"]="Bob_Hearts_Abishola"
["*B.Positive*"]="B_Positive"
["*Broke*"]="Broke"
["*Bull*"]="Bull"
["*Debris*"]="Debris"
["*A.Discovery.Of.Witches*"]="A_Discovery_of_Witches"
["*Doctor?Who*"]="Doctor_Who"
["*Doom.Patrol*"]="Doom_Patrol"
["*The?Equalizer*"]="The_Equalizer"
["*The?Expanse*"]="The_Expanse"
["*The?Falcon?and?the?Winter?Soldier*"]="Falcon_and_the_Winter_Soldier"
["*Fargo*"]="Fargo"
["*The?Flash*"]="The_Flash"
["*The.Good.Doctor*"]="Good_Doctor"
["*Harley.Quinn*"]="Harley_Quinn"
["*Holey.Moley*"]="Holey_Moley"
["*Hollywood.Game.Night*"]="Hollywood_Game_Night"
["*Kung.Fu*"]="Kung_Fu"
["*Last?Man?Standing*"]="Last_Man_Standing"
["*Last.Week.Tonight*"]="Last_Week_Tonight_with_John_Oliver"
["*Legends.of.Tomorrow*"]="DCs_Legends_of_Tomorrow"
["*Lucifer*"]="Lucifer"
["*MacGyver*"]="MacGyver"
["*The.Mandalorian*"]="Star_Wars_The_Mandalorian"
["*Magnum.p.i*"]="Magnum_PI"
["*Marvels.Agents.of.S.H.I.E.L.D.*"]="Marvel's_Agents_of_S.H.I.E.L.D"
["*Mom*"]="Mom"
["*Mr.Mayor*"]="Mr_Mayor"
["*NCIS*"]="NCIS"
["*The.Neighborhood*"]="The_Neighborhood"
["*Our.Cartoon.President*"]="Our_Cartoon_President"
["*Penn.And.Teller.Fool.Us*"]="Penn_&_Teller_Fool_Us"
["*Penny.Dreadful.City.of.Angels*"]="Penny_Dreadful_City_of_Angels"
["*The?Rookie*"]="The_Rookie"
["*Saturday.Night.Live*"]="Saturday_Night_Live"
["*The?Simpsons*"]="Simpsons"
["*Star.Trek.Discovery*"]="Star_Trek_Discovery"
["*Star.Trek.Lower.Decks*"]="Star_Trek_Lower_Decks"
["*Stargirl*"]="Stargirl"
["*Stephen?Colbert*"]="The_Late_Show_with_Stephen_Colbert"
["*Superman?and?Lois*"]="Superman_and_Lois"
["*Late?Show?Colbert*"]="The_Late_Show_with_Stephen_Colbert"
["*Superstore*"]="Superstore"
["*This.is.Us*"]="This_is_Us"
["*This.Old.House*"]="This_Old_House"
["*Undercover.Boss*"]="Undercover_Boss"
["*The.Unicorn*"]="The_Unicorn"
["*United.States.of.Al*"]="United_States_of_Al"
["*Van.Helsing*"]="Van_Helsing"
["*WandaVision*"]="WandaVision"
["*Wipeout*"]="Wipeout"
["*Wynonna.Earp*"]="Wynonna_Earp"
["*Young.Sheldon*"]="Young_Sheldon"
)

#
# should not have to modify anything below here
#
LOGOUT="$SOURCE$logfile"
TMPFILE="$SOURCE/tmp.$$"
DOOUT="$SOURCE$doCreatDirs"
RAN=$(date '+%Y:%m:%d:%H:%M')
echo "$RAN" >> "$LOGOUT"

move_if_dir_exists () {
	file="$1"
	dest="$2"
	# filename, everything after last / in path/parts/filename
	simpleFile="${file##*/}"

	if [[ ! -d $dest ]] && [[ $createDir ]]
	then
		mkdir -v "$dest"
		echo "CREATED DIR $dest" | tee -a "$LOGOUT"
		if [[ $createFileInDir ]]
		then
			touch "$dest$emptyFileName"
		fi
	fi
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
# Loop through all show patterns and look for matching files, add matches to hash array
for searchFor in ${!shows[@]}; do 
	folder=${shows[$searchFor]}; 
	outDir="$DESTINATION$folder/"
	for ext in ${moviesEXT[@]}; do
		find "$SOURCE" -type f -iname "$searchFor${ext}" -print > "$TMPFILE"
		while IFS= read -r line; do
        		matchFull+=(["$line"]="$outDir")
		done < "$TMPFILE"
	#echo "find $SOURCE -type f -iname $searchFor${ext} -print0"
	done
done
echo "Possible # of shows to move: ${#matchFull[@]}"

# Go through all matches and move them to correct folder
for file in "${!matchFull[@]}"; do
	DEST="${matchFull[$file]}"
	#echo "move_if_dir_exists ${file} $DEST"
	move_if_dir_exists "${file}" "$DEST"
done

echo "Delete extra files and empty directories..."
# remove non-video files
for badext in ${deleteEXT[@]}; do
	find $SOURCE -type f -iname "*.${badext}" | xargs -I {} -n 1 rm -v "{}"
done
#find $SOURCE -type f -iname "*.txt" -o -iname "*.exe" -o -iname "*.nfo" | xargs -I {} -n 1 rm -v "{}"
# cleanup tmp file
[ -e "$TMPFILE" ] && rm "$TMPFILE"

# delete any empty dirs below SOURCE
find $SOURCE -mindepth 1 -type d -empty -print -delete
