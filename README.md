iMirror
=======
`/sBin/iMirror v0.4`

OverView
--------
iNotify Mirror &amp; Sync Bash App

Automatically Mirrors /sBin Workspace to Development WebServer's DocumentsRoot on Network
Transfering Starts ONLY when Workspace Has a Modified File Using Kernel's INotify Module
Ignores All Files and/or Directories Which is Hidden
Sets The Mirroed Files Permissions & [U/G]UID(NOT Directories)

Requirements
------------
* Kernel 2.6.13+
* LibNotify/NotifyOSD

Usage
-----

```bash
./iMirror.sh -s=192.168.16.4 -w=/workspace/ -d=/var/www/  -v -m=700 -o=user:group -n
```

License
-------
[MIT License](http://slashsbin.mit-license.org/)



