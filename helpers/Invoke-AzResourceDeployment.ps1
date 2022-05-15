Connect-AzAccount | Out-Null

$ResourceGroupName = 'hhh-simple-poll-we'
$resourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
if ($null -eq $resourceGroup) {
    New-AzResourceGroup -Name $ResourceGroupName -Location 'westeurope' | Out-Null
}

$baseScriptPath = $PSScriptRoot
if (($null -ne $psEditor) -and ([string]::IsNullOrEmpty($baseScriptPath))) {
    $baseScriptPath = ([Io.FileInfo]$psEditor.GetEditorContext().CurrentFile.Path).Directory.FullName
}

$deployParams = @{
    ResourceGroupName     = $ResourceGroupName
    TemplateFile          = "${baseScriptPath}\..\arm-templates\azuredeploy.json"
    TemplateParameterFile = "${baseScriptPath}\..\arm-templates\azuredeploy.parameters.json"
    Mode                  = 'Incremental'
    Verbose               = $true
}
Test-AzResourceGroupDeployment @deployParams

New-AzResourceGroupDeployment @deployParams
