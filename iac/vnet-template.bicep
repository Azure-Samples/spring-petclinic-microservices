param virtualNetworks_vnet_krc_011_name string = 'vnet-krc-011'

resource virtualNetworks_vnet_krc_011_name_resource 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: virtualNetworks_vnet_krc_011_name
  location: 'koreacentral'
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.21.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'sub1'
        properties: {
          addressPrefix: '10.21.1.0/24'
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'sub2'
        properties: {
          addressPrefix: '10.21.2.0/24'
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
    virtualNetworkPeerings: []
    enableDdosProtection: false
  }
}

resource virtualNetworks_vnet_krc_011_name_sub1 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' = {
  name: '${virtualNetworks_vnet_krc_011_name_resource.name}/sub1'
  properties: {
    addressPrefix: '10.21.1.0/24'
    delegations: []
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
}

resource virtualNetworks_vnet_krc_011_name_sub2 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' = {
  name: '${virtualNetworks_vnet_krc_011_name_resource.name}/sub2'
  properties: {
    addressPrefix: '10.21.2.0/24'
    delegations: []
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
}