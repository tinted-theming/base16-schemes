#!/usr/bin/env bash
# Usage
# export NIXPKGS_ALLOW_UNFREE=1 ; nix-shell
# ./doc/generate_main_readme.sh

TMPDIR=$(mktemp -d)
CWIDTH=47
CHEIGHT=37
CSPACE=2
CBACKGROUNDS=("212121")
NB_BACKGROUND=$(expr ${#CBACKGROUNDS[@]} - 1)
BG_SEQS=$(seq 0 $NB_BACKGROUND)

TITLE="Name"
LINE="---"
for idx in $BG_SEQS; do
    CBACKGROUND=${CBACKGROUNDS[$idx]}
    TITLE+=" | bg_${CBACKGROUND}"
    LINE+=" | ---"
done

SCHEMES="${TITLE}
${LINE}
"

###############################
# Generating palette, pictures
###############################
echo "TMPDIR: $TMPDIR"
while IFS= read -r filename
do
    stylename=$(echo "$filename" | sed 's/.yaml$//g')
    authorline=$(yq -r .author ../${filename})
    author=$(echo "$authorline" | sed 's/ (.*//g')
    url=$(echo "$authorline" | sed -n "s/.*(\(.*\))/\1/p")

    echo "Generating style for ${stylename} scheme"
    if [ ! -f "palettes/colors_scheme_${stylename}_bg${CBACKGROUND}.png" ]; then
        for idx in $BG_SEQS; do
            CBACKGROUND=${CBACKGROUNDS[$idx]}

            ###################
            # Generate palette
            ###################
            colors=""
            for color in $(cat ../$filename | grep -E 'base.*?:' |  grep -oE '".*"' | tr -d '"') ; do
                test -f ${TMPDIR}/color_${color}.png || convert -size ${CWIDTH}x${CHEIGHT} xc:\#${color} ${TMPDIR}/color_${color}.png
                colors="${colors}${TMPDIR}/color_${color}.png "
            done

            montage -background "#${CBACKGROUND}" $(echo $colors) -tile x1 -geometry +${CSPACE}+${CSPACE} ${TMPDIR}/noborder_${stylename}.png
            convert ${TMPDIR}/noborder_${stylename}.png -bordercolor "#${CBACKGROUND}" -border 5 palettes/colors_scheme_${stylename}_bg${CBACKGROUND}.png
        done
    fi

    #########################
    # Generate readme content
    #########################
    # URL
    if [ -n "${url}" ]; then
        ITEM="[${stylename}](${url})"
    else
        ITEM="${stylename}"
    fi

    # Author
    if [ -n "${author}" ]; then
        ITEM+=" by ${author}"
    fi

    SCHEMES+="${ITEM}"
    for idx in $BG_SEQS; do
        CBACKGROUND=${CBACKGROUNDS[$idx]}
        SCHEMES+=" | <img src='doc/palettes/colors_scheme_${stylename}_bg${CBACKGROUND}.png' />"
    done
    SCHEMES+="
"    

done < <(find ../ -name "*.yaml"  -printf "%f\n")
CONTRIBUTORS=$(git shortlog -s | sed -r 's/^.*?[0-9]\t+/- /g')

export SCHEMES
export CONTRIBUTORS
envsubst < README.tpl > ../README.md
