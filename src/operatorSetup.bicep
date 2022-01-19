
@description('principalId if the user that will be given contributor access to the tenant')
param operatorPrincipalId string

@description('Application name, used to compose the name of the role definitions.')
param appName string


#disable-next-line BCP081
resource roledefinition_deploymentOperator 'Microsoft.Authorization/roleDefinitions@2018-07-01' = {
  name: guid('deployment-operator', appName)
  properties: {
    roleName: 'Operator role for app ${appName}'
    description: 'Role with specific permissions to perform the deployment of the resources we need in this deployment'
    assignableScopes: [
      resourceGroup().id
    ]
    permissions: [
      {
        actions: [
          'Microsoft.Authorization/*/read'
          'Microsoft.Insights/alertRules/*'
          'Microsoft.Resources/deployments/*'
          'Microsoft.Resources/subscriptions/resourceGroups/read'
          'Microsoft.Support/*'
          'Microsoft.KeyVault/checkNameAvailability/read'
          'Microsoft.KeyVault/deletedVaults/read'
          'Microsoft.KeyVault/locations/*/read'
          'Microsoft.KeyVault/vaults/*'
          'Microsoft.KeyVault/operations/read'
        ]
        dataActions:[
          'Microsoft.KeyVault/vaults/*'
        ]
        notActions: []
        notDataActions: []
      }
    ]
  }
}

var roleAssignmentName = guid(resourceGroup().id, roledefinition_deploymentOperator.id, operatorPrincipalId, appName)

resource keyvault_roleAssignment_deploymentOperator 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: roleAssignmentName
  scope: resourceGroup()
  properties: {
    roleDefinitionId: roledefinition_deploymentOperator.id 
    principalId: operatorPrincipalId
  }
}


output roleId string = roledefinition_deploymentOperator.id 
output roleName string = roledefinition_deploymentOperator.name 
output roleType string = roledefinition_deploymentOperator.type 
