---
layout: post
title: Look Ma, No GUI! Automating Peakboard Installs from the Command Line
date: 2023-03-01 00:00:00 +0200
tags: administration
image: /assets/2026-05-25/title.png
image_header: /assets/2026-05-25/title.png
bg_alternative: true
read_more_links:
  - name: PowerShell and Remote Desktop Connection - How to really dismantle a Peakboard box
    url: /PowerShell-and-Remote-Desktop-How-to-really-dismantle-a-Peakboard-box.html
  - name: Side-by-Side - Making Peakboard BYOD Play Nice among other Windows Apps
    url: /Side-by-Side-Making-Peakboard-BYOD-Play-Nice-among-other-Windows-Apps.html
  - name: The Log Files Strike Back - A Nerd's Guide to Peakboard Debugging
    url: /The-Log-Files-Strike-Back-A-Nerds-Guide-to-Peakboard-Debugging.html
  - name: Bed time stories - Three ways to shut down a Peakboard Box remotely
    url: /Bed-time-stories-Three-ways-to-shut-down-a-Peakboard-box-remotely.html
---
Let's be honest, clicking through installation wizards is nobody's idea of a good time. Doing it once is fine, but doing it ten times across ten machines on a Monday morning? That's where the command line comes to the rescue. Both the Peakboard Designer and the BYOD Runtime come as self-contained executables that happily accept command line parameters for fully silent, unattended installations. No wizard, no clicking, no coffee-spilling moments of distraction mid-install.

Before we dive in, let's get the boring stuff out of the way. We need admin rights to run both installers, and the target machine must be running at least Windows 10 20H1 (build 19041). Both setups are .NET 8.0 self-contained apps, so we don't need to worry about installing any runtime first. And if we want to check whether everything went smoothly, an exit code of `0` means all good.

The binaries can be downloaded directly from:
- [PeakboardSetup.exe](https://downloads.peakboard.com/download/Peakboard/master/PeakboardSetup.exe) for the Designer
- [PeakboardRuntimeSetupUI.exe](https://downloads.peakboard.com/download/Peakboard/master/PeakboardRuntimeSetupUI.exe) for the BYOD Runtime

## Installing the Peakboard Designer silently

The Designer installer is `PeakboardSetup.exe`, and it comes with a neat set of parameters that let us control every aspect of the installation:

| Parameter | Type | Default | Description |
|---|---|---|---|
| `Silent` | Bool | `False` | Runs the setup without any UI |
| `InstallPath` | String | `C:\Program Files\Peakboard\Designer` | Installation directory |
| `CreateStartMenuShortcuts` | Bool | `True` | Creates Start menu shortcuts |
| `ContinueInstallation` | Bool | `False` | Skips the welcome page and installs right away |
| `Update` | Bool | `False` | Update mode that checks for running Designer or Runtime processes |

The quickest way to get a fully silent installation with all the defaults is just one line:

{% highlight bash %}
PeakboardSetup.exe Silent=True ContinueInstallation=True
{% endhighlight %}

If we want to get fancy and install to a custom directory while skipping the Start menu shortcuts, we go with:

{% highlight bash %}
PeakboardSetup.exe Silent=True InstallPath="D:\Peakboard\Designer" CreateStartMenuShortcuts=False
{% endhighlight %}

For those of us who prefer the dash syntax in our scripts, that works too:

{% highlight bash %}
PeakboardSetup.exe -Silent True -InstallPath "D:\Peakboard\Designer"
{% endhighlight %}

## Installing the BYOD Runtime silently

The BYOD Runtime installer is `PeakboardRuntimeSetupUI.exe`. It has a few more knobs to turn than the Designer because the runtime needs to know things like whether it should start automatically with Windows or whether to enforce encrypted connections.

| Parameter | Type | Default | Description |
|---|---|---|---|
| `Silent` | Bool | `False` | Runs the setup without any UI |
| `InstallPath` | String | `C:\Program Files\Peakboard` | Installation directory |
| `ContinueInstallation` | Bool | `False` | Skips the video and welcome page |
| `CreateStartMenuShortcuts` | Bool | `True` | Creates Start menu shortcuts |
| `AddToStartup` | Bool | `False` | Adds the runtime to Windows autostart |
| `BlockUnencryptedConnection` | Bool | `False` | Blocks unencrypted connections to the runtime |
| `RunOnPeakboardBox` | Bool | `False` | Configures the runtime to run on a Peakboard Box |

The no-frills silent installation looks like this:

{% highlight bash %}
PeakboardRuntimeSetupUI.exe Silent=True ContinueInstallation=True
{% endhighlight %}

In a real-world production scenario, we probably want the runtime to launch automatically after a reboot and lock things down with encrypted connections:

{% highlight bash %}
PeakboardRuntimeSetupUI.exe Silent=True InstallPath="D:\Peakboard" AddToStartup=True BlockUnencryptedConnection=True
{% endhighlight %}

And if we are deploying directly on a Peakboard Box, there is a dedicated flag for that:

{% highlight bash %}
PeakboardRuntimeSetupUI.exe Silent=True RunOnPeakboardBox=True
{% endhighlight %}

## The secret config file

Here is a neat little detail that can make life even easier for large-scale deployments. The Runtime installer checks for a configuration file at `C:\ProgramData\Peakboard\LocalState\Setup.config` before it starts. This is a simple key-value file that looks like this:

{% highlight ini %}
InitialVersion=3.12.0.1
RunOnBox=False
InstallPath=C:\Program Files\Peakboard
RunOnPeakboardBox=False
InstallService=True
CreateStartMenuShortcuts=True
AddToStartup=False
BlockUnencryptedConnection=False
WriteToRegistry=True
ProductName=Peakboard Runtime
VersionNumber=4.2
ProductPublisher=Peakboard GmbH
{% endhighlight %}

After the very first installation, this file is created automatically and reflects the settings that were used. The clever part is that we can modify this file before running the installer on another machine. If we pre-deploy a tweaked `Setup.config` to the target machine, the installer picks up those values as its defaults. And if we still pass command line parameters on top, they override whatever is in the config file. So the hierarchy is: command line beats config file beats built-in defaults. This makes `Setup.config` perfect for setting organization-wide defaults while still allowing per-machine overrides when needed.

## Conclusion

That's it. No more wizard fatigue. Whether we are rolling out the Designer to a team of engineers or deploying the BYOD Runtime across a fleet of shop floor machines, a single command line is all it takes. And with `Setup.config` in our back pocket, we can even pre-bake organization-wide defaults and let the installer do the thinking for us. Happy scripting!
