# haus completion. Depends on bash-completion 2.0

type _get_comp_words_by_ref _filedir &>/dev/null &&

_haus() {
    local cur prev cword words reply space=1
    _get_comp_words_by_ref cur prev cword words

    if ((cword == 1)); then
        reply=(link copy unlink)
    elif [[ $cur == -* ]]; then
        reply=(--path --users --force --noop --quiet --help)
        if [[ "${words[1]}" == 'link' ]]; then
            reply+=(--absolute)
        elif [[ "${words[1]}" == 'unlink' ]]; then
            reply+=(--all --broken)
        fi
    elif [[ $prev == @(-p|--path) ]]; then
        _filedir -d
        reply="${COMPREPLY[@]}"
    elif [[ $prev == @(-u|--users) ]]; then
        space=0
        reply=($(ruby -r etc -e '
            cur = ARGV.first.split ",", -1
            pre = cur[0...-1].join ","
            pre << "," unless pre.empty?
            pat = Regexp.new "\\A%s" % cur.last, "i"
            us = []
            while u = Etc.getpwent
                if u.name =~ pat and File.directory? u.dir
                    us << pre + u.name + ","
                end
            end
            puts us
        ' -- "$cur"))
    fi

    if ((space)); then
        local i
        for ((i = 0; i < ${#reply[@]}; ++i)); do
            reply[i]="${reply[i]} \
"
        done
    fi

    local IFS=$'\n'
    COMPREPLY=($(compgen -W "${reply[*]}" -- "$cur"))
    unset IFS
} && complete -F _haus -o nospace haus

# vim:ft=sh:
