#!/bin/bash

docker run -ti --rm --name ruby-rvm --user "root" combro2k/ruby-rvm:latest ${@}
