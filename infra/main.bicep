// =================================================================================
// Template Bicep para a Infraestrutura do Projeto BPA-AI
// Autor: Esteves Marques
// Versão: 1.0
// Descrição: Provisiona todos os recursos Azure necessários para a aplicação.
// =================================================================================

@description('A localização dos recursos. Por padrão, usa a localização do Resource Group.')
param location string = resourceGroup().location

@description('Um prefixo curto para todos os recursos, para fácil identificação.')
param prefix string = 'bpaai'


// =================================================================================
// VARIÁVEIS DE NOMENCLATURA
// =================================================================================
@description('Sufixo único e curto para garantir nomes de recursos globalmente únicos.')
var uniqueSuffix = substring(uniqueString(resourceGroup().id), 0, 5)

// Nomes de recursos legíveis e consistentes
var storageAccountName = '${prefix}sa${uniqueSuffix}'
var cosmosDbAccountName = '${prefix}-db-${uniqueSuffix}'
var serviceBusNamespaceName = '${prefix}-sb-${uniqueSuffix}'
var appInsightsName = '${prefix}-insights-${uniqueSuffix}'
var functionAppName = '${prefix}-func-${uniqueSuffix}'
var functionAppPlanName = '${prefix}-plan-${uniqueSuffix}'

// =================================================================================
// RECURSOS
// =================================================================================

// --- Computação e Essenciais ---

@description('Conta de Armazenamento para os assets da Azure Function.')
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
  }
}

@description('Application Insights para monitoramento e observabilidade.')
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

@description('Plano de Consumo (Serverless) para hospedar a Function App.')
resource functionAppPlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: functionAppPlanName
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {
    reserved: true // Necessário para planos de consumo Linux
  }
}

// --- Banco de Dados (Máquina de Estados) ---

@description('Conta do Azure Cosmos DB API for MongoDB (RU-based) no nível gratuito.')
resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2023-04-15' = {
  name: cosmosDbAccountName
  location: location
  kind: 'MongoDB' // Define o "sabor" da conta para MongoDB
  properties: {
    databaseAccountOfferType: 'Standard'
    // Habilita o nível gratuito para a conta
    enableFreeTier: true 
    consistencyPolicy: {
      defaultConsistencyLevel: 'Eventual'
    }
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
  }
}

// --- Mensageria (Orquestração de Eventos) ---

@description('Namespace do Service Bus para o barramento de eventos.')
resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' = {
  name: serviceBusNamespaceName
  location: location
  sku: {
    name: 'Standard'
  }
  // A propriedade 'properties' foi removida pois estava vazia e causava erro.
}

@description('Tópico principal onde todos os eventos do processo serão publicados.')
resource serviceBusTopic 'Microsoft.ServiceBus/namespaces/topics@2022-10-01-preview' = {
  parent: serviceBusNamespace
  name: 'onboarding-process'
}

// --- Aplicação Principal ---

@description('Azure Function App que hospedará os nossos agentes Python.')
resource functionApp 'Microsoft.Web/sites@2022-09-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned' // Boa prática para futuras integrações
  }
  properties: {
    serverFarmId: functionAppPlan.id
    siteConfig: {
      linuxFxVersion: 'PYTHON|3.10'
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'python'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
        {
          name: 'CosmosDbConnectionString'
          value: cosmosDbAccount.listConnectionStrings().connectionStrings[0].connectionString
        }
        {
          name: 'ServiceBusConnectionString'
          value: listKeys(
            resourceId(
              'Microsoft.ServiceBus/namespaces/authorizationRules',
              serviceBusNamespace.name,
              'RootManageSharedAccessKey'
            ),
            serviceBusNamespace.apiVersion
          ).primaryConnectionString
        }
      ]
    }
    httpsOnly: true
  }
}
