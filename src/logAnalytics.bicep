
param appName string
param location string = resourceGroup().location
var logAnalyticsWorkspaceName = 'log-${appName}'
var appInsightsName = 'appi-${appName}'

// Log Analytics workspace is required for new Application Insights deployments
resource logAnalyticsWorspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  location: location
  name: logAnalyticsWorkspaceName
  properties: {
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    sku: {
      name: 'PerGB2018'
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// App Insights resource
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorspace.id
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

output instrumentationKey string = appInsights.properties.InstrumentationKey
