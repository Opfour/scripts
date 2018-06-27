#!/bin/bash
#Want to clear the exim queue from the command line rather than logging into the WHM?
#
#run the following as root.
#
for i in `exim -bpr|awk {'print $3'}`;do /usr/sbin/exim -v -Mrm $i;done

