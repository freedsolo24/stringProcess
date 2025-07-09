/status:success/ {
    s/.*user:([a-z]*).*ip:([0-9.]*)/[LOGIN] user=\1 ip=\2/p
    b
}
    s/.*user:([a-z]*).*ip:([0-9.]*)/[WARNING] user=\1 ip=\2/p
    $ a\
