# Shadow

Shadow is a LLVM & CLang based compiler that allows for Windows binaries obfuscation.

## Why?

Shadow was incepted as part of my research on executable similarity and specifically malware similarity (TODO: cite). I wanted to examin how reliant are static AV engines (exposed through VirusTotal (TM)) on meta data such as hard-coded strings and debug info.

## Notes
* As opposed to many tools build upon LLVM, Shadow is *not* implemented as a pass, but instead coded as an integral part of CLang. To the best of my knowledge, you can’t at this point create an out-of-source LLVM pass on windows.
* You cannot cross compile (you can’t build a Windows clang on a non-Win machine)


## Status & Contributing

Shadow is in a very initial state, and only allows for basic string obfuscation through RORing with a random value. Decoding is done JIT-style be allocating a string for each usage and decoding the obfuscated string to it (and then reading it).

Although being a trivial transformation, I have yet to find a decent open source tool for doing this. Furthermore, the string transformation seems to be enough to avoid static detection of malware (TODO: cite).

A list of interesting transformation I hope to explore and perhaps implement:
* More string obfuscations through concatenation, whitelist, etc.
* Dead code addition
* Instruction substitution
* Function splitting, cloning and merging.
* Live code addition

**You are very much encouraged to suggest and implement any and all features through issues / pull requests**

## Compiling on Win 10

**Prerequisites:**
* Install Build Tools for VS from [here](https://visualstudio.microsoft.com/downloads/#) (check the “C++ build tools” box and under the “Installation details” may want to also check ‘C++ ATL’ box).
    * [Unchecked] You can install it via command line by downloading https://aka.ms/vs/16/release/vs_buildtools.exe and running `vs_buildtools.exe --quiet --wait --norestart --nocache  --add 	Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Component.VC.ATLMFC --includeRecommended`
* Install Git, CMake and Python3, make sure they are added to path.
    * [Unchecked] You can install deps using Chocolatey:
        * Install choco from powershell: `iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))`
        * `choco install cmake git python3` 
* Clone the Shadow repo `git clone --config core.autocrlf=false https://github.com/nimrodpar/Shadow.git`

**Build with Ninja (preferred):**
* Open a `cmd.exe` and run `build.bat`. You can rebuild under the same shell by invoking `ninja -j8 clang`
* To (re)build in a new shell, open a `cmd.exe`, run `env.bat`, `cd` into `build` and `ninja -j8 clang`

**Build with CMake (not recommended):**
* Open a “Developer Command Prompt for VS 2019”
* Configure the build:
```
mkdir build && cd build
cmake -G "Visual Studio 16 2019" -DLLVM_ENABLE_PROJECTS=clang -A x64 -Thost=x64 -DLLVM_TARGETS_TO_BUILD="AArch64" ..\llvm   
```
* To (re)Build:
```
cmake --build
```

## Resources
* [Nice CLang overview](https://llvm.org/devmtg/2017-06/2-Hal-Finkel-LLVM-2017.pdf)
* [Writing an LLVM obfuscating pass](https://medium.com/@polarply/build-your-first-llvm-obfuscator-80d16583392b)
