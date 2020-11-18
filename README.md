# Shadow

Shadow is a LLVM & CLang based compiler that allows for Windows binaries obfuscation.

### Compiling on Win 10

**Notes:**
* To the best of my knowledge, you can’t at this point create an out-of-source LLVM pass on windows.
* You cannot cross compile (you can’t build a Windows clang on a non-Win machine)

**Resources:**
* [Nice CLang overview](https://llvm.org/devmtg/2017-06/2-Hal-Finkel-LLVM-2017.pdf)
* [Writing an LLVM obfuscating pass](https://medium.com/@polarply/build-your-first-llvm-obfuscator-80d16583392b)

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