###
### SHELL PATH
###

PATHLIST=(
    ~/{.local/,}bin                     # User programs
    /usr/local/{,s}bin                  # Local admin programs
    {~/.haus/bin,/opt/haus/bin}         # Haus programs
    "$PATH"                             # Existing PATH
)

# Prune duplicate, non-searchable, and non-extant directories, as well as
# directories that are not owned by the current user or root.
export PATH="$(ruby -e '
    print ARGV.flat_map { |arg|
        arg.split(":").map! { |p| File.symlink?(p) ? File.expand_path(File.readlink(p), File.dirname(p)) : p }
    }.uniq!.select! { |path|
        if File.directory? path and File.executable? path
            stat = File.stat path
            stat.uid == Process.euid or stat.uid.zero?
        end
    }.join(":")
' -- "${PATHLIST[@]}")"

unset PATHLIST
