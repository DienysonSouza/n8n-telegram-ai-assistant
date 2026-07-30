$ErrorActionPreference = "Stop"

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw "Docker nao encontrado. Instale Docker Desktop e execute novamente."
}

docker compose version | Out-Null

function New-RandomHex([int]$Bytes) {
    $buffer = New-Object byte[] $Bytes
    $rng = [Security.Cryptography.RandomNumberGenerator]::Create()
    try {
        $rng.GetBytes($buffer)
    }
    finally {
        $rng.Dispose()
    }
    return -join ($buffer | ForEach-Object { $_.ToString("x2") })
}

function Read-Secret([string]$Prompt) {
    $secure = Read-Host $Prompt -AsSecureString
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
    }
}

if (-not (Test-Path -LiteralPath ".env")) {
    $telegramToken = Read-Secret "Token do bot Telegram"
    $anthropicKey = Read-Secret "Chave da Anthropic"
    $ownerChatId = Read-Host "Seu chat ID do Telegram"
    $ownerName = Read-Host "Seu nome"
    $botName = Read-Host "Nome do assistente [Assistente]"
    if ([string]::IsNullOrWhiteSpace($botName)) { $botName = "Assistente" }
    $webhookUrl = Read-Host "URL publica HTTPS do n8n [http://localhost:5678/]"
    if ([string]::IsNullOrWhiteSpace($webhookUrl)) {
        $webhookUrl = "http://localhost:5678/"
    }

    $uri = [Uri]$webhookUrl
    $secureCookie = if ($uri.Scheme -eq "https") { "true" } else { "false" }

    $content = @"
TELEGRAM_BOT_TOKEN=$telegramToken
ANTHROPIC_API_KEY=$anthropicKey
OWNER_CHAT_ID=$ownerChatId
OWNER_NAME=$ownerName
BOT_NAME=$botName
PG_PASSWORD=$(New-RandomHex 24)
N8N_ENCRYPTION_KEY=$(New-RandomHex 32)
PG_HOST=postgres
PG_PORT=5432
PG_DATABASE=assistant
PG_USER=assistant
N8N_PORT=5678
N8N_HOST=$($uri.Host)
N8N_PROTOCOL=$($uri.Scheme)
N8N_SECURE_COOKIE=$secureCookie
WEBHOOK_URL=$webhookUrl
GENERIC_TIMEZONE=America/Sao_Paulo
TZ=America/Sao_Paulo
ASSISTANT_VERSION=latest
ANTHROPIC_MODEL=claude-haiku-4-5-20251001
EXECUTIONS_DATA_MAX_AGE=168
EXECUTIONS_DATA_PRUNE_MAX_COUNT=1000
SECONDARY_NAME=
CNJ_API_KEY=
CLOUDFLARE_TUNNEL_TOKEN=
"@

    [IO.File]::WriteAllText(
        (Join-Path (Get-Location) ".env"),
        $content,
        [Text.UTF8Encoding]::new($false)
    )
    $telegramToken = $null
    $anthropicKey = $null
    Write-Host "Arquivo .env criado."
}
else {
    Write-Host "Usando o .env existente."
}

docker compose pull
docker compose up -d

Write-Host ""
Write-Host "Instalacao iniciada."
Write-Host "Abra o n8n na URL configurada, crie o usuario local e ative apenas o workflow escolhido."
Write-Host "O Telegram exige uma URL publica HTTPS para ativar o trigger."
