# Install script for win-setup project
# by Patrick Wyatt 3/22/2013
#
# To run this command:
# @powershell -NoProfile -ExecutionPolicy Unrestricted -Command "iex ((new-object net.webclient).DownloadString('https://raw.github.com/webcoyote/win-setup/master/INSTALL.ps1'))"
#


# Fail on errors
$ErrorActionPreference = 'Stop'


#-----------------------------------------------
# Configuration -- change these settings if desired
#-----------------------------------------------

  # Where do you like your projects installed?
  # For me it is C:\dev but you can change it here:
  $DEVELOPMENT_DIRECTORY = $Env:SystemDrive + '\dev'

  # By default Chocolatey wants to install to C:\chocolatey
  # but lots of folks on Hacker News don't like that. Override
  # the default directory here:
  $CHOCOLATEY_DIRECTORY = $Env:SystemDrive + '\chocolatey'

  # Git has three installation mode:
  #   1. Use Git Bash only
  #   2. Run Git from the Windows Command Prompt
  #   3. Run Git and included Unix tools from the Windows Command Prompt
  #
  # You probably want #2 or #3 so you can use git from a DOS command shell
  # More details: http://www.geekgumbo.com/2010/04/09/installing-git-on-windows/
  #
  # Pick one:
  $GIT_INSTALL_MODE=3


#-----------------------------------------------
# Constants
#-----------------------------------------------
  # Git is assumed to be installed here, which is true
  # as of 2/7/2013. But I can't control what the package
  # manager does so I'll hardcode these here and check
  $GIT_INSTALL_DIR = ${Env:ProgramFiles(x86)} + '\Git'
  $GIT_CMD = $GIT_INSTALL_DIR + '\cmd\git.exe'


#-----------------------------------------------
#
#-----------------------------------------------
function Exec
{
    [CmdletBinding()]
    param (
        [Parameter(Position=0, Mandatory=1)]
        [ScriptBlock]$Command,
        [Parameter(Position=1, Mandatory=0)]
        [string]$ErrorMessage = "ERROR: command failed:`n$Command"
    )

    &$Command

    if ($LastExitCode -ne 0) {
        write-host $ErrorMessage
        exit 1
    }
}

<#
# What the fuck!?! PowerShell is supposed to be a scripting language
# for system administrators, not a descent into the bowels of hell!
# I understand *why* this happens, but not *how* a language could be
# designed to work like this!

  function Append ([String]$path, [String]$dir) {
    [String]::concat($path, ";", $dir)
  }
  [String]::concat("a;b;c", ";", "d") # => a;b;c;d
  Append("a;b;c", "d")                # => a;b;c d;
  Append "a;b;c", "d"                 # => a;b;c d;
  Append "a;b;c" "d"                  # => a;b;c;d
#>

#-----------------------------------------------
# Environment variables
#-----------------------------------------------
function AppendPath ([String]$path, [String]$dir) {
  $result = $path.split(';') + $dir.split(';') |
      where { $_ -ne '' } |
      select -uniq
  [String]::join(';', $result)
}
# AppendPath ";a;b;;c;" ";d;"    => a;b;c;d

function AppendEnvAndGlobalPath ([String]$dir, [String]$target) {
  # Add to this shell's environment
  $Env:Path = AppendPath $Env:path $dir

  # Add to the global environment; $target => { 'Machine', User' }
  $path = [Environment]::GetEnvironmentVariable('Path', $target)
  $path = AppendPath $path $dir
  [Environment]::SetEnvironmentVariable('Path', $path, $target)
}

function FindInEnvironmentPath ([String]$file) {
  [Environment]::GetEnvironmentVariable('Path', 'Machine').split(';') +
  [Environment]::GetEnvironmentVariable('Path', 'User').split(';') |
    where { $_ -ne '' } |
    foreach { join-path $_ $file } |
    Where-Object { Test-Path $_ } |
    Select-Object -First 1
}

#-----------------------------------------------
# Directory functions
#-----------------------------------------------
function MakeDirectory ([String]$dir) {
  if (Test-path $dir -PathType Container) {
    return
  }

  if (new-item $dir -itemtype directory) {
    return
  }

  write-host "Unable to create directory '$dir'"
  exit 1
}

#-----------------------------------------------
# Install Chocolatey package manager
#-----------------------------------------------
function InstallPackageManager () {
  # Set Chocolatey directory unless already set or program already installed
  if (! $Env:ChocolateyInstall) {
    $Env:ChocolateyInstall = $CHOCOLATEY_DIRECTORY
  }

  # Save install location for future shells. Any shells that have already
  # been started will not pick up this environment variable (Windows limitation)
  [Environment]::SetEnvironmentVariable(
    'ChocolateyInstall',
    $Env:ChocolateyInstall,
    'User'
  )

  # Install Chocolatey
  $url = 'http://chocolatey.org/install.ps1'
  iex ((new-object net.webclient).DownloadString($url))

  # Chocolatey sets the global path; set it for this shell too
  $Env:Path += "$Env:ChocolateyInstall\bin"

  # Install packages to C:\Bin so the root directory isn't polluted
  cinst binroot
}


#-----------------------------------------------
# Git
#-----------------------------------------------
function InstallGit () {

  # Install the git package
  cinst git

  # Verify git installed
  if (! (Test-Path $GIT_CMD) ) {
    write-host "ERROR: I thought I just installed git but now I can't find it here:"
    write-host ("--> " + $GIT_CMD)
    exit 1
  }

  # Verify git runnable
  &$GIT_CMD --version
  if ($LASTEXITCODE -ne 0) {
    write-host "ERROR: Unable to run git; did it install correctly?"
    write-host ("--> '" + $GIT_CMD + "' --version")
    exit 1
  }

  # Fix path based on git installation mode
  switch ($GIT_INSTALL_MODE) {
    1 {
      # => Use Git Bash only
      # blank
    }

    2 {
      # => Run Git from the Windows Command Prompt
      AppendEnvAndGlobalPath "$GIT_INSTALL_DIR\cmd" "User"
    }

    3 {
      # => Run Git and included Unix tools from the Windows Command Prompt
      AppendEnvAndGlobalPath "$GIT_INSTALL_DIR\bin" "User"
    }
  }

}

#-----------------------------------------------
# Tools
#-----------------------------------------------
function Install7Zip () {
  cinst 7zip
  AppendEnvAndGlobalPath "C:\Program Files\7-Zip" "User"
}
function InstallSysInternals () {
  cinst sysinternals
  AppendEnvAndGlobalPath "C:\bin\sysinternals" "User"
}


function InstallPathed () {
  # Download ZIP file
  $src  = "http://pathed.googlecode.com/files/pathed-08.zip"
  $name = [System.IO.Path]::GetFileName($src)
  $zip = join-path -path $env:temp -childpath $name
  $wc = New-Object System.Net.WebClient
  $wc.DownloadFile($src, $zip)

  $shell_app = new-object -com shell.application
  $zip_file = $shell_app.namespace($zip)
  $dst = $shell_app.namespace("C:\Bin")

  # 0x04 => do not display dialog box
  # 0x10 => yes to all
  $dst.Copyhere($zip_file.items(), 0x14)
}

#-----------------------------------------------
# Main
#-----------------------------------------------

MakeDirectory c:\bin
AppendEnvAndGlobalPath "c:\bin" "User"
MakeDirectory $DEVELOPMENT_DIRECTORY
InstallPackageManager
InstallGit
Install7Zip
InstallPathed
InstallSysInternals


# Can I mention here how frequently PowerShell violates the principle of least surprise?
