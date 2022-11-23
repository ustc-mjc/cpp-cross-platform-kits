
# Copyright (c) 2022 The VolcEngineRTC project authors. All Right Reserved.
#Requires -RunAsAdministrator
<#
    the script will install base cmdlet tools:
        -  choco >= 1.2.0
        -  python-3.10.8
        -  git-2.38.1
        -  git-lfs-3.2.0
        -  cmake 3.24.1
        -  nasm 2.15.05
        -  ninja 1.11.1
        -  StrawberryPerl 5.32.1.1
        -  rtcbuild release version
    the script will config:
        - gitconfig for bytedance gitlab

    the script will install base local dev IDE tools:
        -  vscode
        # for windows dev
        -  visual studio 2019
        -  windows platform sdk
        # for android dev
        -  android studio
        -  jdk
        -  ndk
        -  android sdk
        -  qt5.14.2

    after run this script, you can git clone repo from gitlab
#>

param([string]$help = "", [string]$userName = "", [string]$install_as = "true", [string]$install_qt = "true")

$pacakageLists = @(
    @{"name"               = "winget"
        "cliName"          = "winget"
        "version"          = "1.0"
        "cliVersionString" = "1.3.2691"
        "insatllParams"    = ""
        "installMod"       = "other"
        "installInImage"   = "true"
    },
    @{"name"               = "choco"
        "cliName"          = "choco"
        "version"          = "1.2.0"
        "cliVersionString" = "1.2.0"
        "insatllParams"    = ""
        "installMod"       = "other"
        "installInImage"   = "true"
    },
    @{"name"               = "python3"
        "cliName"          = "python3"
        "version"          = "3.10.8"
        "cliVersionString" = "Python 3.10.8"
        "insatllParams"    = '--params "/InstallDir:C:\Python310 /NoLockdown"'
        "installMod"       = "choco"
        "installInImage"   = "true"
    },
    @{"name"               = "git"
        "cliName"          = "git"
        "version"          = "2.38.1"
        "cliVersionString" = "git version 2.37.0.windows.1"
        "insatllParams"    = "--params `"/GitAndUnixToolsOnPath /NoGitLfs /NoAutoCrlf`""
        "installMod"       = "choco"
        "installInImage"   = "true"
    },
    @{"name"               = "git-lfs"
        "cliName"          = "git-lfs"
        "version"          = "3.2.0"
        "cliVersionString" = "git-lfs/3.2.0 (GitHub; windows amd64; go 1.18.2)"
        "insatllParams"    = ""
        "installMod"       = "choco"
        "installInImage"   = "true"
    },
    @{"name"               = "cmake"
        "cliName"          = "cmake"
        "version"          = "3.24.3"
        "cliVersionString" = "cmake version 3.24.3 CMake suite maintained and supported by Kitware (kitware.com/cmake)."
        "insatllParams"    = "--installargs `'`"ADD_CMAKE_TO_PATH=System`'`""
        "installMod"       = "choco"
        "installInImage"   = "true"
    },
    @{"name"               = "nasm"
        "cliName"          = "nasm"
        "version"          = "2.15.05"
        "cliVersionString" = ""
        "insatllParams"    = ''
        "installMod"       = "choco"
        "installInImage"   = "true"
    },
    @{"name"               = "ninja"
        "cliName"          = "ninja"
        "version"          = "1.11.1"
        "cliVersionString" = ""
        "insatllParams"    = ''
        "installMod"       = "choco"
        "installInImage"   = "true"
    },
    @{"name"               = "StrawberryPerl"
        "cliName"          = "perl"
        "version"          = "5.32.1.1"
        "cliVersionString" = ""
        "insatllParams"    = ''
        "installMod"       = "choco"
        "installInImage"   = "true"
    },
    @{"name"               = "vscode"
        "cliName"          = "code"
        "version"          = "1.73.1"
        "cliVersionString" = "1.73.1 6261075646f055b99068d3688932416f2346dd3b x64"
        "insatllParams"    = ''
        "installMod"       = "choco"
        "installInImage"   = "false"
    },
    @{"name"               = "visual studio 2019"
        "cliName"          = ""
        "version"          = "2019"
        "cliVersionString" = ""
        "insatllParams"    = ''
        "installMod"       = "special"
        "installInImage"   = "true"
    },
    @{"name"               = "Microsoft.OpenJDK.11"
        "cliName"          = "java"
        "version"          = "11.0.17"
        "cliVersionString" = "openjdk 11.0.17 2022-10-18 LTS OpenJDK Runtime Environment Microsoft-6841889 (build 11.0.17+8-LTS) OpenJDK 64-Bit Server VM Microsoft-6841889 (build 11.0.17+8-LTS, mixed mode)"
        "insatllParams"    = "--accept-source-agreements --accept-package-agreements --rainbow"
        "installMod"       = "winget"
        "installInImage"   = "true"
    },
    @{"name"               = "Google.AndroidStudio"
        "cliName"          = ""
        "version"          = "2021.3.1.17"
        "cliVersionString" = ""
        "insatllParams"    = "--accept-source-agreements --accept-package-agreements --rainbow"
        "installMod"       = "winget"
        "installInImage"   = "false"
    },
    @{"name"               = "sdkmanager"
        "cliName"          = ""
        "version"          = "8.0"
        "cliVersionString" = "8.0"
        "insatllParams"    = ''
        "installMod"       = "special"
        "installInImage"   = "true"
    },
    @{"name"               = "platforms"
        "cliName"          = ""
        "version"          = @("android-27", "android-28", "android-31")
        "cliVersionString" = ""
        "insatllParams"    = ''
        "installMod"       = "sdkmanager"
        "installInImage"   = "true"
    },
    @{"name"               = "ndk"
        "cliName"          = ""
        "version"          = @("21.0.6113669", "21.1.6352462", "21.3.6528147", "22.1.7171670", "23.1.7779620")
        "cliVersionString" = ""
        "insatllParams"    = ''
        "installMod"       = "sdkmanager"
        "installInImage"   = "true"
    },
    @{"name"               = "platform-tools"
        "cliName"          = ""
        "version"          = @(" ")
        "cliVersionString" = ""
        "insatllParams"    = ''
        "installMod"       = "sdkmanager"
        "installInImage"   = "true"
    },
    @{"name"               = "cmake"
        "cliName"          = ""
        "version"          = @("3.10.2.4988404", "3.22.1")
        "cliVersionString" = ""
        "insatllParams"    = ''
        "installMod"       = "sdkmanager"
        "installInImage"   = "true"
    },
    @{"name"               = "qt"
        "cliName"          = ""
        "version"          = "5.14.2"
        "cliVersionString" = ""
        "insatllParams"    = ''
        "installMod"       = "special"
        "installInImage"   = "true"
    }
)

# define some functions
function Checkpoint-GlobalParam {
    param(
        $param
    )
    if (-not $param) {
        Write-Error "you need to config git, but userName not found, please run script with -userName"
        Exit
    }
}

function Test-Command {
    param (
        [string]$Command, [string]$CommandVersion, [bool]$PrintVersion = $True
    )
    $CommandStatus = $False
    $null = Get-Command $Command
    if ($?) {
        if ($Command -eq "python3" -and (-not $(."$Command" --version))) {
            Out-ColorMessage -Message "$Command not found"
            $CommandStatus = $False
            return $CommandStatus
        }
        Out-ColorMessage -Message "$Command has been installed"
        if ($PrintVersion) {
            $CommandVersionString = [string]$(Invoke-Expression "$Command --version")
            # Out-ColorMessage -Message "Command: $Command, --version: $CommandVersionString"
            if ($CommandVersionString -match "\d+(\.\d+){0,2}") {
                $currentCmdVersion = $Matches.0
                Out-ColorMessage -Message "$Command's version is: $currentCmdVersion"
                if ($currentCmdVersion -ge $CommandVersion -or $Command -eq 'perl') {
                    $CommandStatus = $True
                }
                else {
                    # remove or upgrade origin's package, return false
                    winget uninstall --name $Command --version $CommandVersion -h
                    Out-ColorMessage -Message "target's version is: $CommandVersion, will remove or upgrade origin version: $currentCmdVersion"
                }
            }
        }
    }
    else {
        # please check your network, open vpn and retry again!
        Out-ColorMessage -Message "$Command not found"
        $CommandStatus = $False
    }
    return $CommandStatus
}

function Test-GitAuth {
    if ($Env:BITS_CLOUD_BUILD_ENV) {
        return
    }
    if (-not (Test-Path $home\.gitconfig)) {
        Checkpoint-GlobalParam -param $userName
        New-Item -Path $home -Name .gitconfig -ItemType file
        Out-ColorMessage -Message "userName: $userNasme, please make sure userName is same with your bytedance email prefix!"
        $gitconfigContent = '
        [init]
            templatedir = {0}/.gittemplates
        [user]
            name = {1}
            email = {1}@bytedance.com
        [url "ssh://{1}@git.byted.org:29418"]
            insteadOf = https://git.byted.org 
        [url "git@code.byted.org:"]
            insteadOf = https://code.byted.org/
        ' -f $home.Replace("\", "/"), $userName
        $gitconfigContent | Out-File "$home\.gitconfig" -Encoding utf8
    }

    if (-not (Test-Path $home\.ssh\config)) {
        Checkpoint-GlobalParam -param $userName
        if (Test-Path $home\.ssh) {
            Remove-Item $home\.ssh -Recurse
        }
        New-Item -Path $home -Name .ssh -ItemType directory
        New-Item -Path $home\.ssh -Name config -ItemType file
        $sshconfigContent = "
        Host *
            GSSAPIAuthentication yes
            GSSAPIDelegateCredentials no
        Host git.byted.org
            Hostname git.byted.org
            Port 29418
            User $userName
        Host review.byted.org
            Hostname git.byted.org
            Port 29418
            User $userName
        Host *.byted.org
            GSSAPIAuthentication yes
            User $userName"
        # powershell 5.x will generator utf8 file with bom, but git can't recognize it, so we write file with python3 to generator utf8 file without bom
        # $sshconfigContent | Out-File $home\.ssh\config -Encoding utf8
        'with open("{0}","w",encoding="utf-8") as f:' -f "$home\.ssh\config".Replace("\", "/") | Out-File $home\write.py -Encoding utf8
        Add-Content -Path $home\write.py -Value ('   f.write("""{0}""")' -f $sshconfigContent) -Encoding utf8
        python3 $home\write.py
        Remove-Item $home\write.py
    }
    if (-not (Test-Path $home\.ssh\id_ed25519.pub)) {
        Checkpoint-GlobalParam -param $userName
        $null = Test-Command -Command ssh-keygen -PrintVersion $False
        Out-ColorMessage -Message "generate your ssh key, please press enter and continue!!!"
        ssh-keygen -t ed25519 -C "$userName@bytedance.com"
        
        # after generater ssh key, please go to GitLab configuration page: https://code.byted.org/profile/keys
        if (Test-Path $home\.ssh\id_ed25519.pub) {
            $sshkeyContent = Get-Content "$home\.ssh\id_ed25519.pub"
            Out-ColorMessage -Message "your ssh key is: $sshkeyContent"
            Out-ColorMessage -Message "now please visit https://code.byted.org/profile/keys to config your gitlab sshkey, after config, you need input Y, else input N"
            $userResult = Read-Host "are you finish gitlab sshkey configuration?"
            if ($userResult -eq "Y") {
                Out-ColorMessage -Message "use Command: ssh -T code.byted.org to check your git access right"
                Out-ColorMessage -Message "please press yes to continue!!!"
                $gitSshStatus = ssh -T code.byted.org |  Select-String "Welcome to Gitlab, $userName"
                if ($gitSshStatus) {
                    Out-ColorMessage -Message "configurations! you has finished your git sshkey config, now you can git clone gitlab repo"
                }
                else {
                    Out-ColorMessage -Message "config gitlab sshkey failed, please check -userName and config gitlab sshkey on https://code.byted.org/profile/keys"
                    Exit
                }
            }
            else {
                Out-ColorMessage -Message "config gitlab sshkey failed, please config gitlab sshkey on https://code.byted.org/profile/keys"
                Exit
            }
        }
    }
}
function Out-ColorMessage {
    param (
        [string]$ForegroundColor = "yellow", [string]$BackgroundColor = "black", [string]$Message
    )
    Write-Host $Message -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor
}

function Invoke-FileDownload {
    param (
        [string]$Uri, [string]$OutFile, [int]$RetryCount = 3
    )
    $downloadStatus = $False
    for ($i = 0; $i -lt $RetryCount; $i++) {
        <# Action that will repeat until the condition is met #>
        if (-not $downloadStatus) {
            Invoke-WebRequest -Uri $Uri -OutFile $OutFile
            if (Test-Path $OutFile) {
                $downloadStatus = $True
                break
            }
        }
    }
    return $downloadStatus
    
}

function Invoke-InstallAndroidTools {
    param (
        [string]$SdkmanagerPath, [string]$AndroidHome = [Environment]::GetEnvironmentVariable('ANDROID_SDK_ROOT', 'Machine'), [string]$ToolsType, [string]$ToolsVersion 
    )
    if ($ToolsType -eq "platform-tools") {
        if (-not $(Test-Path "$AndroidHome\$ToolsType")) {
            Out-ColorMessage -Message "start install android tools: $ToolsType"
            ."$androidSdkManager" --install "$ToolsType"
        }
    }
    elseif (-not $(Test-Path "$AndroidHome\$ToolsType\$ToolsVersion")) {
        Out-ColorMessage -Message "start install android tools: $ToolsType;$ToolsVersion"
        ."$androidSdkManager" --install "$ToolsType;$ToolsVersion"    
    }
    
}

function Install-PackageWithChocoOrOther {
    param (
        [string]$PackageName, [string]$CliPackageName, [string]$PackageVersion, [string]$PackageParms, [int]$RetryCount = 3
    )
    if (-not $(Test-Command -Command $CliPackageName -CommandVersion $PackageVersion)) {
        for ($i = 0; $i -lt $RetryCount; $i++) {
            $installStatus = $False
            Out-ColorMessage -Message "start install $PackageName, count is: $i, please wait for a moment!"
            switch ($PackageName) {
                { $_ -eq "winget" } {
                    # https://github.com/microsoft/winget-cli/releases/download/v1.3.2691/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle
                    $wingetUri = "https://github.com/microsoft/winget-cli/releases/download/v1.3.2691/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
                    Invoke-FileDownload -Uri $wingetUri -OutFile $home\winget.msixbundle
                    if (Test-Path $home\winget.msixbundle) {
                        Add-AppxPackage -Path $home\winget.msixbundle -DependencyPath $home\winget.msixbundle
                    }
                    Remove-Item $home\winget.msixbundle 
                    break
                }
                { $_ -eq "choco" } {
                    Set-ExecutionPolicy Bypass -Scope Process -Force;
                    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;
                    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
                    break
                }
                { $_ -eq "python3" } {
                    # remove WindowsApps's python3
                    if (Test-Path $home\AppData\Local\Microsoft\WindowsApps\python.exe) {
                        Remove-Item -Path $home\AppData\Local\Microsoft\WindowsApps\python.exe -Force
                    }
                    if (Test-Path $home\AppData\Local\Microsoft\WindowsApps\python3.exe) {
                        Remove-Item -Path $home\AppData\Local\Microsoft\WindowsApps\python3.exe -Force
                    } 
                    Out-ColorMessage -Message "run cmd -> choco install $PackageName --version $PackageVersion $PackageParms -y --force"
                    # Out-ColorMessage -Message "PackageParms: $PackageParms"
                    $installStatus = choco install $PackageName --version $PackageVersion --params "/InstallDir:C:\Python310 /NoLockdown" -y --force
                    RefreshEnv
                    break
                }
                Default { 
                    Out-ColorMessage -Message "run cmd -> choco install $PackageName --version $PackageVersion $PackageParms -y --force"
                    # Out-ColorMessage -Message "PackageParms: $PackageParms"
                    if ($PackageName -eq "cmake") {
                        $installStatus = choco install $PackageName --version $PackageVersion --installargs "'ADD_CMAKE_TO_PATH=System'" -y --force 

                    }
                    elseif ($PackageName -eq "git") {
                        $installStatus = choco install $PackageName --version $PackageVersion --params "/GitAndUnixToolsOnPath /NoGitLfs /NoAutoCrlf" -y --force 
                    }
                    # if all packages are installed by $PackageParms, there will be some bugs, so we use if and elseif
                    else {
                        $installStatus = choco install $PackageName --version $PackageVersion $PackageParms -y --force 
                    }
                    RefreshEnv
                }
            }
            # after install
            switch ($CliPackageName) {
                { $_ -eq "python3" } {
                    New-Item -Path C:\Python310\python3.exe -ItemType SymbolicLink -Value C:\Python310\python.exe -Force
                    break 
                }
                { $_ -eq "git-lfs" } {
                    git-lfs install 
                    break
                }
                { $_ -eq "nasm" } {
                    [Environment]::SetEnvironmentvariable("PATH", "$([Environment]::GetEnvironmentvariable("Path", "Machine"));C:\Program Files\NASM", "Machine") 
                    break 
                }
                { $_ -eq "perl" } {
                    [Environment]::SetEnvironmentvariable("PATH", "$([Environment]::GetEnvironmentvariable("Path", "Machine"));C:\Strawberry\perl\bin", "Machine")
                    break
                }

                Default {}
            }
            if (($installStatus) -or (Test-Command -Command $CliPackageName -CommandVersion $PackageVersion)) { break }
            
        }
        if ($RetryCount -eq 3) {
            Out-ColorMessage -ForegroundColor "red" -Message "install $PackageName failed, please check your network and try again!"

        }
    }
    else {
        # compare version and upgrade package's version
        switch ($PackageName) {
            { $_ -eq "choco" } {
                if ($(choco --version) -lt "1.2.0") {
                    Out-ColorMessage -Message "update chocolatey, please wait for a moment"
                    choco upgrade chocolatey -y
                    refreshenv
                } 
            }
            Default {}
        }
    }
}

function Install-PackageWithWinget {
    param (
        [string]$PackageName, [string]$CliPackageName, [string]$PackageVersion, [string]$PackageParms, [int]$RetryCount = 3
    )
    if ($CliPackageName) {
        # use test-command to check package
        if (-not $(Test-Command -Command $CliPackageName)) {
            for ($i = 0; $i -lt $RetryCount; $i++) {
                Out-ColorMessage -Message "start install $PackageName, version is: $PackageVersion retry count is: $i, please wait for a moment!"
                winget install --id $PackageName --version $PackageVersion $PackageParms
                if (Test-Command -Command $PackageName) { break }
            }
            Out-ColorMessage -ForegroundColor "red" -Message "install $PackageName failed, please check your network and try again!"

        }
    }
    # can't use cli tool to check package
    else {
        switch ($PackageName) {
            { $_ -eq "Google.AndroidStudio" -and $install_as -eq "true" } {
                if (Test-Path "C:\Program Files\Android\Android Studio") {
                    return
                } 
            }
            Default {
                for ($i = 0; $i -lt $RetryCount; $i++) {
                    Out-ColorMessage -Message "start install $PackageName, version is: $PackageVersion retry count is: $i, please wait for a moment!"
                    winget install --id $PackageName --version $PackageVersion $PackageParms
                    if (Test-Path "C:\Program Files\Android\Android Studio") { break }
                    Out-ColorMessage -ForegroundColor "red" -Message "install $PackageName failed, please check your network and try again!"
                }
            }
        }
    }
}

function Install-VisualStudio {
    param (
        [string]$PackageName, [string]$PackageVersion
    )
    # use 16.11.21 buildtools to install visual studio 2019
    if (-not $(Test-Path "C:\Program Files (x86)\Microsoft Visual Studio\2019\")) {
        Out-ColorMessage -Message "start install visual studio 2019, please wait a long time!"
        if ($Env:BITS_CLOUD_BUILD_ENV) {
            $vsBuildToolsUrl = "http://tosv.byted.org/obj/rtcsdk/build_env_install/windows/vs_BuildTools_16.11.21.exe"
            if (-not $(Test-Path $home\vs_IntsallTools_16.11.21.exe)) {
                Invoke-FileDownload -Uri $vsBuildToolsUrl -OutFile $home\vs_BuildTools_16.11.21.exe
            }
            ."$home\vs_BuildTools_16.11.21.exe" --quiet --wait --norestart --nocache install `
                --installPath "C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools" `
                --add Microsoft.VisualStudio.Workload.VCTools `
                --includeRecommended `
                --add Microsoft.VisualStudio.Component.VC.Modules.x86.x64 `
                --add Microsoft.VisualStudio.Component.VC.ATLMFC `
                --add Microsoft.VisualStudio.Component.VC.Tools.ARM64 `
                --add Microsoft.VisualStudio.Component.VC.ATL.ARM64 `
                --add Microsoft.VisualStudio.Component.VC.MFC.ARM64 `
                --remove Microsoft.VisualStudio.Component.Windows10SDK.10240 `
                --remove Microsoft.VisualStudio.Component.Windows10SDK.10586 `
                --remove Microsoft.VisualStudio.Component.Windows10SDK.14393 `
                --remove Microsoft.VisualStudio.Component.Windows81SDK
            Out-ColorMessage -Message "visual studio 2019 is being installed..."
            if ($? -and $(Test-Path "C:\Program Files (x86)\Microsoft Visual Studio\2019\")) {
                Out-ColorMessage -Message "install visual studio 2019 success!!"
            } 
            Remove-Item -Path "$home\vs_BuildTools_16.11.21.exe" -Force
        }
        else {
            $vsBuildToolsUrl = "http://tosv.byted.org/obj/rtcsdk/build_env_install/windows/vs_Community_16.11.21.exe"
            if (-not $(Test-Path $home\vs_IntsallTools_16.11.21.exe)) {
                Invoke-FileDownload -Uri $vsBuildToolsUrl -OutFile $home\vs_Community_16.11.21.exe
            }
            # before install, we will delete the original
            ."$home\vs_Community_16.11.21.exe" uninstall -p --wait --installPath "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community"
            ."$home\vs_Community_16.11.21.exe" -p --norestart --wait --nocache `
                --installPath "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community" `
                --add Microsoft.VisualStudio.Workload.CoreEditor `
                --add Microsoft.VisualStudio.Workload.NativeDesktop `
                --includeRecommended `
                --add Microsoft.VisualStudio.Component.VC.Modules.x86.x64 `
                --add Microsoft.VisualStudio.Component.VC.ATLMFC `
                --add Microsoft.VisualStudio.Component.VC.Tools.ARM64 `
                --add Microsoft.VisualStudio.Component.VC.ATL.ARM64 `
                --add Microsoft.VisualStudio.Component.VC.MFC.ARM64 `
                --remove Microsoft.VisualStudio.Component.Windows10SDK.10240 `
                --remove Microsoft.VisualStudio.Component.Windows10SDK.10586 `
                --remove Microsoft.VisualStudio.Component.Windows10SDK.14393 `
                --remove Microsoft.VisualStudio.Component.Windows81SDK
            Out-ColorMessage -Message "visual studio 2019 is being installed, please don't close visual studio's ui, now continue to install other tools!!"
            Remove-Item -Path "$home\vs_Community_16.11.21.exe" -Force
        } 
    }  
}

function Install-SdkManager {
    param (
        [string]$PackageName, [string]$PackageVersion
    )
    # install android sdk manager tools and set android system env C:\Program Files\Android
    if (-not $(Test-Path "C:\Android\cmdline-tools\tools")) {
        Out-ColorMessage -Message "start install android sdkmanager tools, please wait for a long time!"
        New-Item -Path "C:\Android" -Name cmdline-tools -ItemType Directory -Force
        $winSDKManager = "http://tosv.byted.org/obj/rtcsdk/build_env_install/windows/Commandlinetools-win_latest.zip"
        Invoke-FileDownload -Uri $winSDKManager -OutFile $home\Commandlinetools-win_latest.zip
        Expand-Archive -Path $home\Commandlinetools-win_latest.zip -DestinationPath $home\cmdline-tools
        Rename-Item -Path $home\cmdline-tools\cmdline-tools -NewName $home\cmdline-tools\tools -Force
        Move-Item -Path "$home\cmdline-tools\tools" -Destination "C:\Android\cmdline-tools" -Force
        Remove-Item -Path $home\Commandlinetools-win_latest.zip -Force
        Remove-Item -Path $home\cmdline-tools -Recurse -Force
    }
    # set system env for android
    [Environment]::SetEnvironmentVariable('ANDROID_SDK_ROOT', 'C:\Android' , 'Machine')
    [Environment]::SetEnvironmentVariable('ANDROID_HOME', 'C:\Android' , 'Machine')

    # android sdk manager --licenses
    Out-ColorMessage -Message "accept sdkmanager licenses"
    $androidSdkManager = "C:\Android\cmdline-tools\tools\bin\sdkmanager.bat"
    New-Item -Path $home -Name y_file.txt -ItemType File -Force
    Add-Content -Path $home\y_file.txt -Value "y`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`n" -Encoding utf8
    $null = Get-Content -Path $home\y_file.txt | ."$androidSdkManager" --licenses
    Remove-Item -Path $home\y_file.txt -Force
    
}

function Install-QT {
    param (
        [string]$PackageName, [string]$PackageVersion
    )
    if ($install_qt) {
        if (([Environment]::GetEnvironmentVariable('Qt32Path', 'Machine')) -or ([Environment]::GetEnvironmentVariable('Qt64Path', 'Machine')) -or ($(Test-Path "C:\Qt\5.14.2")) -or $(Test-Path "C:\Qt\Qt5.14.2\5.14.2")) { return }
        $qt5InstallerUri = "http://tosv.byted.org/obj/rtcsdk/build_env_install/windows/qt-unified-windows-x86-4.3.0-1-online.exe"
        $QT_EMAIL = "sunhang.io@bytedance.com"
        $QT_PASSWORD = "bytertc@2020"
        Out-ColorMessage -Message "start install qt5.14.2, please wait for a long time!!"
        Invoke-FileDownload -Uri $qt5InstallerUri -OutFile $home\qt-unified-windows-x86-4.3.0-1-online.exe
        .$home\qt-unified-windows-x86-4.3.0-1-online.exe install `
            qt.qt5.5142.qtcharts `
            qt.qt5.5142.win64_msvc2017_64 `
            qt.qt5.5142.win32_msvc2017 `
            qt.qt5.5142.qtquick3d `
            qt.qt5.5142.qtdatavis3d `
            qt.qt5.5142.qtlottie `
            qt.qt5.5142.qtpurchasing `
            qt.qt5.5142.qtvirtualkeyboard `
            qt.qt5.5142.qtwebengine `
            qt.qt5.5142.qtnetworkauth `
            qt.qt5.5142.qtwebglplugin `
            qt.qt5.5142.qtscript `
            qt.qt5.5142.debug_info `
            qt.qt5.5142.qtquicktimeline `
            --default-answer --accept-licenses --confirm-Command `
            --auto-answer telemetry-question=Yes, AssociateCommonFiletypes=Yes --accept-obligations `
            --email $QT_EMAIL --pw $QT_PASSWORD
        # set system env for qt5
        [Environment]::SetEnvironmentVariable('Qt32Path', 'C:\Qt\5.14.2\msvc2017\lib\cmake' , 'Machine')
        [Environment]::SetEnvironmentVariable('Qt64Path', 'C:\Qt\5.14.2\msvc2017_64\lib\cmake' , 'Machine')
    }
}
function Install-PackageWithSpecial {
    param (
        [string]$PackageName, [string]$PackageVersion
    )
    switch ($PackageName) {
        { $_ -eq "visual studio 2019" } { Install-VisualStudio }
        { $_ -eq "sdkmanager" } { Install-SdkManager }
        { $_ -eq "qt" } { Install-QT }
        Default {}
    }
}

###### start ######
# parse cli params
if ($help -eq "help" -or $help -eq "h") {
    Out-ColorMessage -Message "Usage: .\init_base_env.ps1 [OPTIONS]`n`nOptions:`n  -useName [userName]: input your email prefix`n  -install_as [true or false]: install android studio or not`n  -install_qt [true or false]: install qt5.14.2 or not
    `nExamples:`n  .\init_base_env.ps1 -install_qt false"
    Exit
}

# check current os's version and install winget, os'version need >= 1809 to use winget
$computerInfo = Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, OsHardwareAbstractionLayer
Out-ColorMessage -Message "$computerInfo"
$windowsOSVersion = $computerInfo.WindowsVersion
if ($windowsOSVersion -lt 1809) {
    Out-ColorMessage -ForegroundColor "red" -Message "Error: windows' version is $windowsOSVersion, you need to upgrade windows version which is equal or greater than 1809 first!"
    Exit
}

# make sure user input username when first use git
$gitSshStatus = "yes" | ssh -T code.byted.org |  Select-String "Welcome to Gitlab,"
if (-not $gitSshStatus) {
    Checkpoint-GlobalParam -param $userName
}

# check and install packages
foreach ($package in $pacakageLists) {
    # "name" "cliName" "version" "cliVersionString" "insatllParams" "installMod" "installInImage"
    # on remote machine, not need to install some packages
    if ($Env:BITS_CLOUD_BUILD_ENV -and $package["installInImage"] -eq "false") {
        break
    }
    if ( $package["installMod"] -in @("other", "choco")) {
        Install-PackageWithChocoOrOther -PackageName $package["name"] -CliPackageName $package["cliName"] `
            -PackageVersion $package["version"] -PackageParms $package["insatllParams"]
    }
    elseif ($package["installMod"] -eq "winget") {
        Install-PackageWithWinget  -PackageName $package["name"] -CliPackageName $package["cliName"] `
            -PackageVersion $package["version"] -PackageParms $package["insatllParams"]
    }
    elseif ($package["installMod"] -eq "special") {
        Install-PackageWithSpecial -PackageName $package["name"] -PackageVersion $package["version"] 
    }
}

# install android sdk、ndk、cmake with sdkmanager
$androidSdkManager = "C:\Android\cmdline-tools\tools\bin\sdkmanager.bat"
if (-not $(Test-Path $androidSdkManager)) {
    Out-ColorMessage -ForegroundColor "red" -Message "sdkmanager not found, pass to install android sdk、ndk、cmake"
}
foreach ($package in $pacakageLists) {
    if ($package["installMod"] -eq "sdkmanager") {
        foreach ($version in $package["version"]) {
            Invoke-InstallAndroidTools -SdkmanagerPath $androidSdkManager -ToolsType $package["name"] -ToolsVersion $version
        }
    }
}
# if first use git, config git sshkey, make sure your PC has been installed OpenSSH Client
$gitSshStatus = "yes" | ssh -T code.byted.org |  Select-String "Welcome to Gitlab,"
if (-not $gitSshStatus) {
    Test-GitAuth 
}
# install base pip packages
python3 -m pip install requests, psutil, PyYAML

# set default ndk home env
if (-not [Environment]::GetEnvironmentVariable('ANDROID_NDK_HOME', 'Machine')) {
    $ANDROID_HOME = [Environment]::GetEnvironmentVariable('ANDROID_HOME', 'Machine')
    [Environment]::SetEnvironmentVariable('ANDROID_NDK_HOME', "$ANDROID_HOME\ndk\22.1.7171670" , 'Machine')
}

# check checklist
foreach ($Command in $checklist.Keys) {
    $null = Test-Command -Command $Command -PrintVersion $True
}
foreach ($package in $pacakageLists) {
    if ($package["cliName"]) {
        $null = Test-Command -Command $package["cliName"] -CommandVersion $package["version"]
    }
}