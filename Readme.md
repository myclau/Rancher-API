Objective
=========
This is for updating docker image in Already create stack in Rancher 1.x
Support update seperatly for normal service and sidekick service.

Prerequirement
==============

Install rancher cli
-------------------

Can be find in here:
https://github.com/rancher/cli/releases

How to use
===========

Local debug
-----------

1) After install the ranchercli
2) modify debug-param.sh with for rancher config and set dir of the ranchercli
3) if you just want to use ranchercli, you can run `. debug-param.sh`, and then run `~\ranchercli --help` assume you install it in home

Use in Jenkins or related
------------------------

1) create step with shell
2) define to use Bash `#!/bin/bash`
3) checkout `rancher-deploy.sh`, `rancher-lib.sh` ,`rancher-sidekick-deploy.sh`
4) Define all param same name in `debug-param.sh`
5) cd into script location
6) if normal deploy run `. rancher-deploy.sh`
7) if it is deploying the update job run `. rancher-sidekick-deploy.sh`