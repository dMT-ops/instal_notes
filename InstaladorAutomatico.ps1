<#
.SYNOPSIS
    Instalador Automatizado Portatil - Diagonal/Allugga
    
.DESCRIPTION
    Instala automaticamente programas e fontes de forma personalizada
    Versao compatível com o Instalador Automatico Portatil v3.1
    
.NOTES
    Versão: 3.1
    Data: 2025
    Requer: Execução como Administrador
    Compatível com: Windows 10/11/Server 2016+
#>

# ==============================================================================
# CONFIGURAÇÕES
# ==============================================================================

param(
    [string]$PastaInstaladores = "$PSScriptRoot\Programas",
    [string]$PastaFontes = "$PSScriptRoot\Fontes",
    [switch]$ModoSilencioso = $false,
    [string]$LogFile = "instalacao_completa_log.txt"
)

# ==============================================================================
# VARIÁVEIS GLOBAIS
# ==============================================================================

$Global:Sucessos = 0
$Global:Falhas = 0
$Global:ReinicioNecessario = $false
$Global:StartTime = Get-Date
$Script:TempLog = Join-Path $env:TEMP "instalacao_temp_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# ==============================================================================
# FUNÇÕES PRINCIPAIS
# ==============================================================================

function Write-Log {
    param(
        [string]$Message, 
        [string]$Type = "INFO",
        [switch]$ConsoleOnly = $false
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Type] $Message"
    
    if (-not $ConsoleOnly) {
        Add-Content -Path $Script:TempLog -Value $logMessage
    }
    
    switch ($Type) {
        "SUCCESS" { 
            Write-Host "✓ $Message" -ForegroundColor Green
            if (-not $ConsoleOnly) {
                Add-Content -Path $LogFile -Value $logMessage
            }
        }
        "ERROR"   { 
            Write-Host "✗ $Message" -ForegroundColor Red
            if (-not $ConsoleOnly) {
                Add-Content -Path $LogFile -Value $logMessage
            }
        }
        "WARNING" { 
            Write-Host "⚠ $Message" -ForegroundColor Yellow
            if (-not $ConsoleOnly) {
                Add-Content -Path $LogFile -Value $logMessage
            }
        }
        "INFO"    { 
            Write-Host "ℹ $Message" -ForegroundColor Cyan
            if (-not $ConsoleOnly) {
                Add-Content -Path $LogFile -Value $logMessage
            }
        }
        "DEBUG"   { 
            if (-not $ModoSilencioso) {
                Write-Host "🔍 $Message" -ForegroundColor Gray
            }
        }
        default   { 
            Write-Host $Message
            if (-not $ConsoleOnly) {
                Add-Content -Path $LogFile -Value $logMessage
            }
        }
    }
}

function Write-Header {
    param([string]$Text)
    Write-Host ""
    Write-Host "=" * 80 -ForegroundColor Cyan
    Write-Host $Text.ToUpper() -ForegroundColor Cyan
    Write-Host "=" * 80 -ForegroundColor Cyan
    Write-Host ""
}

function Write-Section {
    param([string]$Text)
    Write-Host ""
    Write-Host "-" * 60 -ForegroundColor Yellow
    Write-Host $Text -ForegroundColor Yellow
    Write-Host "-" * 60 -ForegroundColor Yellow
}

function Test-Administrator {
    try {
        $user = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($user)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch {
        return $false
    }
}

function Testar-ArquivosInstaladores {
    param([string]$Pasta)
    
    if (-not (Test-Path $Pasta)) {
        Write-Log "Pasta não encontrada: $Pasta" "ERROR"
        return $false
    }
    
    $arquivos = Get-ChildItem -Path $Pasta -File -Recurse -Include *.exe, *.msi, *.msix | Where-Object { $_.Name -notlike "*uninstall*" }
    
    if ($arquivos.Count -eq 0) {
        Write-Log "Nenhum instalador encontrado em: $Pasta" "WARNING"
        return $false
    }
    
    Write-Log "Encontrados $($arquivos.Count) instaladores em $Pasta" "SUCCESS"
    
    foreach ($arquivo in $arquivos) {
        Write-Log "  - $($arquivo.Name)" "DEBUG"
    }
    
    return $true
}

function Instalar-Programa {
    param(
        [string]$DisplayName,
        [string]$FilePath,
        [string]$SilentArgs = "",
        [string]$Tipo = "EXE",
        [int]$Timeout = 600
    )
    
    Write-Section "INSTALANDO: $DisplayName"
    Write-Log "Arquivo: $(Split-Path $FilePath -Leaf)" "INFO"
    Write-Log "Tipo: $Tipo | Argumentos: $SilentArgs" "DEBUG"
    
    # Verifica se o arquivo existe
    if (-not (Test-Path $FilePath)) {
        Write-Log "Arquivo não encontrado: $FilePath" "ERROR"
        $Global:Falhas++
        return $false
    }
    
    # Verifica se já está instalado
    if (Testar-ProgramaInstalado -DisplayName $DisplayName -FilePath $FilePath) {
        Write-Log "$DisplayName já está instalado" "SUCCESS"
        $Global:Sucessos++
        return $true
    }
    
    try {
        $processParams = @{
            FilePath = $FilePath
            WindowStyle = 'Hidden'
            PassThru = $true
            ErrorAction = 'Stop'
        }
        
        if ($SilentArgs) {
            $processParams.ArgumentList = $SilentArgs
        }
        
        if ($Tipo -eq "MSI") {
            $processParams.FilePath = "msiexec.exe"
            $processParams.ArgumentList = "/i `"$FilePath`" $SilentArgs /quiet /norestart /l*v `"$env:TEMP\install_$($DisplayName -replace '[^a-zA-Z0-9]', '_').log`""
        }
        
        Write-Log "Iniciando instalação..." "DEBUG"
        $process = Start-Process @processParams
        
        # Aguarda conclusão com timeout
        if (-not $process.WaitForExit($Timeout * 1000)) {
            Write-Log "Timeout na instalação de $DisplayName" "WARNING"
            $process.Kill()
            Start-Sleep -Seconds 3
        }
        
        $exitCode = $process.ExitCode
        
        Write-Log "Código de saída: $exitCode" "DEBUG"
        
        # Interpreta códigos de saída
        switch ($exitCode) {
            0 { 
                Write-Log "$DisplayName instalado com sucesso" "SUCCESS"
                $Global:Sucessos++
                return $true 
            }
            3010 { 
                Write-Log "$DisplayName instalado (reinicialização necessária)" "SUCCESS"
                $Global:Sucessos++
                $Global:ReinicioNecessario = $true
                return $true 
            }
            1641 { 
                Write-Log "$DisplayName instalado (reinicialização necessária)" "SUCCESS"
                $Global:Sucessos++
                $Global:ReinicioNecessario = $true
                return $true 
            }
            1602 { 
                Write-Log "Instalação cancelada pelo usuário - $DisplayName" "WARNING"
                $Global:Falhas++
                return $false 
            }
            default { 
                Write-Log "Erro na instalação de $DisplayName (Código: $exitCode)" "ERROR"
                $Global:Falhas++
                return $false 
            }
        }
    }
    catch {
        Write-Log "Exceção ao instalar $DisplayName" "ERROR"
        Write-Log "Detalhes: $($_.Exception.Message)" "ERROR"
        $Global:Falhas++
        return $false
    }
}

function Testar-ProgramaInstalado {
    param(
        [string]$DisplayName,
        [string]$FilePath
    )
    
    $arquivoNome = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
    
    # Verifica no registro
    $registryPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    
    foreach ($path in $registryPaths) {
        $programas = Get-ItemProperty $path -ErrorAction SilentlyContinue | 
                    Where-Object { $_.DisplayName -like "*$DisplayName*" -or $_.DisplayName -like "*$arquivoNome*" }
        
        if ($programas) {
            return $true
        }
    }
    
    # Verifica arquivos comuns
    $commonPaths = @(
        "$env:ProgramFiles\$DisplayName",
        "$env:ProgramFiles\$arquivoNome",
        "${env:ProgramFiles(x86)}\$DisplayName", 
        "${env:ProgramFiles(x86)}\$arquivoNome"
    )
    
    foreach ($path in $commonPaths) {
        if (Test-Path $path) {
            return $true
        }
    }
    
    return $false
}

function Instalar-Fontes {
    param([string]$PastaFontes)
    
    if (-not (Test-Path $PastaFontes)) {
        Write-Log "Pasta de fontes não encontrada: $PastaFontes" "WARNING"
        return
    }
    
    $fontes = Get-ChildItem -Path $PastaFontes -File -Include *.ttf, *.otf
    
    if ($fontes.Count -eq 0) {
        Write-Log "Nenhuma fonte encontrada em: $PastaFontes" "INFO"
        return
    }
    
    Write-Section "INSTALANDO FONTES"
    Write-Log "Encontradas $($fontes.Count) fontes para instalação" "INFO"
    
    $fontesInstaladas = 0
    
    foreach ($fonte in $fontes) {
        try {
            Write-Log "Instalando fonte: $($fonte.Name)" "DEBUG"
            
            # Copia para pasta de fontes do sistema
            $destino = Join-Path $env:WINDIR "Fonts\$($fonte.Name)"
            Copy-Item -Path $fonte.FullName -Destination $destino -Force -ErrorAction Stop
            
            # Adiciona registro
            $shell = New-Object -ComObject Shell.Application
            $fontsFolder = $shell.Namespace(0x14)
            $fontsFolder.CopyHere($fonte.FullName, 0x14)
            
            $fontesInstaladas++
            Write-Log "Fonte instalada: $($fonte.Name)" "SUCCESS"
        }
        catch {
            Write-Log "Erro ao instalar fonte $($fonte.Name)" "ERROR"
            Write-Log "Detalhes: $($_.Exception.Message)" "DEBUG"
        }
    }
    
    Write-Log "Total de fontes instaladas: $fontesInstaladas/$($fontes.Count)" "SUCCESS"
}

function Obter-DetectProgramas {
    # Detecta programas disponíveis na pasta
    $programas = @()
    
    if (Test-Path $PastaInstaladores) {
        $arquivos = Get-ChildItem -Path $PastaInstaladores -File -Recurse | Where-Object {
            $_.Extension -match '\.(exe|msi|msix)$' -and $_.Name -notmatch 'uninstall|remove|remover'
        }
        
        foreach ($arquivo in $arquivos) {
            $nome = [System.IO.Path]::GetFileNameWithoutExtension($arquivo.Name)
            
            # Configurações padrão baseadas no nome do arquivo
            $parametros = ""
            $tipo = if ($arquivo.Extension -eq '.msi') { "MSI" } else { "EXE" }
            
            switch -Wildcard ($arquivo.Name) {
                "*chrome*" { 
                    $nome = "Google Chrome"
                    $parametros = "/silent /install" 
                }
                "*7z*" { 
                    $nome = "7-Zip"
                    $parametros = "/S" 
                }
                "*anydesk*" { 
                    $nome = "AnyDesk"
                    $parametros = "--install `"C:\Program Files (x86)\AnyDesk`" --start-with-win --silent" 
                }
                "*forti*" { 
                    $nome = "FortiClient VPN"
                    $parametros = "/quiet /norestart" 
                }
                "*jre*" -or "*java*" { 
                    $nome = "Java JRE"
                    $parametros = "/s INSTALL_SILENT=1 AUTO_UPDATE=0" 
                }
                "*office*" { 
                    $nome = "Microsoft Office"
                    # Verifica se existe arquivo de configuração
                    $configFile = Join-Path $arquivo.Directory "configuration.xml"
                    if (Test-Path $configFile) {
                        $parametros = "/configure configuration.xml"
                    } else {
                        $parametros = "/quiet"
                    }
                }
                "*ndd*" -or "*print*" { 
                    $nome = "NDD Print Agent"
                    $parametros = "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-" 
                }
                "*adobe*reader*" { 
                    $nome = "Adobe Reader"
                    $parametros = "/sAll /rs /rps" 
                }
                "*vscode*" { 
                    $nome = "Visual Studio Code"
                    $parametros = "/VERYSILENT /MERGETASKS=!runcode" 
                }
                default {
                    # Tenta determinar parâmetros silenciosos baseados no tipo
                    if ($tipo -eq "MSI") {
                        $parametros = "/quiet /norestart"
                    } else {
                        $parametros = "/S /quiet /silent /verysilent /norestart"
                    }
                }
            }
            
            $programas += @{
                Nome = $nome
                Caminho = $arquivo.FullName
                Parametros = $parametros
                Tipo = $tipo
            }
        }
    }
    
    return $programas
}

function Mostrar-Resumo {
    $endTime = Get-Date
    $duration = $endTime - $Global:StartTime
    
    Write-Header "RESUMO DA INSTALAÇÃO"
    
    Write-Host "📊 ESTATÍSTICAS:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Programas processados: " -NoNewline -ForegroundColor White
    Write-Host $($Global:Sucessos + $Global:Falhas) -ForegroundColor Cyan
    
    Write-Host "  ✓ Instalados com sucesso: " -NoNewline -ForegroundColor White
    Write-Host $Global:Sucessos -ForegroundColor Green
    
    Write-Host "  ✗ Falhas: " -NoNewline -ForegroundColor White
    Write-Host $Global:Falhas -ForegroundColor $(if($Global:Falhas -eq 0){"Green"}else{"Red"})
    
    Write-Host ""
    Write-Host "  ⏱️  Tempo total: " -NoNewline -ForegroundColor White
    Write-Host "$($duration.ToString('hh\:mm\:ss'))" -ForegroundColor Cyan
    
    Write-Host "  🔄 Reinício necessário: " -NoNewline -ForegroundColor White
    Write-Host $(if($Global:ReinicioNecessario){"SIM"}else{"NÃO"}) -ForegroundColor $(if($Global:ReinicioNecessario){"Yellow"}else{"Green"})
    
    Write-Host ""
    Write-Host "📄 LOGS:" -ForegroundColor Cyan
    Write-Host "  Log detalhado: " -NoNewline -ForegroundColor White
    Write-Host $Script:TempLog -ForegroundColor Gray
    Write-Host "  Log resumido: " -NoNewline -ForegroundColor White
    Write-Host $LogFile -ForegroundColor Gray
    
    # Copia log temporário para o final
    if (Test-Path $Script:TempLog) {
        Get-Content $Script:TempLog | Add-Content $LogFile
        Remove-Item $Script:TempLog -Force
    }
}

# ==============================================================================
# EXECUÇÃO PRINCIPAL
# ==============================================================================

# Inicialização
Clear-Host
Write-Header "INSTALADOR AUTOMÁTICO PORTÁTIL v3.1"
Write-Log "Iniciando instalação automática..." "INFO"
Write-Log "Data/Hora: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')" "DEBUG"
Write-Log "Computador: $env:COMPUTERNAME" "DEBUG"
Write-Log "Usuário: $env:USERNAME" "DEBUG"

# Verifica privilégios administrativos
if (-not (Test-Administrator)) {
    Write-Log "AVISO CRÍTICO: Execute como Administrador para instalação completa!" "ERROR"
    Write-Host ""
    Write-Host "Solução:" -ForegroundColor Yellow
    Write-Host "1. Clique direito no PowerShell" -ForegroundColor White
    Write-Host "2. Selecione 'Executar como Administrador'" -ForegroundColor White
    Write-Host "3. Execute o script novamente" -ForegroundColor White
    Write-Host ""
    
    if (-not $ModoSilencioso) {
        $continuar = Read-Host "Deseja continuar mesmo assim? (S/N)"
        if ($continuar -notin @('S', 's')) {
            exit 1
        }
    }
}

# Verifica pastas
Write-Section "VERIFICANDO ARQUIVOS"

if (-not (Testar-ArquivosInstaladores -Pasta $PastaInstaladores)) {
    Write-Log "Nenhum instalador encontrado. Verifique a pasta: $PastaInstaladores" "ERROR"
    
    if (-not $ModoSilencioso) {
        Write-Host ""
        $abrirPasta = Read-Host "Deseja abrir a pasta de programas? (S/N)"
        if ($abrirPasta -in @('S', 's')) {
            Start-Process explorer.exe -ArgumentList $PastaInstaladores
        }
    }
    
    pause
    exit 1
}

# Detectar programas automaticamente
Write-Section "DETECTANDO PROGRAMAS"
$programasParaInstalar = Obter-DetectProgramas

if ($programasParaInstalar.Count -eq 0) {
    Write-Log "Nenhum programa detectado para instalação" "ERROR"
    pause
    exit 1
}

Write-Log "Detectados $($programasParaInstalar.Count) programas para instalação:" "SUCCESS"
foreach ($programa in $programasParaInstalar) {
    Write-Log "  - $($programa.Nome)" "INFO"
}

# Confirmação
if (-not $ModoSilencioso) {
    Write-Host ""
    Write-Host "⚠️  ATENÇÃO: Esta operação instalará $($programasParaInstalar.Count) programas" -ForegroundColor Yellow
    Write-Host "   Tempo estimado: 15-30 minutos" -ForegroundColor Yellow
    Write-Host ""
    
    $confirmacao = Read-Host "Deseja continuar com a instalação? (S/N)"
    if ($confirmacao -notin @('S', 's')) {
        Write-Log "Instalação cancelada pelo usuário" "WARNING"
        exit
    }
}

# Instalação dos programas
Write-Section "INICIANDO INSTALAÇÕES"

foreach ($programa in $programasParaInstalar) {
    $resultado = Instalar-Programa -DisplayName $programa.Nome `
                                   -FilePath $programa.Caminho `
                                   -SilentArgs $programa.Parametros `
                                   -Tipo $programa.Tipo
    
    # Pequena pausa entre instalações
    Start-Sleep -Seconds 3
}

# Instalação de fontes
if (Test-Path $PastaFontes) {
    Instalar-Fontes -PastaFontes $PastaFontes
}

# Resumo final
Mostrar-Resumo

# Mensagem final
Write-Host ""
if ($Global:Falhas -eq 0) {
    Write-Host "🎉 INSTALAÇÃO CONCLUÍDA COM SUCESSO!" -ForegroundColor Green
} else {
    Write-Host "⚠️  INSTALAÇÃO CONCLUÍDA COM $($Global:Falhas) ERRO(S)" -ForegroundColor Yellow
}

if ($Global:ReinicioNecessario) {
    Write-Host ""
    Write-Host "🔄 REINICIALIZAÇÃO NECESSÁRIA" -ForegroundColor Yellow
    Write-Host "Alguns programas requerem reinicialização para funcionar corretamente." -ForegroundColor White
    
    if (-not $ModoSilencioso) {
        Write-Host ""
        $reiniciar = Read-Host "Deseja reiniciar o computador agora? (S/N)"
        if ($reiniciar -in @('S', 's')) {
            Write-Log "Reiniciando computador..." "INFO"
            Restart-Computer -Force
        }
    }
}

Write-Host ""
if (-not $ModoSilencioso) {
    Write-Host "Pressione qualquer tecla para fechar..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
