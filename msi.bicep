param managedIdentityName string
param location string
param roleDefinitionId string = 'b24988ac-6180-42a0-ab88-20f7382dd24c' //Default as contributor role
param operatorRoleDefinitionId string

resource msi 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: managedIdentityName
  location: location
}

resource roleassignment_contributor 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(roleDefinitionId, resourceGroup().id)

  properties: {
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: msi.properties.principalId
  }
}


param keyVaultUserRoleDefinitionId string = '4633458b-17de-408a-b874-0445c86b69e6' 
resource roleassignment_keyvaultReader 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(keyVaultUserRoleDefinitionId, resourceGroup().id)
  properties: {
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', keyVaultUserRoleDefinitionId)
    principalId: msi.properties.principalId
  }
}

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
