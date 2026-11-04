# jetson-dev-env Windows 설치. 없는 것만 설치하고, 사람이 해야 할 단계에서 멈춰 안내한다.
# 다시 실행하면 이어서 진행한다.
#   1. WSL2가 없으면 설치 (관리자 권한, 재부팅 필요)
#   2. WSL에 Ubuntu가 없으면 Ubuntu 22.04 설치 (처음 실행 때 리눅스 사용자 이름·비밀번호 입력)
#   3. Ubuntu 안에 이 저장소를 받고 install.sh 실행 (Docker 엔진 설치, 이미지 빌드)
#
#   powershell -ExecutionPolicy Bypass -File setup.ps1
param(
    [string]$Distro = "",
    [string]$RepoUrl = "https://github.com/JunghanShin/jetson-dev-env.git"
)
$ErrorActionPreference = "Stop"

function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    return (New-Object Security.Principal.WindowsPrincipal $id).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# wsl.exe는 UTF-16으로 출력한다
function Invoke-Wsl {
    $old = [Console]::OutputEncoding
    [Console]::OutputEncoding = [Text.Encoding]::Unicode
    try { $out = & wsl.exe @args 2>&1; $code = $LASTEXITCODE } finally { [Console]::OutputEncoding = $old }
    return @{ Code = $code; Out = (($out | ForEach-Object { "$_" }) -join "`n") -replace "`0", "" }
}

function Get-UbuntuDistros {
    $r = Invoke-Wsl -l -v
    if ($r.Code -ne 0) { return @() }
    $list = @()
    foreach ($line in ($r.Out -split "`n" | Select-Object -Skip 1)) {
        $cols = ($line -replace '^\s*\*?\s*', '') -split '\s+' | Where-Object { $_ }
        if ($cols.Count -ge 3 -and $cols[0] -like 'Ubuntu*') {
            $list += [pscustomobject]@{ Name = $cols[0]; Version = $cols[2] }
        }
    }
    return $list
}

# ---- 1. WSL2 ------------------------------------------------------------------------
$status = Invoke-Wsl --status
if ($status.Code -ne 0) {
    if (-not (Test-Admin)) {
        Write-Host "WSL2 설치에는 관리자 권한이 필요합니다. 관리자 창에서 다시 실행합니다."
        Start-Process powershell -Verb RunAs -ArgumentList "-NoExit -ExecutionPolicy Bypass -File `"$PSCommandPath`""
        exit 0
    }
    Write-Host "WSL2와 Ubuntu 22.04를 설치합니다."
    & wsl.exe --install -d Ubuntu-22.04
    Write-Host ""
    Write-Host "PC를 재부팅하세요. 재부팅 후 Ubuntu 창이 뜨면 리눅스 사용자 이름과 비밀번호를 정하고,"
    Write-Host "이 스크립트를 다시 실행하세요."
    exit 0
}

# ---- 2. Ubuntu ----------------------------------------------------------------------
$distros = Get-UbuntuDistros
if ($Distro) {
    $target = $distros | Where-Object { $_.Name -eq $Distro } | Select-Object -First 1
} else {
    $target = $distros | Where-Object { $_.Name -eq 'Ubuntu-22.04' } | Select-Object -First 1
    if (-not $target) { $target = $distros | Select-Object -First 1 }
}
if (-not $target) {
    Write-Host "WSL에 Ubuntu가 없어 Ubuntu 22.04를 설치합니다."
    & wsl.exe --install -d Ubuntu-22.04
    Write-Host ""
    Write-Host "Ubuntu 창에서 리눅스 사용자 이름과 비밀번호를 정한 뒤, 이 스크립트를 다시 실행하세요."
    Write-Host "(창이 뜨지 않으면 시작 메뉴에서 'Ubuntu 22.04'를 실행합니다.)"
    exit 0
}
if ($target.Version -ne '2') {
    Write-Host "$($target.Name)을 WSL2로 바꿉니다."
    & wsl.exe --set-version $target.Name 2
}
Write-Host "WSL 배포판: $($target.Name)"

# 사용자 계정을 아직 만들지 않았으면 root로만 들어가진다 (리눅스 명령 출력은 UTF-8)
$who = "$(& wsl.exe -d $target.Name -- id -un)".Trim()
if ($who -eq 'root' -or -not $who) {
    Write-Host "$($target.Name)에 일반 사용자가 없습니다. 시작 메뉴에서 $($target.Name)을 한 번 실행해 사용자를 만든 뒤 다시 실행하세요."
    exit 1
}

# ---- 3. 저장소와 install.sh (Ubuntu 안) -------------------------------------------------
# 빌드 속도를 위해 /mnt/c가 아니라 WSL 홈에 둔다. install.sh는 sudo 비밀번호를 물을 수 있다.
$script = "set -e; " +
    "command -v git >/dev/null || { sudo apt-get update && sudo apt-get install -y git; }; " +
    "if [ -d ~/jetson-dev-env/.git ]; then git -C ~/jetson-dev-env pull --ff-only; " +
    "else git clone '$RepoUrl' ~/jetson-dev-env; fi; " +
    "~/jetson-dev-env/install.sh"
& wsl.exe -d $target.Name --cd "~" -- bash -lc $script
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "Ubuntu 안의 설치가 끝나지 않았습니다. 위 안내를 따른 뒤 이 스크립트를 다시 실행하세요."
    exit 1
}
Write-Host ""
Write-Host "완료. Ubuntu 터미널(시작 메뉴의 $($target.Name))에서 jetson-build 등을 씁니다."
