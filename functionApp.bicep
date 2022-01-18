// The following will create an Azure Function app on
// a consumption plan, along with a storage account
// and application insights.

// note: https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations

param location string = resourceGroup().location
param functionRuntime string = 'dotnet'

@description('A name for this whole project, used to help name individual resources')
param appName string

@description('The name of the role or service of this function. Example: Api CommandHandler, EventHandler')
param appInternalServiceName string

@description('Id of a existing keyvault that will be used to store and retrieve keys in this deployment')
param keyVaultName string

@description('User-assigned managed identity that will be attached to this function and will have power to connect to different resources.')
param msiRbacId string

@description('Application insights instrumentation key.')
param appInsightsInstrumentationKey string

param deploymentDate string = utcNow()

param appNameSuffix string


var functionAppName = 'func-${appName}-${appInternalServiceName}-${appNameSuffix}'
var appServiceName = 'ASP-${appName}${appInternalServiceName}-${appNameSuffix}'



// remove dashes for storage account name
var storageAccountName =  toLower(format('st{0}', replace('${appInternalServiceName}-${appNameSuffix}', '-', '')))

var appTags = {
  AppID: '${appName}-${appInternalServiceName}'
  AppName: '${appName}-${appInternalServiceName}'
}



// Storage Account - I am using 1 storage account for each function. It would be potentially shared across many function apps.
resource storageAccount 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
  tags: appTags
}

// Blob Services for Storage Account
resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2019-06-01' = {
  parent: storageAccount

  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' existing = {     
  name: keyVaultName
  scope: resourceGroup()     
} 

module setStorageAccountSecret 'setSecret.bicep' = {
  name: 'stgSecret-${appInternalServiceName}-${deploymentDate}'
  params: {
    keyVaultName: keyVault.name
    secretName: '${storageAccount.name}-${appInternalServiceName}-ConnectionString'
    secretValue: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
  }
}


// App Service
resource appService 'Microsoft.Web/serverfarms@2020-12-01' = {
  name: appServiceName
  location: location
  kind: 'functionapp'
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
    size: 'Y1'
    family: 'Y'
    capacity: 0
  }
  properties: {
    maximumElasticWorkerCount: 1
    targetWorkerCount: 0
    targetWorkerSizeId: 0
  }
  tags: appTags
}


// Function App
resource functionApp 'Microsoft.Web/sites@2020-12-01' = {
  name: functionAppName
  location: location
  identity: {
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities: {
      '${msiRbacId}': {}
    }
  }
  kind: 'functionapp'
  properties: {
    keyVaultReferenceIdentity: msiRbacId
    enabled: true
    hostNameSslStates: [
      {
        name: '${functionAppName}.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
      {
        name: '${functionAppName}.scm.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
    ]
    serverFarmId: appService.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=${storageAccount.name}-${appInternalServiceName}-ConnectionString)'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=${storageAccount.name}-${appInternalServiceName}-ConnectionString)'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsInstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: 'InstrumentationKey=${appInsightsInstrumentationKey}'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: functionRuntime
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'CosmosDbConnectionString' 
          value: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=CosmosDbConnectionString)'
        }
      ]
      use32BitWorkerProcess: true
    }
    scmSiteAlsoStopped: false
    clientAffinityEnabled: false
    clientCertEnabled: false
    hostNamesDisabled: false
    dailyMemoryTimeQuota: 0
    httpsOnly: false
    redundancyMode: 'None'
  
  }
  tags: appTags
}
