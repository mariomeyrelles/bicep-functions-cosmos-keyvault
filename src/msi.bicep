param managedIdentityName string
param location string
param operatorRoleDefinitionId string

resource msi 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: managedIdentityName
  location: location
}

// uses the role definition created on operatorSetup.bicep and maps it to this recently created managed identity.
resource roleassignment_operator 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(operatorRoleDefinitionId, resourceGroup().id)
  properties: {
    principalType: 'ServicePrincipal'
    roleDefinitionId: operatorRoleDefinitionId
    principalId: msi.properties.principalId
  }
}

output principalId string = msi.properties.principalId
output clientId string = msi.properties.clientId
output id string = msi.id
