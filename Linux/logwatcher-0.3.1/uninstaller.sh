#!/bin/bash

# Uninstall script for watcher

echo "Removing /etc/watcher and it's contents"
rm -rfv /etc/watcher
echo "Removing cron job"
rm -fv /etc/cron.d/watcher
echo "Removing logs (silent)"
rm -rf /var/logs/watcher
