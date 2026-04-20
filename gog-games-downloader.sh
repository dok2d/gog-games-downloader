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
     œ© --no-dlc œ©  œ© Disable DLC download
     œ© --no-md5 œ©  œ© Disable MD5-check
     œ© --extras œ©  œ© Download bonus materials (soundtracks, artbooks, etc.)
     œ© --check-updates œ©  œ© Re-download files if GOG updated the game

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
    --no-dlc)
      dlc_disable=yes
      shift;;
    --no-md5)
      md5_disable=yes
      shift;;
    --extras)
      extras_enable=yes
      shift;;
    --check-updates)
      check_updates=yes
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
  [ "$?" = 0 ] && echo "ok]" || echo "not ok] FILE: ${outdir}/${outfile_name} URL: ${target_link} (current md5sum:${1})"
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

save_manifest() {
    local manual_url=$1
    local md5=$2
    local file_path=$3
    local manifest_file="${outpath}/.gog-md5-manifest"
    grep -v "^${manual_url}|" "${manifest_file}" 2>/dev/null > "${manifest_file}.tmp" || true
    echo "${manual_url}|${md5}|${file_path}" >> "${manifest_file}.tmp"
    mv "${manifest_file}.tmp" "${manifest_file}"
}

get_manifest_entry() {
    local manual_url=$1
    local manifest_file="${outpath}/.gog-md5-manifest"
    grep "^${manual_url}|" "${manifest_file}"
}

[ -z "${cook}" ] && exit_script err "The path to the cookie file is not specified!"
[ "$(dpkg -l | awk '{print $2}' | grep -c "^jq$")" -ne 1 ] && exit_script err "You need install jq!"
getpage https://www.gog.com/giveaway/claim | jq -r '.message'
totalpages="$(getpage "https://www.gog.com/account/getFilteredProducts?hiddenFlag=0&mediaType=1" | jq -r '.totalPages')"

for i in $(seq 1 ${totalpages}); do
  inventory="$(echo -e "${inventory}${inventory:+\n}$(getpage "https://www.gog.com/account/getFilteredProducts?hiddenFlag=0&mediaType=1&page=${i}&sortBy=date_purchased" | jq -r '.products[] | "\(.id) \(.slug) \(.title)"')")"
done

[ -d "${outpath}" ] || mkdir -p "${outpath}"
[ -f "${outpath}/.gog-md5-manifest" ] || touch "${outpath}/.gog-md5-manifest"
[ -z "${onlygiveawayclaim}" ] && echo -e "Download dir: ${outpath}/ (Available$(df -h --output=avail "${outpath}" | tail -1))"
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
        if [ -z "${dlc_disable}" -a -n "$(echo ${gameinfo} | jq -r '.dlcs[] | .downloads[] | select(.[0]=="'${lang_selected}'")')" ]; then
          files_links="${files_links[@]} $(echo ${gameinfo} | jq -r '.dlcs[] | .downloads[] | select(.[0]=="'${lang_selected}'") | .[1] | .'${os_type}'[] | .manualUrl' | grep installer[0-9])"
        fi
        files_count=$(echo -e "${files_links}" | wc -l)
        [ "${files_count}" -eq 1 ] && outdir=${outpath}/${os} || outdir=${outpath}/${os}/${slug}
        mkdir -p "${outdir}"
        [ -n "${cdkey}" ] && echo ${cdkey} > "${outdir}/${slug}.cdkey"
        unset count_download staging_mode all_staging_ok
        all_staging_ok=yes
        staging_info=$(mktemp)
        for i in ${files_links}; do
          count_download=$((count_download+1))
          echo -n "${name} [${os}] (${count_download}/${files_count}).. "
          target_link=$(curl -sILH "${cook}" --write-out '%{url_effective}' --output /dev/null https://www.gog.com${i})
          [ -z "${md5_disable}" ] && target_md5="$(getpage ${target_link}.xml | sed -n 's/.*md5="\([^"]*\)".*/\1/p')"
          target_bytesize="$(getpage ${target_link}.xml | sed -n 's/.*total_size="\([^"]*\)".*/\1/p')"
          outfile_name=$(echo ${target_link} | sed 's/.*\///;s/%[0-9][0-9]//g;s/setup_//g;s/gog_//g;s///g;s/\.exe.*/.exe/g;s/\.bin.*/.bin/g')
          download_dir="${outdir}"
          use_staging=""
          if [ -n "${check_updates}" -a -z "${md5_disable}" ]; then
            if manifest_entry=$(get_manifest_entry "${i}"); then
              saved_md5=$(echo "${manifest_entry}" | cut -d'|' -f2)
              saved_file=$(echo "${manifest_entry}" | cut -d'|' -f3)
              saved_name=$(basename "${saved_file}")
              if [ "${saved_name}" != "${outfile_name}" ]; then
                download_dir="${outdir}/new"
                mkdir -p "${download_dir}"
                staging_mode=yes
                use_staging=yes
                echo -n "(update: ${saved_name} -> ${outfile_name}) "
              elif [ -n "${saved_md5}" -a -n "${target_md5}" -a "${saved_md5}" != "${target_md5}" ]; then
                echo -n "(update found) "
                rm -f "${outdir}/${outfile_name}"
              fi
            fi
          fi
          if [ -f "${download_dir}/${outfile_name}" ]; then
            if [ $((${target_bytesize} - $(stat -c %s "${download_dir}/${outfile_name}"))) -gt $(df -B1 --output=avail "${outpath}" | tail -1) ]; then
              echo "Skipping a file that is too large. File size: $(human_readable_filesize ${target_bytesize}). Available disk space:$(df -h --output=avail "${outpath}" | tail -1)"
              [ -n "${use_staging}" ] && all_staging_ok=""
              continue
            fi
          elif [ ${target_bytesize} -gt $(df -B1 --output=avail "${outpath}" | tail -1) ]; then
            echo "Skipping a file that is too large. File size: $(human_readable_filesize ${target_bytesize}). Available disk space:$(df -h --output=avail "${outpath}" | tail -1)"
            [ -n "${use_staging}" ] && all_staging_ok=""
            continue
          fi
          wget ${target_link} -qcO "${download_dir}/${outfile_name}"
          if [ "$?" = 0 ]; then
            echo -n ok
            if [ -n "${use_staging}" ]; then
              if [ -z "${md5_disable}" ]; then
                echo -n " [md5:"
                if md5sum --quiet -c <(echo "${target_md5} ${download_dir}/${outfile_name}") > /dev/null 2>&1; then
                  echo "ok]"
                  echo "${i}|${target_md5}|${outfile_name}" >> "${staging_info}"
                else
                  echo "not ok]"
                  all_staging_ok=""
                fi
              else
                echo
                echo "${i}||${outfile_name}" >> "${staging_info}"
              fi
            else
              if [ -z "${md5_disable}" ]; then
                check_md5 ${target_md5} "${download_dir}/${outfile_name}"
                save_manifest "${i}" "${target_md5}" "${outdir}/${outfile_name}"
              else
                echo
              fi
            fi
          else
             echo not ok
             [ -n "${use_staging}" ] && all_staging_ok=""
          fi
        done
        if [ -n "${staging_mode}" -a -n "${all_staging_ok}" ]; then
          while IFS='|' read mu md5 fname; do
            me=$(get_manifest_entry "${mu}")
            if [ -n "${me}" ]; then
              sf=$(echo "${me}" | cut -d'|' -f3)
              [ -f "${sf}" ] && rm -f "${sf}"
            fi
            mv "${outdir}/new/${fname}" "${outdir}/${fname}"
            save_manifest "${mu}" "${md5}" "${outdir}/${fname}"
          done < "${staging_info}"
          rmdir "${outdir}/new" 2>/dev/null
        elif [ -n "${staging_mode}" ]; then
          echo "Update incomplete. Staged files kept in ${outdir}/new/ for resume."
        fi
        rm -f "${staging_info}"
      fi
    done
    if [ -n "${extras_enable}" ]; then
      extras_links=$(echo ${gameinfo} | jq -r '.extras[]? | .manualUrl' 2>/dev/null)
      if [ -n "${extras_links}" ]; then
        extras_count=$(echo -e "${extras_links}" | wc -l)
        extras_dir="${outpath}/extras/${slug}"
        mkdir -p "${extras_dir}"
        unset count_extras
        for i in ${extras_links}; do
          count_extras=$((count_extras+1))
          echo -n "${name} [extras] (${count_extras}/${extras_count}).. "
          target_link=$(curl -sILH "${cook}" --write-out '%{url_effective}' --output /dev/null https://www.gog.com${i})
          outfile_name=$(echo ${target_link} | sed 's/.*\///;s/%[0-9][0-9]//g')
          target_bytesize="$(curl -sILH "${cook}" "${target_link}" | grep -i content-length | tail -1 | tr -d '[:space:]' | cut -d: -f2)"
          if [ -f "${extras_dir}/${outfile_name}" ]; then
            echo "already downloaded"
            continue
          fi
          if [ -n "${target_bytesize}" ] && [ ${target_bytesize} -gt $(df -B1 --output=avail "${outpath}" | tail -1) ]; then
            echo "Skipping a file that is too large. File size: $(human_readable_filesize ${target_bytesize}). Available disk space:$(df -h --output=avail "${outpath}" | tail -1)"
            continue
          fi
          wget ${target_link} -qcO "${extras_dir}/${outfile_name}"
          [ "$?" = 0 ] && echo "ok" || echo "not ok"
        done
      fi
    fi
  else
    echo ${name} is not available in languages ${langs_priority}!
  fi
done
