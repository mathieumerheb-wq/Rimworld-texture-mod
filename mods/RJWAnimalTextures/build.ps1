<#
Builds Assemblies/RJWAnimalTextures.dll for RimWorld 1.7 from Source/*.cs with the .NET Framework C#
compiler (C# 5), against the installed game's own core assemblies (/nostdlib), UnityStubs, Harmony 1.7
and Sized Apparel 1.7. Same approach as mods/HaulAfterWork/build.ps1.
Output goes to build/ (not shipped). Pass -Install to copy it into Assemblies/. The script never writes
into the game or the Workshop.

    powershell -ExecutionPolicy Bypass -File build.ps1
    powershell -ExecutionPolicy Bypass -File build.ps1 -Install
#>
param(
    [switch]$Install,
    [string]$Game = 'C:\Program Files (x86)\Steam\steamapps\common\RimWorld',
    [string]$Workshop = 'C:\Program Files (x86)\Steam\steamapps\workshop\content\294100'
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot

$installed = (Get-Content (Join-Path $Game 'Version.txt') -ErrorAction SilentlyContinue | Select-Object -First 1)
if (-not $installed -or -not $installed.StartsWith('1.7.')) {
    throw "RimWorld 1.7 is not installed (Version.txt says '$installed')."
}

$csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (-not (Test-Path $csc)) { throw "C# compiler not found: $csc" }

$runtime = 'System.Private.CoreLib', 'System.Runtime', 'mscorlib', 'netstandard', 'System.Collections',
    'System.Linq', 'System.Core', 'System.Reflection.Emit.ILGeneration', 'System.Reflection.Emit.Lightweight',
    'System.Reflection.Primitives', 'System.Runtime.Serialization.Formatters', 'System.Memory'
$references = @($runtime | ForEach-Object { Join-Path $Game "$_.dll" })
$references += @(
    (Join-Path $Game 'Assembly-CSharp.dll'),
    (Join-Path $Game 'UnityStubs.dll'),
    (Join-Path $Workshop '2009463077\1.7\Assemblies\0Harmony.dll'),
    (Join-Path $Game 'Mods\sized-apparel-zero\1.7\Assemblies\SizedApparelforRJW.dll')
)
foreach ($reference in $references) {
    if (-not (Test-Path $reference)) { throw "Reference not found: $reference" }
}

$outDir = Join-Path $root 'build'
New-Item -ItemType Directory -Force $outDir | Out-Null
$out = Join-Path $outDir 'RJWAnimalTextures.dll'
$sources = Get-ChildItem (Join-Path $root 'Source') -Filter *.cs | ForEach-Object { $_.FullName }

$arguments = @('/noconfig', '/nostdlib+', '/nowarn:1701', '/target:library', '/optimize+', "/out:$out") +
    ($references | ForEach-Object { "/reference:$_" }) + $sources
& $csc @arguments
if ($LASTEXITCODE -ne 0) { throw "Compile failed ($LASTEXITCODE)." }
"Built $out"

if ($Install) {
    Copy-Item $out (Join-Path $root 'Assemblies\RJWAnimalTextures.dll') -Force
    "Installed into Assemblies"
}
