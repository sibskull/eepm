#!/bin/bash

# TODO: use epm from the sources

fatal()
{
    exit 1
}

TDIR=~/epm-play-versions
EDIR=~/epm-errors
LDIR=~/epm-logs
mkdir -p $TDIR/ $EDIR/ $LDIR/

rm -f $EDIR/errors.txt

EPM=$(realpath $(dirname $0)/../bin/epm)

install_app()
{
    local app="$1"
    local applog="$1"
    local alt="$2"
    [ -n "$alt" ] && applog="$applog.$alt"

    echo "epm play $app $alt"
    $EPM play --verbose --auto $app $alt >$EDIR/$applog 2>&1 || return

    mv -f $EDIR/$applog $LDIR/$applog

    local pkgname="$($EPM play --package-name $app $alt)"
    $EPM print version for package $pkgname > $TDIR/$pkgname 2>$EDIR/$pkgname && rm -f $EDIR/$pkgname
    [ -s $TDIR/$pkgname ] || echo "empty file $TDIR/$pkgname" >>$EDIR/errors.txt
}

install_app_alt()
{
    local app="$1"
    local productalt="$($EPM play --product-alternatives $app)"

    if [ -z "$productalt" ] ; then
        install_app $app
        return
    fi

    # оставляем дефолтный вариант в конце в системе
    for i in $productalt "" ; do
        $EPM play --remove --auto $app
        install_app $app $i
    done
}

if [ -n "$1" ] ; then
    install_app_alt "$1"
    exit
fi

# install/update all
$EPM play --list-all --short | while read app ; do
    install_app_alt $app </dev/null
done

commit_git()
{
    cd "$1" || return
    [ -d .git ] || git init
    git add *
    git commit -m "updated"
}

commit_git $TDIR
commit_git $EDIR
commit_git $LDIR

cd $TMP
rm -rf tmp.* rpm-tmp.*

exit 0