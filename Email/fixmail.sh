#!/bin/bash

# Set catch-all address to blackhole
for i in `ls /etc/valiases`; do perl -p -i -e 's/\*:.+/\*: :blackhole:/g' /etc/valiases/$i; done

# Empty out default inboxes
for i in `ls /home/*/mail/inbox`; do > $i; done
