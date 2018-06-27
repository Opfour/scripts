#a rm inside /usr/local/bin that execs the real rm 
#basically places sanity checks inb4 the real rm.
#!/bin/sh

set -e
set -u

for arg; do
    case "$arg" in
        -?*) ;;
        *)
            realarg="$(realpath "$arg")"
            case "$realarg" in
                /|/usr|/var|/etc|/home|/bin|/lib|/lib64|/boot|/opt|/media|/root)

                    echo "refusing to remove $realarg" 1>&2
                    exit 100
                    ;;
            esac
            ;;
    esac
done

exec /bin/rm --one-file-system --preserve-root "$@"
