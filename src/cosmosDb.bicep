
@maxLength(30)
param cosmosAccountId string
param location string
param cosmosDbName string
param keyVaultName string


param tags object = {
  deploymentGroup: 'cosmosdb'
}

resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2021-10-15' = {
  name: toLower(cosmosAccountId)
  location: location
  kind: 'GlobalDocumentDB'
  properties: {
    publicNetworkAccess: 'Enabled'
    enableFreeTier: false
    databaseAccountOfferType: 'Standard'
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
      maxIntervalInSeconds: 5
      maxStalenessPrefix: 100
    }
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    capabilities: [
      {
        name: 'EnableServerless'
      }
    ]
  }
}


resource cosmosDb_database 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2021-06-15' = {
  parent: cosmosAccount
  name: cosmosDbName
  tags: tags
  properties: {
    resource: {
      id: cosmosDbName
    }
  }
}

resource container_leases 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2021-06-15' = {
  parent: cosmosDb_database
  name: 'leases'
  tags: tags
  properties: {
    resource: {
      id: 'leases'
      partitionKey: {
        paths: [
          '/id'
        ]
      }
    }
  }
}


resource container_employees 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2021-06-15' = {
  parent: cosmosDb_database
  name: 'Employees'
  tags: tags
  properties: {
    resource: {
      id: 'Employees'
      partitionKey: {
        paths: [
          '/EmployeeId'
        ]
      }
      uniqueKeyPolicy: {
        uniqueKeys: [
          {
            paths: [
              '/EmployeeId'
            ]
          }
        ]
      }
    }
  }
}

module setCosmosConnectionString 'setSecret.bicep' = {
  name: 'setCosmosConnectionString'
  params: {
    keyVaultName: keyVaultName
    secretName: 'CosmosDbConnectionString'
    secretValue: cosmosAccount.listConnectionStrings().connectionStrings[0].connectionString
  }
}

output cosmosAccountId string = cosmosAccountId
