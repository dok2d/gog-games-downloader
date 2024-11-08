#!/bin/bash
set -e

function exit_script {
  set +x
  unset err_stat
  case $1 in
    err)  shift; echo -e "\033[1;33mError!\n${@}\033[0m"; err_stat=yes ;;
    warn) shift; echo -e "\033[1;34mError!\n${@}\033[0m";;
    info) shift; echo -e "$@" ;;
  esac
  [ -z "${err_stat}" ] && exit 0
  [ -n "${err_stat}" -a "${err_stat}" = yes ] && exit 1
}

t_help=$(echo -e "
$(echo -e "Run: bash gog-games-downloader.sh -c [COOCKIE-FILE] [OPTIONS]
Options:
  Option œ© Long option œ© SubOption œ© Meaning
  -c œ© --cookie-file œ© <file> œ© Required. Path to the cookie file
  -o œ© --out-path œ© [PATH] œ© Path to save directory
  -p œ© --platforms œ© [TYPE] œ© Select platforms. Default: lin win
  -l œ© --langs-priority œ© [LANG] œ© List of languages to download, in order of priority. Default: rus eng
     œ© --only-giveawayclaim œ©  œ© Check giveaway claim and exit

Available arguments
Platform types: lin win mac
language in ISO 639-3: deu eng spa por tur fra ita pol ron fin swe ces rus zho jpn kor

Examples
bash gog-games-downloader.sh -c cook_file -p "mac win" -l "fra eng"
bash gog-games-downloader.sh -c cook_file --only-giveawayclaim
" | column -ets 'œ©')")

while [ ! -z "${1}" ]; do
  case "${1,,}" in
    -c|--cookie-file) 
      shift
      [ -z "${1}" ] && exit_script err "The path to the cookie file is not specified!"
      [ ! -f "${1}" ] && exit_script err "There is no cookie file named ${1}"
      [ ! -s "${1}" ] && exit_script err "The file "${1}" is empty."
      cook=$(cat "${1}") 
      shift;;
    -p|--platforms)
      shift
      [ -z "${1}" ] && exit_script err "Platforms is not specified!"
      avail_platforms=("win" "lin" "mac")
      while [[ $# -gt 0 && ! $1 =~ ^- ]]; do
          [[ ! " ${avail_platforms[@]} " =~ " $1 " ]] && exit_script err "Platform ${1} is not in available list!"
          platforms+="${1} "
          shift
      done;;
    -l|--langs-priority)
      shift
      [ -z "${1}" ] && exit_script err "Languages is not specified!"
      avail_languages=("deu" "eng" "spa" "por" "tur" "fra" "ita" "pol" "ron" "fin" "swe" "ces" "rus" "zho" "jpn" "kor")
      while [[ $# -gt 0 && ! $1 =~ ^- ]]; do
          [[ ! " ${avail_languages[@]} " =~ " $1 " ]] && exit_script err "Language ${1} is not in available list!"
          langs_priority+="${1} "
          shift
      done;;
    -o|--out-path)
      [ -z "${1}" ] && exit_script err "The path to the cookie file is not specified!"
      shift
      outpath=${1}
      shift;;
    --only-giveawayclaim)
      onlygiveawayclaim=yes
      shift;;
    -h|--help) exit_script info "${t_help}" ;;
    *) exit_script info "Error flag - ${1}\n\n${t_help}" ;;
  esac
done

platforms="${platforms:-lin win}"
langs_priority="${langs_priority:-rus eng}"
outpath=${outpath:-~/gog-dump}

getpage() {
  [ -z "${1}" ] && exit_script err "NULL URL"
  curl -s -H "${cook}" "$(for i in $*; do echo -n "${i} "; done | sed 's/ $//g')"
}

check_md5() {
  echo -n " [md5:"
  md5sum --quiet -c <(echo "$@") > /dev/null 2>&1
  [ "$?" = 0 ] && echo "ok]" || echo "not ok]"
}

human_readable_filesize() {
    local bytes=$1
    local units=("B" "KB" "MB" "GB" "TB")
    local i=0
    while (( bytes >= 1024 && i < ${#units[@]} - 1 )); do
        bytes=$(( bytes / 1024 ))
        i=$(( i + 1 ))
    done
    printf "%.1f %s\n" "$bytes" "${units[i]}"
}

[ -z "${cook}" ] && exit_script err "The path to the cookie file is not specified!"
[ "$(dpkg -l | awk '{print $2}' | grep -c "^jq$")" -ne 1 ] && apt-get --yes install jq
totalpages="$(getpage "https://www.gog.com/account/getFilteredProducts?hiddenFlag=0&mediaType=1" | jq -r '.totalPages')"

for i in $(seq 1 ${totalpages}); do
  inventory="$(echo -e "${inventory}${inventory:+\n}$(getpage "https://www.gog.com/account/getFilteredProducts?hiddenFlag=0&mediaType=1&page=${i}&sortBy=date_purchased" | jq -r '.products[] | "\(.id) \(.slug) \(.title)"')")"
done

[ -z "${onlygiveawayclaim}" ] && echo -e "Download dir: ${outpath}/ (Available$(df -h --output=avail "${outpath}" | tail -1))"
getpage https://www.gog.com/giveaway/claim | jq -r '.message'
echo
[ "${onlygiveawayclaim}" = "yes" ] && exit_script

echo -e "${inventory}" | grep -v "^$" | while read id slug name; do
  unset lang_selected
  gameinfo="$(getpage "https://www.gog.com/account/gameDetails/${id}.json")"
  cdkey=$(echo ${gameinfo} | jq -r '.cdKey')
  langs_available=$(echo ${gameinfo} | jq -r '.downloads[] | .[0]')

  for lang in ${langs_priority,,}; do
    [ "${lang:0:3}" = rus ] && lang="русский"
    [ "${lang:0:3}" = eng ] && lang="English"
    [ "${lang:0:3}" = deu ] && lang="Deutsch"
    [ "${lang:0:3}" = spa ] && lang="Español (AL) or español"
    [ "${lang:0:3}" = por ] && lang="Português do Brasil or português"
    [ "${lang:0:3}" = tur ] && lang="Türkçe"
    [ "${lang:0:3}" = fra ] && lang="français"
    [ "${lang:0:3}" = ita ] && lang="italiano"
    [ "${lang:0:3}" = pol ] && lang="polski"
    [ "${lang:0:3}" = ron ] && lang="română"
    [ "${lang:0:3}" = fin ] && lang="suomi"
    [ "${lang:0:3}" = swe ] && lang="svenska"
    [ "${lang:0:3}" = ces ] && lang="český"
    [ "${lang:0:3}" = zho ] && lang="中文(简体)"
    [ "${lang:0:3}" = jpn ] && lang="日本語"
    [ "${lang:0:3}" = kor ] && lang="한국어"
    if [ "${lang}" = "Español (AL) or español" -o "${lang}" = "Português do Brasil or português" ]; then
      for i in $(echo ${lang// /_} | sed 's/_or_/ /g'); do
        [[ "${langs_available}" == *${i//_/ }* ]] && lang_selected=${i//_/ }
      done
    elif [[ "${langs_available,,}" == *"$(echo ${lang,,} | sed 's/ .*//g')"* ]]; then
      lang_selected=${lang}
    fi
    [ -n "${lang_selected}" ] && break
  done

  if [ -n "${lang_selected}" ]; then
    platform_available=$(echo ${gameinfo} | jq -r '.downloads[] | select(.[0]=="'${lang_selected}'") | .[1] | keys[]')
    for os in ${platforms,,}; do
      unset os_type
      [ "${os:0:1}" = l ] && os_type=linux
      [ "${os:0:1}" = w ] && os_type=windows
      [ "${os:0:1}" = m ] && os_type=mac
      if [[ "${platform_available}" == *${os_type}* ]]; then
        files_links=$(echo ${gameinfo} | jq -r '.downloads[] | select(.[0]=="'${lang_selected}'") | .[1] | .'${os_type}'[] | .manualUrl' | grep installer[0-9])
        files_count=$(echo -e "${files_links}" | wc -l)
        [ "${files_count}" -eq 1 ] && outdir=${outpath}/${os} || outdir=${outpath}/${os}/${slug}
        mkdir -p "${outdir}"
        [ -n "${cdkey}" ] && echo ${cdkey} > "${outdir}/${slug}.cdkey"
        unset count_download
        for i in ${files_links}; do
          count_download=$((count_download+1))
          echo -n "${name} [${os}] (${count_download}/${files_count}).. "
          target_link=$(curl -sILH "${cook}" --write-out '%{url_effective}' --output /dev/null https://www.gog.com${i})
          target_md5="$(getpage ${target_link}.xml | sed -n 's/.*md5="\([^"]*\)".*/\1/p')"
          target_bytesize="$(getpage ${target_link}.xml | sed -n 's/.*total_size="\([^"]*\)".*/\1/p')"
          outfile_name=$(echo ${target_link} | sed 's/.*\///;s/%[0-9][0-9]//g;s/setup_//g;s/gog_//g;s///g;s/\.exe.*/.exe/g;s/\.bin.*/.bin/g')
          if [ -f "${outdir}/${outfile_name}" ]; then
            if [ $((${target_bytesize} - $(stat -c %s "${outdir}/${outfile_name}"))) -gt $(df --output=avail . | tail -1) ]; then
              echo "Skipping a file that is too large. File size: $(human_readable_filesize ${target_bytesize}). Available disk space:$(df -h --output=avail "${outpath}" | tail -1)"
              continue
            fi
          elif [ ${target_bytesize} -gt $(df --output=avail . | tail -1) ]; then
            echo "Skipping a file that is too large. File size: $(human_readable_filesize ${target_bytesize}). Available disk space:$(df -h --output=avail "${outpath}" | tail -1)"
            continue
          fi
          wget ${target_link} -qcO "${outdir}/${outfile_name}"
          if [ "$?" = 0 ]; then
            echo -n ok
            check_md5 ${target_md5} "${outdir}/${outfile_name}"
          else
             echo fail
          fi
        done
      fi
    done
  else
    echo ${name} is not available in languages ${langs_priority}!
  fi
done
