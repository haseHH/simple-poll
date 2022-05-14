Connect-AzAccount | Out-Null

$ResourceGroupName = 'hhh-simple-poll-we'
$resourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
if ($null -eq $resourceGroup) {
    New-AzResourceGroup -Name $ResourceGroupName -Location 'westeurope' | Out-Null
}

$deployParams = @{
    ResourceGroupName     = $ResourceGroupName
    TemplateFile          = 'arm-templates\azuredeploy.json'
    TemplateParameterFile = 'arm-templates\azuredeploy.parameters.json'
    Mode                  = 'Incremental'
    Verbose               = $true
}
Test-AzResourceGroupDeployment @deployParams

New-AzResourceGroupDeployment @deployParams
