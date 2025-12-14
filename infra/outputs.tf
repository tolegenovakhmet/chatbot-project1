output "cloud_function_url" {
  value = yandex_function_function.chatbot.execution[0].url
}

output "api_gateway_url" {
  value = yandex_apigateway_api_gateway.gateway.url
}

