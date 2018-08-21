###
### SHELL PATH
###

__PATHLIST__=(
    ~/{.local/,}bin                     # User programs
    /usr/local/{,s}bin                  # Local admin programs
    {~/.haus/bin,/opt/haus/bin}         # Haus programs
    "$PATH"                             # Existing PATH
)

__IFS__=$IFS
IFS=':' __PATHLIST__=(${__PATHLIST__[@]})
IFS=$__IFS__

__PATH__=''
declare -A __PATHSET__=''

# Prune duplicate, non-searchable, and non-extant directories, as well as
# directories that are not owned by the current user or root.
for p in "${__PATHLIST__[@]}"; do
    # Resolve symlinks
    [[ -L "$p" ]] && p="$(realpath -e "$p")"

    # Skip duplicates
    [[ -z "${__PATHSET__["$p"]}" ]] || continue
    __PATHSET__["$p"]=1

    # Skip non-searchable directories
    [[ -d "$p" && -x "$p" ]] || continue

    # Skip directories owned by other non-root users
    [[ -O "$p" ]] || [[ "$(stat -c %u "$p")" -eq 0 ]] || continue

    __PATH__+="${p}:"
done

export PATH="${__PATH__%:}"

unset __PATHLIST__ __IFS__ __PATH__ __PATHSET__ p
