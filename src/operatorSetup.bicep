
@description('principalId of the user that will be given the permissions needed to operate this deployment.')
param operatorPrincipalId string

@description('Application name, used to compose the name of the role definitions.')
param appName string

// creates a new role definition that will have the permissions needed to manipulate the items in this deployment.
#disable-next-line BCP081
resource roledefinition_deploymentOperator 'Microsoft.Authorization/roleDefinitions@2018-07-01' = {
  name: guid('deployment-operator', appName)
  properties: {
    roleName: 'Operator role for app ${appName}'
    description: 'This role orchestrates this deployment and allows the communication between the components in this solution.'
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

// assigns the role definition above to the user who will perform the deployment.
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
