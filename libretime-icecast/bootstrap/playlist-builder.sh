
#### Setup playlist for stream fallback ####

# Sort-out the playlist file...
touch /etc/ezstream_playlist.m3u


function pullCCMedia() {

    # There's no fallback media - Let's just use some Creative Commons Media for now...
    git clone https://github.com/ned-kelly/moh-cc.git /opt/cc-media/

    FALLBACK_MEDIA=`find /opt/cc-media/ -type f -name *.mp3`
    echo "$FALLBACK_MEDIA" > /etc/ezstream_playlist.m3u

}

FALLBACK_MEDIA=`find /external-media/imported -type f -name *.mp3`
if [ $? -eq 0 ]; then
    if [[ $(echo "$FALLBACK_MEDIA" | wc -l) -ge 0 ]];then
        # There's already imported tracks from Libretime - Let's use them for our fallback stream...
        echo "$FALLBACK_MEDIA" > /etc/ezstream_playlist.m3u
    else
        pullCCMedia
    fi
else
    pullCCMedia
fi

echo "Wrote ezstream_playlist.m3u & Reloaded ezstream"

# See here: https://icecast.imux.net/viewtopic.php?t=6438&sid=98f01c25910c27fa7276d89ae24def64 -- Supervisor will take care of the rest...
killall -HUP ezstream
