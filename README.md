# Friday Night Funkin' - Step Engine - Modded Psych Engine

The engine currently uses the ["FNF Mistful Crimson Morning Fan-Made Build"](https://gamejolt.com/games/mcmbuildfan/1089544) for initial testing; in the future, it will be separated from the mod.

## Installation:
You must have [Haxe version 4.2.5](https://haxe.org/download/version/4.2.5/), seriously, stop using older or newer versions, it won't work!

open up a Command Prompt/PowerShell or Terminal, type `haxelib install hmm`

after it finishes, simply type `haxelib run hmm install` in order to install all the needed libraries for *Psych Engine!*

## Customization:

if you wish to disable things like *Lua Scripts* or *Video Cutscenes*, you can read over to `Project.xml`

inside `Project.xml`, you will find several variables to customize Psych Engine to your liking

to start you off, disabling Videos should be simple, simply Delete the line `"VIDEOS_ALLOWED"` or comment it out by wrapping the line in XML-like comments, like this `<!-- YOUR_LINE_HERE -->`

same goes for *Lua Scripts*, comment out or delete the line with `LUA_ALLOWED`, this and other customization options are all available within the `Project.xml` file

## Step Engine Credits:
* MARD - Programmer And Artist


## Psych Engine:
* Shadow Mario - Programmer
* RiverOaken - Artist
* Yoshubs - Assistant Programmer

### Special Thanks
* bbpanzu - Ex-Programmer
* Yoshubs - New Input System
* SqirraRNG - Crash Handler and Base code for Chart Editor's Waveform
* KadeDev - Fixed some cool stuff on Chart Editor and other PRs
* iFlicky - Composer of Psync and Tea Time, also made the Dialogue Sounds
* PolybiusProxy - .MP4 Video Loader Library (hxCodec)
* Keoiki - Note Splash Animations
* Smokey - Sprite Atlas Support
* Nebula the Zorua - LUA JIT Fork and some Lua reworks
_____________________________________

# Features

Since it's a modified version of Psych Engine, it includes practically all of its features.

**However, keep in mind that it uses version 0.7.1h of the engine.**

## Step Engine Features


### Mods Psych Engine

Yes, it supports Psych Engine mods, but only for versions 0.7 through 0.7.1h. Note that P-Slice is not supported either


### SM files

Sure, it has support for .sm files—or rather, a converter that turns .sm files into .JSON


### StepMania Mode

It has a separate Freeplay section where you can find the .sm (StepMania) songs.

#### Freeplay

All songs will appear in the StepMania Freeplay list.

![](https://github.com/user-attachments/assets/3ab9793b-4021-4ad4-a7b5-c91fbdb0d3c5)

#### Step Dancing Options

Gameplay Modifiers Options Screen - StepMania Mode

![](https://github.com/user-attachments/assets/88f40700-46b8-43a2-b90e-eab153544132)

#### Results Screen

Every time you finish a song, a results screen will pop up. This also applies to regular FNF songs.

![](https://github.com/user-attachments/assets/80d2a560-e38f-41ad-882a-8c83d51ed4be)

### New Main Menu
#### Main Menu Changes:

* Added the StepMania Freeplay section

Displays your current country along with its flag

![](https://github.com/user-attachments/assets/9166cd92-f829-4b5e-8e9d-bb66d87bc50b)


