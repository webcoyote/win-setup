# Win-setup - Basic Windows configuration for development 

    @powershell -NoProfile -ExecutionPolicy Unrestricted -Command "iex ((new-object net.webclient).DownloadString('https://raw.github.com/webcoyote/win-setup/master/INSTALL.ps1'))"

That's it!

## What does it do?

The installation script installs and configures the required software:

* [Chocolatey](http://chocolatey.org/) (command-line software installation)
* [Git](http://git-scm.com/) (revision control software)
* [7-Zip](http://www.7-zip.org/) (file archiver)
* [Pathed](http://code.google.com/p/pathed/) (command-line path editor)

# Author

Author:: Patrick Wyatt (pat@codeofhonor.com)

If this doesn't work it is probably my fault, I would appreciate your feedback so I can fix it for you :)
