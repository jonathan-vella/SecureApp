$localpath = "{your local directory}"
$templateparamfile = $localpath + "azuredeploy.parameters.local.json"
$params = get-content $templateparamfile | ConvertFrom-Json
$prefix = $params.parameters.resourcenameprefix.value
$rgname = $prefix + "-rg"
$pepname =  $prefix+ "-sql-pep"
$routevnet = $prefix + "-spoke-vnet"
# get sql private endpoint
$pe = get-azprivateendpoint -resourcegroupname $rgname -name $pepname
# get the NIC
$nic = get-aznetworkinterface -resourceid $pe.NetworkInterfaces[0].Id
# get the actual private IP
$sqlip = $nic.ipconfigurations[0].privateipaddress
# get the az fw
$fw = get-azfirewall -resourcegroup $rgname
# get the fw private ip
$fwip = $fw.ipconfigurations[0].privateipaddress
# ceate route
$route = New-AzRouteConfig -Name "sql2fw" -AddressPrefix "$sqlip/32" -NextHopType "VirtualAppliance" -NextHopIpAddress $fwip
$rg = get-azresourcegroup -name $rgname
# create route table
$rtable = New-AzRouteTable -Name "allowapp2sql" -ResourceGroupName $rgname -Location $rg.location -Route $route
# assign route table to subnet
$vnet = get-azvirtualnetwork -resourcegroupname $rgname -name $routevnet
$sqlsubnet = $vnet.subnets | where-object {$_.Name -like "*sql*"}
set-azvirtualnetworksubnetconfig -name $sqlsubnet.name -virtualnetwork $vnet -addressprefix $sqlsubnet.addressprefix -routetable $rtable
$vnet | set-azvirtualnetwork
write-host "UDR Enabled"