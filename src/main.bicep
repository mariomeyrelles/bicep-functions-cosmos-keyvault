

@description('Application Name - change it!')
param appName string = 'sampleApp'

param location string = resourceGroup().location
param tenantId string = tenant().tenantId

@description('This is the object id of the user who will do the deployment on Azure. Can be your user id on AAD. Discover it running [az ad signed-in-user show] and get the [objectId] property.')
param deploymentOperatorId string 

// a 4-char suffix to add to the various names of azure resources to help them be unique, but still, previsible
var appSuffix = substring(uniqueString(resourceGroup().id),0,4)

// grants access to the operator of this deployment with specific roles like key vault access.
module operatorSetup 'operatorSetup.bicep' = {
  name: 'operatorSetup-deployment'
  params: {
    operatorPrincipalId: deploymentOperatorId
    appName: appName
  }
}

// creates an user-assigned managed identity that will used by different azure resources to access each other.
module msi 'msi.bicep' = {
  name: 'msi-deployment'
  params: {
    location: location
    managedIdentityName: '${appName}Identity'
    operatorRoleDefinitionId: operatorSetup.outputs.roleId
  }
}

// creates a key vault in this resource group
module keyvault 'keyvault.bicep' = {
  name: 'keyvault-deployment'
  params: {
    location: location
    appName: appName
    tenantId: tenantId
  }
}

// creates the cosmos db account and database with some containers configured. Saves connection string in keyvault.
module cosmos 'cosmosDb.bicep' = {
  name: 'cosmos-deployment'
  params:{
    cosmosAccountId: '${appName}-${appSuffix}'
    location: location
    cosmosDbName: appName
    keyVaultName: keyvault.outputs.keyVaultName
  }
}

// creates a Log Analytics + Application Insights instance
module logAnalytics 'logAnalytics.bicep' = {
  name: 'log-analytics-deployment'
  params: {
    appName: appName
  }
}

// creates an azure function, with secrets stored in the key vault
module azureFunctions_api 'functionApp.bicep' = {
  name: 'functions-app-deployment-api'
  params: {
    appName: appName
    appInternalServiceName: 'api'
    appNameSuffix: appSuffix
    appInsightsInstrumentationKey: logAnalytics.outputs.instrumentationKey
    keyVaultName: keyvault.outputs.keyVaultName
    msiRbacId: msi.outputs.id
  }
  dependsOn: [
    keyvault
    logAnalytics
  ]
}
