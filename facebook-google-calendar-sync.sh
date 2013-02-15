#!/bin/bash
source $HOME/.bashrc
rvm use ruby-1.9.3@facebook-google-calendar-sync
ruby `dirname $0`/facebook-google-calendar-sync.rb