$shell = New-Object -COMObject Shell.Application
$rawDir = (Resolve-Path "android\app\src\main\res\raw").Path
$folder = $shell.Namespace($rawDir)

foreach ($name in @("adzan_regular.mp3", "adzan_subuh.mp3")) {
    $item = $folder.ParseName($name)
    $duration = $folder.GetDetailsOf($item, 27)
    Write-Host "$name duration: $duration"
}
