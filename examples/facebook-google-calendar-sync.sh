#!/bin/bash
source $HOME/.bashrc
rvm use ruby-1.9.3@facebook-google-calendar-sync
facebook-google-calendar-sync -f "http://www.facebook.com/ical/u.php?uid=UID&key=KEY"