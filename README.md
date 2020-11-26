# Shadow

Shadow is a LLVM & CLang based compiler that allows for Windows binaries obfuscation.

Shadow is currently implemented as an integral part of CLang and is invoked automatically as part of the compilation with `clang.exe`.

## Why?

Shadow was incepted as part of my research on executable similarity and specifically malware similarity (TODO: cite). I wanted to examin how reliant are static AV engines (exposed through VirusTotal (TM)) on meta data such as hard-coded strings and debug info.

It can also be of use to software authors that want to protect their code from RE.

## Notes
* As opposed to many tools build upon LLVM, Shadow is *not* implemented as a pass, but instead coded as an integral part of CLang. To the best of my knowledge, you can’t at this point create an out-of-source LLVM pass on windows.
* You cannot cross compile (you can’t build a Windows clang on a non-Win machine)

## Shadow on \*nix systems
There is nothing preventing Shadow from working on Linux and Mac distributions. It shoudl work just fine, I just didn't get around to testing it. 

## Status & Contributing

Shadow is in a very initial state, and only allows for basic string obfuscation through RORing with a random value. Decoding is done JIT-style by allocating a string for each usage and decoding the obfuscated string to it (and then reading it).

Although being a trivial transformation, I have yet to find a decent open source tool for doing this. Furthermore, the string transformation seems to be enough to avoid static detection of malware (TODO: cite).

A list of interesting transformation I hope to explore and perhaps implement:
* More string obfuscations through concatenation, whitelist, etc.
* Dead code addition
* Instruction substitution
* Function splitting, cloning and merging.
* Live code addition

**You are very much encouraged to suggest and implement any and all features through issues / pull requests**

The code for Shadow was added under the `CodeGen` module and is located in files
`clang/lib/CodeGen/ShadowObfuscator.{h, cpp}`

## Compiling on Win 10

**Prerequisites:**
* Install Build Tools for VS from [here](https://visualstudio.microsoft.com/downloads/#) (check the “C++ build tools” box and under the “Installation details” may want to also check ‘C++ ATL’ box).
    * You can install it via command line by downloading https://aka.ms/vs/16/release/vs_buildtools.exe and running `vs_buildtools.exe --quiet --wait --norestart --nocache  --add 	Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Component.VC.ATLMFC --includeRecommended`
* Install Git, CMake and Python3, make sure they are added to path.
    * [Unchecked] You can install deps using Chocolatey:
        * Install choco from powershell: `iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))`
        * `choco install cmake git python3` 
* Clone the Shadow repo `git clone --config core.autocrlf=false https://github.com/nimrodpar/Shadow.git`

**Build:**
* Open a `cmd.exe` and run `build.bat`. You can rebuild under the same shell by invoking `ninja clang`
* To (re)build in a new shell, open a `cmd.exe`, run `env.bat`, `cd` into `build` and `ninja clang`

**Test:**
* Testing requires grep and sed, you can install them with chocolatey `choco install grep sed`
* Open a `cmd.exe`, run `env.bat`, `cd` into `build` and `ninja check-llvm clang-test`

## Resources
* [Nice CLang overview](https://llvm.org/devmtg/2017-06/2-Hal-Finkel-LLVM-2017.pdf)
* [Writing an LLVM obfuscating pass](https://medium.com/@polarply/build-your-first-llvm-obfuscator-80d16583392b)
* https://github.com/tsarpaul/llvm-string-obfuscator/blob/master/StringObfuscator/StringObfuscator.cpp
* https://llvm.org/docs/ProgrammersManual.html
* https://llvm.org/docs/LangRef.html
* https://llvm.org/docs/GetElementPtr.html
