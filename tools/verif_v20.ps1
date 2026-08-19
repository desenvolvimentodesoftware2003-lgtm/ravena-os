# VERIF_v20.ps1 - Conferencia pos-gravacao RV10v20 (requer admin)
$ErrorActionPreference = "Stop"

$ISO = "C:\Users\DELL\RAVENA-ISOS\ravena-remaster-RV10v20.iso"
$DISK = 1
$DEV = "\\.\PHYSICALDRIVE$DISK"
$OUTLOG = "C:\Users\DELL\RAVENA-ISOS\verif_v20_resultado.txt"
Remove-Item $OUTLOG -ErrorAction SilentlyContinue

function Log($msg) {
    $ts = "[$(Get-Date -Format HH:mm:ss)] $msg"
    Write-Host $ts
    Add-Content -Path $OUTLOG -Value $ts
}

function Read-Raw([long]$offset, [int]$len, $fs) {
    $buf = New-Object byte[] $len
    $fs.Seek($offset, [System.IO.SeekOrigin]::Begin) | Out-Null
    $read = $fs.Read($buf, 0, $len)
    if ($read -ne $len) { throw "Leitura curta em offset $offset ($read/$len)" }
    return $buf
}

function Hash-Buf($buf) {
    $sha = [System.Security.Cryptography.SHA512]::Create()
    return [BitConverter]::ToString($sha.ComputeHash($buf)).Replace("-","").ToLower()
}

function Test-Block([long]$offset, [int]$len, $fs, $isoFs, [string]$nome) {
    $hp = Hash-Buf (Read-Raw $offset $len $fs)
    $hi = Hash-Buf (Read-Raw $offset $len $isoFs)
    $ok = ($hp -eq $hi)
    if ($ok) { Log "BLOCO $nome OK - confere com o ISO" }
    else { Log "BLOCO $nome DIFERENTE!" }
    return $ok
}

if (-not (Test-Path $ISO)) { Log "ERRO: ISO nao encontrado"; exit 1 }
$d = Get-Disk -Number $DISK
if ($d.FriendlyName -notmatch "SanDisk|Cruzer") { Log "ERRO: Disco $DISK nao e SanDisk"; exit 1 }
if ($d.OperationalStatus -ne "Online") { Log "ERRO: Disco nao esta Online"; exit 1 }
if ($d.IsReadOnly) { Log "ERRO: Disco esta ReadOnly"; exit 1 }
$isoLen = (Get-Item $ISO).Length

Log "=== VERIFICACAO POS-GRAVACAO RV10v20 ==="
Log "Alvo: $($d.FriendlyName) / Disco $DISK / ISO $isoLen bytes"

$offsets = @(
    @{ off = 0;            len = 1048576;  nome = "1/8 MBR+boot" },
    @{ off = 8388608;      len = 4194304;  nome = "2/8 squashfs@8MB" },
    @{ off = 1073741824;   len = 1048576;  nome = "3/8 @1GB" },
    @{ off = 2147483648;   len = 1048576;  nome = "4/8 @2GB" },
    @{ off = 3221225472;   len = 1048576;  nome = "5/8 @3GB" },
    @{ off = 4294967296;   len = 1048576;  nome = "6/8 @4GB" },
    @{ off = 5368709120;   len = 1048576;  nome = "7/8 @5GB" },
    @{ off = $isoLen - 2097152; len = 2097152; nome = "8/8 final" }
)

$fs = [System.IO.File]::Open($DEV, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
$isoFs = [System.IO.File]::Open($ISO, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
try {
    $okList = @()
    foreach ($b in $offsets) { $okList += Test-Block $b.off $b.len $fs $isoFs $b.nome }
    $n = @($okList | Where-Object { $_ }).Count
    Log ""
    if ($n -eq $offsets.Count) { Log "RESULTADO: $n/$($offsets.Count) IGUAL - GRAVACAO INTEGRA" }
    else { Log "RESULTADO: $n/$($offsets.Count) IGUAL - INCONSISTENTE, regravar" }
} finally { $fs.Close(); $isoFs.Close() }
Log "FIM"

