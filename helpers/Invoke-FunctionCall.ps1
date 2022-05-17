$Function = 'twitch-poll'

$baseScriptPath = $PSScriptRoot
if (($null -ne $psEditor) -and ([string]::IsNullOrEmpty($baseScriptPath))) {
    $baseScriptPath = ([Io.FileInfo]$psEditor.GetEditorContext().CurrentFile.Path).Directory.FullName
}

$request = Get-Content -Path "${baseScriptPath}\..\azure-function\${Function}\sample.dat" -Raw
$functionJson = Get-Content -Path "${baseScriptPath}\..\azure-function\${Function}\function.json" | ConvertFrom-Json
$method = ($functionJson.bindings | Where-Object {$null -ne $_.methods} | Select-Object -ExpandProperty 'methods').ToUpper()
$baseUri = 'http://localhost:7071/api'

$callParams = @{
    Method  = $method
    Verbose = $true
}
if ($method -eq 'GET') {
    $callParams.Add('Uri', "${baseUri}/${Function}?${request}")
} else {
    $callParams.Add('Uri', "${baseUri}/${Function}")
    $callParams.Add('Body', $request)
}
(Invoke-RestMethod @callParams).message
