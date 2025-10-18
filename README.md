# Analista de Processos de Negócio Autônomo (BPA-AI)

[![Status do Build](https://img.shields.io/badge/build-pending-yellow)](https://github.com/SEU_USUARIO/SEU_REPOSITORIO/actions)
[![Licença](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

Um projeto de plataforma serverless e event-driven no Azure que orquestra agentes de IA para automatizar processos de negócio complexos, como o onboarding de novos clientes.

## O Problema a ser Resolvido

A maioria das aplicações de IA atuais opera em um paradigma de "Perguntas e Respostas". O usuário pergunta, a IA responde. Este projeto eleva esse paradigma para "Tarefas e Ações". Em vez de ser um oráculo passivo, o BPA-AI atua como um time de "operários digitais" autônomos que executam um workflow de negócio de ponta a ponta, tomando decisões e interagindo com outros sistemas.

## Diagrama da Arquitetura

*(A ser inserido: Um diagrama claro e conciso da nossa arquitetura final. Manteremos este placeholder por enquanto.)*

```
[API Gateway] -> [Function de Recepção] -> [Cosmos DB: Cria Estado]
      |
      v
[Service Bus Topic: NewClientReceived]
      |
      v (Filtro de Assinatura)
[Function de Validação] -> [API Externa] -> [Cosmos DB: Atualiza Estado]
      |
      v
[Service Bus Topic: ValidationCompleted]
      |
      v ... (e assim por diante para os outros agentes)
```

## Stack de Tecnologia

| Categoria           | Tecnologia                                                                                             |
| ------------------- | ------------------------------------------------------------------------------------------------------ |
| **Cloud**           | ![Microsoft Azure](https://img.shields.io/badge/Microsoft_Azure-0078D4?style=for-the-badge&logo=microsoft-azure&logoColor=white) |
| **Computação**      | ![Azure Functions](https://img.shields.io/badge/Azure_Functions-0078D4?style=for-the-badge&logo=azure-functions&logoColor=white) |
| **Mensageria**      | ![Azure Service Bus](https://img.shields.io/badge/Service_Bus-0078D4?style=for-the-badge&logo=microsoft-azure&logoColor=white)     |
| **Banco de Dados**  | ![Azure Cosmos DB](https://img.shields.io/badge/Cosmos_DB-0078D4?style=for-the-badge&logo=azure-cosmos-db&logoColor=white)       |
| **Inteligência Artificial** | ![Azure OpenAI](https://img.shields.io/badge/Azure_OpenAI-0078D4?style=for-the-badge&logo=openai&logoColor=white)            |
| **Infra as Code**   | ![Bicep](https://img.shields.io/badge/Bicep-0078D4?style=for-the-badge&logo=bicep&logoColor=white)                   |
| **Observabilidade** | ![Application Insights](https://img.shields.io/badge/App_Insights-0078D4?style=for-the-badge&logo=microsoft-azure&logoColor=white) |


## Como Funciona: Workflow de Onboarding de Cliente

O sistema opera como uma máquina de estados distribuída, orquestrada por eventos:

1.  **Recepção:** Uma requisição HTTP inicia um novo processo de onboarding. Um estado inicial é criado no Cosmos DB e um evento `NewClientReceived` é publicado.
2.  **Validação e Enriquecimento:** Um agente reage ao evento, consulta APIs externas para enriquecer os dados do cliente e valida as informações. Ao concluir, publica um evento `ValidationCompleted`.
3.  **Análise de Risco:** Um agente especialista em risco (utilizando RAG) consome o evento anterior, analisa os dados enriquecidos contra uma base de conhecimento interna e calcula um score de risco. Ao concluir, publica `RiskAnalysisCompleted`.
4.  **Tomada de Decisão:** Um agente de decisão aplica regras de negócio ao score de risco, decidindo por aprovar, rejeitar ou encaminhar para revisão humana. Publica `DecisionMade`.
5.  **Comunicação:** Agentes finais notificam os sistemas relevantes (e-mail para o cliente, mensagem no Slack para a equipe interna, etc.) com base na decisão tomada.

## Getting Started

### Pré-requisitos

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Bicep](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install)
- [Python 3.10+](https://www.python.org/downloads/)
- [Azure Functions Core Tools](https://docs.microsoft.com/azure/azure-functions/functions-run-local)

### 1. Provisionar a Infraestrutura

Clone o repositório e execute o seguinte comando para provisionar todos os recursos necessários no Azure:

```bash
# Faça login na sua conta Azure
az login

# Crie o deployment a partir do arquivo principal do Bicep
az deployment group create \
  --resource-group SEU_RESOURCE_GROUP_NAME \
  --template-file ./infra/main.bicep \
  --parameters ./infra/main.parameters.json
```

### 2. Configurar Aplicação

*(Esta seção será detalhada após a Fase 1 de IaC, com instruções sobre como popular o `local.settings.json` das Functions a partir dos outputs do Bicep.)*

### 3. Executar o Projeto

*(Instruções futuras para rodar e testar o projeto.)*
