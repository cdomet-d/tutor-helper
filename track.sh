#!/bin/bash

if [ $# -eq 0 ]; then
	echo "Usage: $0 <login>"
	exit 1
fi

bash "${TOSCRIPT}"api_gen.sh

if [ -t 1 ]; then
	bold=$(tput bold)
	normal=$(tput sgr0)
else
	bold=""
	normal=""
	color=""
fi

login="$1"
abspath="${TOSCRIPT}.json"

token=$(jq -r '.access_token' "$abspath"/token.json)
if ! curl -s -H "Authorization: Bearer $token" \
	https://api.intra.42.fr/v2/users/"$login" \
	-o "$abspath"/user.json ||
	! jq -e -r '.login' "$abspath"/user.json >/dev/null; then
	echo "Error: no such login"
	exit 1
fi

level=""

read -r url loc level < <(
	jq -r '
    . as $root |
    [$root.url, $root.location // "unknown",
     (
       $root.cursus_users
       | map(select(.grade == "Cadet" or .grade == "Transcender"))
       | first
       | .level
     )
    ]
    | @tsv' "$abspath"/user.json
)

if [ -z "$level" ] || [ "$level" == null ]; then
	level="$(jq -r '.cursus_users[] | select(.grade == "Pisciner") | .level' "$abspath"/user.json)"
fi

printf '%-20.20s%s\n' "${bold}Login${normal}" "${login}"
printf '%-20.20s%s\n' "${bold}Level${normal}" "${level}"
printf '%-20.20s%s\n' "${bold}Location${normal}" "${loc}"
printf '%-20.20s%s\n' "${bold}Profile${normal}" "${url//api.intra.42.fr\/v2/profile.intra.42.fr}"

echo

echo "${bold}Working on${normal}"
now=$(date +%s)
jq -r --arg now "$now" '.projects_users[] 
	| select(.final_mark == null) 
	| .created_at as $created
	| ($created | sub("\\..*"; "") | strptime("%Y-%m-%dT%H:%M:%S") | mktime) as $start
	| ($now | tonumber) as $now
	| "\(.project.name)\t\($now - $start)"' "$abspath"/user.json |
	while IFS=$'\t' read -r project seconds_elapsed; do
		days=$((seconds_elapsed / 86400))
		printf '%-20.20s | Since: %d days\n' "$project" "$days"
	done

echo

if jq -e -r '.cursus_users[] | select(.grade == "Cadet" or .grade == "Transcender")' \
	"$abspath"/user.json >/dev/null; then

	printf '%-20.20s' "${bold}Alone${normal}"
	jq -e '.projects_users[] | select(.project.name == "Alone in the Dark") 
		| .final_mark' \
		"$abspath"/user.json || echo "never attempted"
	exit 0
else
	echo "${bold}Validated projects${normal}"
	jq -r '
		.projects_users
		| map (select(.final_mark != null))
		| sort_by(.marked_at)
		| reverse[]
		| [
			.project.name, 
			.marked_at,
			.final_mark, 
			.["validated?"]
		] | @tsv
		' "$abspath"/user.json |
		while IFS=$'\t' read -r name marked_at grade validated; do
			validation_date=$(date -d "$marked_at" '+%a %d/%m/%Y')
			validation_hour=$(date -d "$marked_at" '+%H:%M')
			if [ "$validated" == true ] && [ -t 1 ]; then
				color="\033[32m"
			elif [ "$validated" == false ] && [ -t 1 ]; then
				color="\033[31m"
			fi
			printf "%-20.20s | Grade: ${color}%3d/100${normal} | On %s at %s\n" \
				"$name" "$grade" "$validation_date" "$validation_hour"
		done
fi

echo
echo "${bold}Evaluation logs ${normal}"

curl -s -H "Authorization: Bearer $token" \
	https://api.intra.42.fr/v2/users/"$login"/correction_point_historics  \
	-o "$abspath"/user-evals.json

jq -r '.[] 
	| .created_at as $created
	| .sum as $val
	| ($created | sub("\\..*"; "") | strptime("%Y-%m-%dT%H:%M:%S") | mktime) as $epoch
	| ($epoch | strftime("On %a %d/%m/%Y at %H:%M")) as $formattedDate
	| if ($val == -1 or $val == 1) and ($formattedDate | test("On (Sun|Sat)")) 
		then "\($formattedDate)\t\($val)" else empty end' "$abspath/user-evals.json" |
	while IFS=$'\t' read -r date val; do
		if [ "$val" == "-1" ]; then 
			val="Booked evaluation"
		elif [ "$val" == "1" ]; then
			val="Evaluated someone"
		else
			val=""
		fi
		printf '%s | %s\n' "$date" "$val"
	done


rm -f "$abspath"/user.json
rm -f "$abspath"/user-eval.json
