# Gera os segredos que o stack precisa e imprime na tela.
#
# Nao escreve arquivo nenhum: copie as linhas para o campo de ambiente do
# Dockge (ou para o seu .env) e limpe o console depois.
#
#   .\scripts\gen-secrets.ps1
$ErrorActionPreference = "Stop"

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

Write-Output "PG_PASSWORD=$(New-RandomHex 24)"
Write-Output "N8N_ENCRYPTION_KEY=$(New-RandomHex 32)"

Write-Warning "Guarde N8N_ENCRYPTION_KEY em um gerenciador de senhas: sem ela as credenciais salvas no n8n nao podem ser lidas de volta a partir de um backup."
