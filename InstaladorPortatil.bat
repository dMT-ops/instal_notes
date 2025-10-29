@echo off
:: ============================================
:: INSTALADOR AUTOMATICO PORTATIL v3.0
:: DIAGONAL - 2025
:: ============================================

setlocal enabledelayedexpansion
set DRIVE=%~d0
set PASTA_INSTALADOR=%DRIVE%\InstaladorAutomatico

title DIAGONAL - Instalador Automatico v3.0
color 0B
mode con: cols=85 lines=35

:: ============================================
:: VERIFICACAO INICIAL - PRIMEIRA EXECUCAO
:: ============================================

if not exist "%PASTA_INSTALADOR%" (
    cls
    echo.
    echo  ═══════════════════════════════════════════════════════════════════════════════
    echo                              PRIMEIRA EXECUCAO
    echo  ═══════════════════════════════════════════════════════════════════════════════
    echo.
    echo   Este e a primeira vez que voce esta executando este instalador!
    echo.
    echo   A estrutura necessaria sera criada automaticamente no pen drive.
    echo   Localizacao detectada: %DRIVE%
    echo.
    echo  ═══════════════════════════════════════════════════════════════════════════════
    echo.
    echo   Pressione qualquer tecla para criar a estrutura...
    pause >nul
    
    mkdir "%PASTA_INSTALADOR%" 2>nul
    mkdir "%PASTA_INSTALADOR%\Programas" 2>nul
    mkdir "%PASTA_INSTALADOR%\Fontes" 2>nul
    mkdir "%PASTA_INSTALADOR%\Logs" 2>nul
    mkdir "%PASTA_INSTALADOR%\Scripts" 2>nul
    mkdir "%PASTA_INSTALADOR%\WMIC" 2>nul
    
    echo.
    echo   [OK] Estrutura criada com sucesso!
    echo.
    echo  ═══════════════════════════════════════════════════════════════════════════════
    echo                                  PROXIMOS PASSOS
    echo  ═══════════════════════════════════════════════════════════════════════════════
    echo.
    echo   1. Adicione o script PowerShell em:
    echo      %PASTA_INSTALADOR%\Scripts\InstaladorAutomatico.ps1
    echo.
    echo   2. Adicione os instaladores em:
    echo      %PASTA_INSTALADOR%\Programas\
    echo.
    echo   3. Adicione as fontes em:
    echo      %PASTA_INSTALADOR%\Fontes\
    echo.
    echo   4. Execute este arquivo novamente
    echo.
    echo  ═══════════════════════════════════════════════════════════════════════════════
    echo.
    pause
    exit /b
)

:: ============================================
:: MENU PRINCIPAL
:: ============================================

:MENU_PRINCIPAL
cls
echo.
echo  ______________________________________________________________________________________________________
echo.
echo     ██████╗ ██╗ █████╗  ██████╗  ██████╗ ███╗   ██╗ █████╗ ██╗     
echo     ██╔══██╗██║██╔══██╗██╔════╝ ██╔═══██╗████╗  ██║██╔══██╗██║     
echo     ██║  ██║██║███████║██║  ███╗██║   ██║██╔██╗ ██║███████║██║     
echo     ██║  ██║██║██╔══██║██║   ██║██║   ██║██║╚██╗██║██╔══██║██║     
echo     ██████╔╝██║██║  ██║╚██████╔╝╚██████╔╝██║ ╚████║██║  ██║███████╗
echo     ╚═════╝ ╚═╝╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝
echo.
echo                       INSTALADOR AUTOMATICO v3.0
echo.
echo  ______________________________________________________________________________________________________
echo.
echo   Pen Drive: %DRIVE% ^| PC: %COMPUTERNAME% ^| Usuario: %USERNAME%
echo.
echo  ______________________________________________________________________________________________________
echo.
echo   -----------------------------------------------------------------------
echo   |  [1] Instalar Programas e Fontes |  [5] Verificar Estrutura         |
echo   |                                  |                                  |
echo   |  [2] Habilitar/Configurar WMIC   |  [6] Gerenciar Arquivos          |
echo   |                                  |                                  |
echo   |  [3] Trocar Hostname (DIAG/ALLU) |  [7] Informacoes do Sistema      |
echo   |                                  |                                  |
echo   |  [4] Copiar para C:\Instaladores |  [8] Ver Logs de Instalacoes     |
echo   -----------------------------------------------------------------------
echo.
echo   [0] ❌ Sair
echo.
echo  ______________________________________________________________________________________________________
echo.
set /p opcao="  Opcao: "

if "%opcao%"=="1" goto INSTALAR_LOCAL
if "%opcao%"=="2" goto HABILITAR_WMIC
if "%opcao%"=="3" goto TROCAR_HOSTNAME
if "%opcao%"=="4" goto COPIAR_ESTRUTURA
if "%opcao%"=="5" goto VERIFICAR_ESTRUTURA
if "%opcao%"=="6" goto GERENCIAR_ARQUIVOS
if "%opcao%"=="7" goto INFORMACOES_DETALHADAS
if "%opcao%"=="8" goto VER_LOGS
if "%opcao%"=="0" goto SAIR
goto MENU_PRINCIPAL

:: ============================================
:: OPCAO 1 - INSTALAR LOCAL
:: ============================================

:INSTALAR_LOCAL
cls
echo.
echo ==============================================================================================
echo                            INSTALACAO DIRETA DO PEN DRIVE
echo ==============================================================================================
echo.
echo  Esta opcao ira instalar os programas e fontes DIRETAMENTE deste pen drive.
echo.
echo  O que sera instalado:
echo  - Todos os programas da pasta: %PASTA_INSTALADOR%\Programas
echo  - Todas as fontes da pasta: %PASTA_INSTALADOR%\Fontes
echo.
echo  Tempo estimado: 20-30 minutos
echo.
echo ==============================================================================================
echo.
set /p confirma="Deseja continuar? (S/N): "

if /i not "%confirma%"=="S" goto MENU_PRINCIPAL

:: Verifica privilegios de administrador
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo [AVISO] Este script precisa de privilegios administrativos!
    echo Solicitando permissoes...
    echo.
    PowerShell -Command "Start-Process '%~f0' -Verb RunAs -ArgumentList '1'"
    exit /b
)

:: Verifica se existe o script PowerShell
if not exist "%PASTA_INSTALADOR%\Scripts\InstaladorAutomatico.ps1" (
    echo.
    echo [ERRO] Script PowerShell nao encontrado!
    echo.
    echo Esperado em: %PASTA_INSTALADOR%\Scripts\InstaladorAutomatico.ps1
    echo.
    echo Por favor, adicione o script PowerShell e execute novamente.
    echo.
    pause
    goto MENU_PRINCIPAL
)

:: Cria diretorio temporario
set TEMP_DIR=C:\InstaladorTemp_%RANDOM%
mkdir "%TEMP_DIR%" 2>nul

echo.
echo [1/3] Copiando arquivos necessarios...
xcopy "%PASTA_INSTALADOR%\Scripts\*" "%TEMP_DIR%\" /Y /Q >nul
xcopy "%PASTA_INSTALADOR%\Programas\*" "%TEMP_DIR%\Programas\" /Y /Q /E >nul
xcopy "%PASTA_INSTALADOR%\Fontes\*" "%TEMP_DIR%\Fontes\" /Y /Q /E >nul

echo [2/3] Iniciando instalacao...
echo.

:: Executa o instalador PowerShell
PowerShell.exe -ExecutionPolicy Bypass -NoProfile -File "%TEMP_DIR%\InstaladorAutomatico.ps1" -PastaInstaladores "%TEMP_DIR%\Programas" -PastaFontes "%TEMP_DIR%\Fontes"

echo.
echo [3/3] Salvando log no pen drive...
if exist "%TEMP_DIR%\instalacao_completa_log.txt" (
    set LOG_NAME=Log_%COMPUTERNAME%_%date:~-4%%date:~3,2%%date:~0,2%_%time:~0,2%%time:~3,2%.txt
    set LOG_NAME=!LOG_NAME: =0!
    copy "%TEMP_DIR%\instalacao_completa_log.txt" "%PASTA_INSTALADOR%\Logs\!LOG_NAME!" >nul
    echo Log salvo: !LOG_NAME!
)

echo.
echo Limpando arquivos temporarios...
rd /s /q "%TEMP_DIR%" 2>nul

echo.
echo ==============================================================================================
echo                               INSTALACAO CONCLUIDA!
echo ==============================================================================================
echo.
echo  O log foi salvo no pen drive: %PASTA_INSTALADOR%\Logs\
echo.
pause
goto MENU_PRINCIPAL

:: ============================================
:: OPCAO 2 - HABILITAR WMIC
:: ============================================

:HABILITAR_WMIC
cls
echo.
echo ==============================================================================================
echo                    HABILITAR/CONFIGURAR WMIC
echo ==============================================================================================
echo.
echo  O WMIC e necessario para:
echo  - Obter numero de serie da BIOS
echo  - Informacoes detalhadas de hardware
echo  - Troca automatica de hostname
echo.
echo ==============================================================================================
echo.

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERRO] Esta operacao requer privilegios de Administrador!
    echo.
    echo Clique direito no instalador e selecione "Executar como administrador"
    echo.
    pause
    goto MENU_PRINCIPAL
)

echo Testando WMIC...
echo.

wmic computersystem get name >nul 2>&1
if %errorLevel% equ 0 (
    echo [OK] WMIC ja esta funcionando!
    echo.
    echo Exemplos de uso:
    echo.
    echo Numero de Serie:
    wmic bios get serialnumber
    echo.
    echo Nome do Computador:
    wmic computersystem get name
    echo.
    echo [SUCESSO] WMIC totalmente funcional!
    echo.
    pause
    goto MENU_PRINCIPAL
)

echo [AVISO] WMIC nao esta disponivel.
echo.
echo Tentando habilitar via DISM...
dism /online /enable-feature /featurename:WMI /all /quiet

echo.
echo Testando novamente...
wmic computersystem get name >nul 2>&1
if %errorLevel% equ 0 (
    echo [OK] WMIC habilitado com sucesso!
    echo.
    wmic bios get serialnumber
) else (
    echo [INFO] WMIC nao pode ser habilitado.
    echo.
    echo O sistema usara PowerShell como alternativa automaticamente.
    echo Todas as funcoes continuarao funcionando normalmente.
)

echo.
pause
goto MENU_PRINCIPAL

:: ============================================
:: OPCAO 3 - TROCAR HOSTNAME
:: ============================================

:TROCAR_HOSTNAME
cls
echo.
echo ==============================================================================================
echo                              TROCAR HOSTNAME DA MAQUINA
echo ==============================================================================================
echo.
echo  Esta opcao altera o nome do computador baseado no numero de serie.
echo.
echo  OPCOES DISPONIVEIS:
echo.
echo  [1] DIAGONAL - Formato: DIAG-[NumeroSerie]
echo      Exemplo: DIAG-ABC123456
echo.
echo  [2] ALLUGGA (Maquinas Alugadas) - Formato: ALLUGGA-[NumeroSerie]
echo      Exemplo: ALLUGGA-XYZ789012
echo.
echo  [3] Voltar ao Menu Principal
echo.
echo ==============================================================================================
echo.

:: Verifica privilegios
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERRO] Esta operacao requer privilegios de Administrador!
    echo.
    pause
    goto MENU_PRINCIPAL
)

:: Obtem numero de serie via WMIC
echo Obtendo numero de serie da maquina...
echo.

set "SERIAL="
set "METODO=WMIC"

:: Metodo 1: WMIC
for /f "skip=1 tokens=*" %%a in ('wmic bios get serialnumber 2^>nul') do (
    if not defined SERIAL set "SERIAL=%%a"
    goto :got_serial_wmic
)
:got_serial_wmic

:: Remove espacos
if defined SERIAL set SERIAL=%SERIAL: =%

:: Metodo 2: PowerShell (se WMIC falhar)
if "%SERIAL%"=="" (
    echo [INFO] WMIC nao disponivel, usando PowerShell...
    set "METODO=PowerShell"
    
    for /f "delims=" %%a in ('PowerShell -NoProfile -Command "(Get-WmiObject Win32_BIOS).SerialNumber" 2^>nul') do (
        set "SERIAL=%%a"
    )
)

:: Verifica se conseguiu obter serial
if "%SERIAL%"=="" (
    echo.
    echo [ERRO] Nao foi possivel obter o numero de serie!
    echo.
    echo Possiveis causas:
    echo - WMIC nao esta instalado/configurado (use opcao [2])
    echo - PowerShell bloqueado
    echo - BIOS nao fornece numero de serie
    echo - Executando em maquina virtual
    echo.
    echo SOLUCAO: Defina hostname manualmente
    echo.
    set /p manual="Deseja definir hostname manualmente? (S/N): "
    if /i "!manual!"=="S" goto HOSTNAME_MANUAL
    pause
    goto MENU_PRINCIPAL
)

echo [OK] Numero de Serie obtido via %METODO%: %SERIAL%
echo.
echo Hostname atual: %COMPUTERNAME%
echo.

set /p tipo="Escolha o tipo (1=DIAGONAL / 2=ALLUGGA / 3=Voltar): "

if "%tipo%"=="1" (
    set NOVO_HOSTNAME=DIAG-%SERIAL%
    set TIPO_NOME=DIAGONAL
    goto CONFIRMAR_HOSTNAME
)

if "%tipo%"=="2" (
    set NOVO_HOSTNAME=ALLUGGA-%SERIAL%
    set TIPO_NOME=ALLUGGA
    goto CONFIRMAR_HOSTNAME
)

if "%tipo%"=="3" goto MENU_PRINCIPAL

echo.
echo Opcao invalida!
pause
goto TROCAR_HOSTNAME

:HOSTNAME_MANUAL
cls
echo.
echo ==============================================================================================
echo                          DEFINIR HOSTNAME MANUALMENTE
echo ==============================================================================================
echo.
echo  Digite o novo nome para o computador:
echo  
echo  REGRAS:
echo  - Maximo 15 caracteres
echo  - Sem espacos
echo  - Apenas letras, numeros e hifen
echo.
set /p NOVO_HOSTNAME="Novo hostname: "

if "%NOVO_HOSTNAME%"=="" (
    echo.
    echo [ERRO] Nome nao pode ser vazio!
    pause
    goto TROCAR_HOSTNAME
)

set NOVO_HOSTNAME=%NOVO_HOSTNAME: =%
set SERIAL=MANUAL
set TIPO_NOME=MANUAL
set METODO=Manual
goto CONFIRMAR_HOSTNAME

:CONFIRMAR_HOSTNAME
echo.
echo ==============================================================================================
echo                              CONFIRMACAO DE ALTERACAO
echo ==============================================================================================
echo.
echo  Tipo: %TIPO_NOME%
echo  Metodo de Deteccao: %METODO%
echo  Numero de Serie: %SERIAL%
echo  Hostname Atual: %COMPUTERNAME%
echo  Novo Hostname: %NOVO_HOSTNAME%
echo.
echo  ATENCAO: Esta operacao requer reinicializacao do computador!
echo.
echo ==============================================================================================
echo.
set /p confirma_host="Confirma a alteracao? (S/N): "

if /i not "%confirma_host%"=="S" goto MENU_PRINCIPAL

echo.
echo Alterando hostname via PowerShell...
PowerShell -NoProfile -Command "Rename-Computer -NewName '%NOVO_HOSTNAME%' -Force"

if %errorLevel% equ 0 (
    echo.
    echo [OK] Hostname alterado com sucesso!
    echo.
    echo Novo nome: %NOVO_HOSTNAME%
    echo.
    
    :: Salva log da alteracao
    (
    echo ========================================
    echo LOG DE ALTERACAO DE HOSTNAME
    echo ========================================
    echo Data: %date% %time%
    echo Computador: %COMPUTERNAME%
    echo Tipo: %TIPO_NOME%
    echo Numero de Serie: %SERIAL%
    echo Metodo: %METODO%
    echo Hostname Antigo: %COMPUTERNAME%
    echo Hostname Novo: %NOVO_HOSTNAME%
    echo Usuario: %USERNAME%
    echo ========================================
    ) >> "%PASTA_INSTALADOR%\Logs\Hostname_Changes.txt"
    
    echo.
    echo ==============================================================================================
    echo                          REINICIALIZACAO NECESSARIA
    echo ==============================================================================================
    echo.
    echo  O computador precisa ser reiniciado para aplicar as mudancas.
    echo  Log salvo em: %PASTA_INSTALADOR%\Logs\Hostname_Changes.txt
    echo.
    set /p reiniciar="Deseja reiniciar AGORA? (S/N): "
    
    if /i "!reiniciar!"=="S" (
        echo.
        echo Reiniciando em 10 segundos... Pressione Ctrl+C para cancelar.
        timeout /t 10
        shutdown /r /t 0
    ) else (
        echo.
        echo [IMPORTANTE] Reinicie manualmente para aplicar as mudancas.
    )
) else (
    echo.
    echo [ERRO] Falha ao alterar hostname!
    echo Codigo de erro: %errorLevel%
    echo.
    echo Verifique se voce tem privilegios de administrador.
)

echo.
pause
goto MENU_PRINCIPAL

:: ============================================
:: OPCAO 4 - COPIAR ESTRUTURA
:: ============================================

:COPIAR_ESTRUTURA
cls
echo.
echo ==============================================================================================
echo                         COPIAR INSTALADOR PARA O COMPUTADOR
echo ==============================================================================================
echo.
echo  Esta opcao ira copiar toda a estrutura para: C:\Instaladores
echo.
echo  Vantagens:
echo  - Instalacao mais rapida (sem depender do pen drive)
echo  - Backup local dos instaladores
echo  - Pode reutilizar apos formatacao
echo.
echo  Espaco necessario: ~5-10 GB
echo.
echo ==============================================================================================
echo.
set /p confirma="Deseja continuar? (S/N): "

if /i not "%confirma%"=="S" goto MENU_PRINCIPAL

set DESTINO=C:\Instaladores

if exist "%DESTINO%" (
    echo.
    echo [AVISO] A pasta C:\Instaladores ja existe!
    echo.
    set /p sobrescrever="Deseja sobrescrever? (S/N): "
    if /i not "!sobrescrever!"=="S" goto MENU_PRINCIPAL
)

echo.
echo [1/5] Criando estrutura de destino...
mkdir "%DESTINO%" 2>nul
mkdir "%DESTINO%\Programas" 2>nul
mkdir "%DESTINO%\Fontes" 2>nul
mkdir "%DESTINO%\Scripts" 2>nul
mkdir "%DESTINO%\Logs" 2>nul
mkdir "%DESTINO%\WMIC" 2>nul

echo [2/5] Copiando scripts...
xcopy "%PASTA_INSTALADOR%\Scripts\*" "%DESTINO%\Scripts\" /Y /Q /E

echo [3/5] Copiando programas...
xcopy "%PASTA_INSTALADOR%\Programas\*" "%DESTINO%\Programas\" /Y /Q /E

echo [4/5] Copiando fontes...
xcopy "%PASTA_INSTALADOR%\Fontes\*" "%DESTINO%\Fontes\" /Y /Q /E

echo [5/5] Copiando WMIC...
xcopy "%PASTA_INSTALADOR%\WMIC\*" "%DESTINO%\WMIC\" /Y /Q /E

echo.
echo Criando atalho na area de trabalho...
PowerShell -NoProfile -Command "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut('%USERPROFILE%\Desktop\Instalador Automatico.lnk'); $s.TargetPath = '%~f0'; $s.WorkingDirectory = '%DESTINO%'; $s.IconLocation = 'shell32.dll,21'; $s.Save()" 2>nul

echo.
echo ==============================================================================================
echo                               COPIA CONCLUIDA!
echo ==============================================================================================
echo.
echo  Instalador copiado para: C:\Instaladores
echo  Atalho criado na area de trabalho
echo.
echo  Abrindo pasta de destino...
start "" explorer "%DESTINO%"

echo.
pause
goto MENU_PRINCIPAL

:: ============================================
:: OPCAO 5 - VERIFICAR ESTRUTURA
:: ============================================

:VERIFICAR_ESTRUTURA
cls
echo.
echo ==============================================================================================
echo                            VERIFICACAO DA ESTRUTURA
echo ==============================================================================================
echo.

set ERROS=0

echo Verificando estrutura do pen drive...
echo Pasta base: %PASTA_INSTALADOR%
echo.

:: Verifica pastas
if exist "%PASTA_INSTALADOR%\Programas" (
    echo [OK] Pasta de Programas: Existe
) else (
    echo [X] Pasta de Programas: NAO EXISTE
    set /a ERROS+=1
)

if exist "%PASTA_INSTALADOR%\Fontes" (
    echo [OK] Pasta de Fontes: Existe
) else (
    echo [X] Pasta de Fontes: NAO EXISTE
    set /a ERROS+=1
)

if exist "%PASTA_INSTALADOR%\Scripts" (
    echo [OK] Pasta de Scripts: Existe
) else (
    echo [X] Pasta de Scripts: NAO EXISTE
    set /a ERROS+=1
)

if exist "%PASTA_INSTALADOR%\Logs" (
    echo [OK] Pasta de Logs: Existe
) else (
    echo [X] Pasta de Logs: NAO EXISTE
    set /a ERROS+=1
)

if exist "%PASTA_INSTALADOR%\WMIC" (
    echo [OK] Pasta de WMIC: Existe
) else (
    echo [X] Pasta de WMIC: NAO EXISTE
    set /a ERROS+=1
)

echo.
echo Verificando arquivos essenciais...
echo.

if exist "%PASTA_INSTALADOR%\Scripts\InstaladorAutomatico.ps1" (
    echo [OK] Script PowerShell: Encontrado
) else (
    echo [X] Script PowerShell: NAO ENCONTRADO
    echo     ^> Esperado: Scripts\InstaladorAutomatico.ps1
    set /a ERROS+=1
)

:: Conta instaladores
set CONT_PROG=0
for %%f in ("%PASTA_INSTALADOR%\Programas\*.exe") do set /a CONT_PROG+=1
for %%f in ("%PASTA_INSTALADOR%\Programas\*.msi") do set /a CONT_PROG+=1

echo.
echo Programas encontrados: %CONT_PROG%

:: Conta fontes
set CONT_FONTS=0
for %%f in ("%PASTA_INSTALADOR%\Fontes\*.ttf") do set /a CONT_FONTS+=1
for %%f in ("%PASTA_INSTALADOR%\Fontes\*.otf") do set /a CONT_FONTS+=1

echo Fontes encontradas: %CONT_FONTS%

:: Verifica WMIC
wmic computersystem get name >nul 2>&1
if %errorLevel% equ 0 (
    echo WMIC: Instalado e funcional
) else (
    echo WMIC: NAO instalado ou nao funcional ^(use opcao [2]^)
)

echo.
echo ==============================================================================================

if %ERROS% GTR 0 (
    echo.
    echo  [ATENCAO] Encontrados %ERROS% problema^(s^)!
    echo  Corrija antes de prosseguir.
) else (
    if %CONT_PROG% EQU 0 (
        echo.
        echo  [AVISO] Nenhum programa encontrado!
        echo  Adicione instaladores em: %PASTA_INSTALADOR%\Programas
    ) else (
        echo.
        echo  [SUCESSO] Estrutura completa e funcional!
    )
)

echo.
pause
goto MENU_PRINCIPAL

:: ============================================
:: OPCAO 6 - GERENCIAR ARQUIVOS
:: ============================================

:GERENCIAR_ARQUIVOS
cls
echo.
echo ==============================================================================================
echo                              GERENCIAR ARQUIVOS
echo ==============================================================================================
echo.
echo  [1] Abrir Pasta de Programas
echo  [2] Abrir Pasta de Fontes
echo  [3] Abrir Pasta de Scripts
echo  [4] Abrir Pasta de WMIC
echo  [5] Abrir Pasta de Logs
echo  [6] Abrir Pasta Raiz do Instalador
echo  [0] Voltar
echo.
echo ==============================================================================================
echo.
set /p opc_ger="Digite a opcao: "

if "%opc_ger%"=="1" start "" explorer "%PASTA_INSTALADOR%\Programas"
if "%opc_ger%"=="2" start "" explorer "%PASTA_INSTALADOR%\Fontes"
if "%opc_ger%"=="3" start "" explorer "%PASTA_INSTALADOR%\Scripts"
if "%opc_ger%"=="4" start "" explorer "%PASTA_INSTALADOR%\WMIC"
if "%opc_ger%"=="5" start "" explorer "%PASTA_INSTALADOR%\Logs"
if "%opc_ger%"=="6" start "" explorer "%PASTA_INSTALADOR%"
if "%opc_ger%"=="0" goto MENU_PRINCIPAL

goto GERENCIAR_ARQUIVOS

:: ============================================
:: OPCAO 7 - INFORMACOES DETALHADAS
:: ============================================

:INFORMACOES_DETALHADAS
cls
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "Write-Host ''; Write-Host '==============================================================================================' -ForegroundColor Cyan; Write-Host '                        INFORMACOES DETALHADAS DO SISTEMA' -ForegroundColor Cyan; Write-Host '==============================================================================================' -ForegroundColor Cyan; Write-Host ''; Write-Host ' SISTEMA OPERACIONAL' -ForegroundColor Yellow; $os = Get-WmiObject Win32_OperatingSystem; Write-Host ('  Nome: {0}' -f $os.Caption) -ForegroundColor Green; Write-Host ('  Versao: {0}' -f $os.Version) -ForegroundColor Green; Write-Host ('  Build: {0}' -f $os.BuildNumber) -ForegroundColor Green; Write-Host ('  Arquitetura: {0}' -f $os.OSArchitecture) -ForegroundColor Green; Write-Host ''; Write-Host ' COMPUTADOR' -ForegroundColor Yellow; $cs = Get-WmiObject Win32_ComputerSystem; Write-Host ('  Nome: {0}' -f $cs.Name) -ForegroundColor Green; Write-Host ('  Fabricante: {0}' -f $cs.Manufacturer) -ForegroundColor Green; Write-Host ('  Modelo: {0}' -f $cs.Model) -ForegroundColor Green; Write-Host ''; Write-Host ' BIOS' -ForegroundColor Yellow; $bios = Get-WmiObject Win32_BIOS; Write-Host ('  Fabricante: {0}' -f $bios.Manufacturer) -ForegroundColor Green; Write-Host ('  Numero de Serie: {0}' -f $bios.SerialNumber) -ForegroundColor Cyan; Write-Host ''; Write-Host ' PROCESSADOR' -ForegroundColor Yellow; $cpu = Get-WmiObject Win32_Processor; Write-Host ('  Nome: {0}' -f $cpu.Name) -ForegroundColor Green; Write-Host ('  Nucleos: {0} | Threads: {1}' -f $cpu.NumberOfCores, $cpu.NumberOfLogicalProcessors) -ForegroundColor Green; Write-Host ''; Write-Host ' MEMORIA RAM' -ForegroundColor Yellow; $ram = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2); Write-Host ('  Total: {0} GB' -f $ram) -ForegroundColor Green; Write-Host ''; Write-Host ' DISCOS' -ForegroundColor Yellow; Get-WmiObject Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3} | ForEach-Object { Write-Host ('  {0}\ Total: {1:N2} GB | Livre: {2:N2} GB' -f $_.DeviceID, ($_.Size / 1GB), ($_.FreeSpace / 1GB)) -ForegroundColor Green }; Write-Host ''; Write-Host '==============================================================================================' -ForegroundColor Cyan; Write-Host ''; Read-Host 'Pressione Enter para voltar'"

goto MENU_PRINCIPAL

:: ============================================
:: OPCAO 8 - VER LOGS
:: ============================================

:VER_LOGS
cls
echo.
echo ==============================================================================================
echo                                 LOGS DE INSTALACAO
echo ==============================================================================================
echo.

if not exist "%PASTA_INSTALADOR%\Logs\*.txt" (
    echo  Nenhum log encontrado.
    echo.
    echo  Os logs sao criados apos cada instalacao concluida.
    echo.
) else (
    echo  Logs encontrados:
    echo.
    dir /b /o-d "%PASTA_INSTALADOR%\Logs\*.txt"
    echo.
    set /p abrir="Deseja abrir a pasta de logs? (S/N): "
    if /i "!abrir!"=="S" start "" explorer "%PASTA_INSTALADOR%\Logs"
)

echo.
pause
goto MENU_PRINCIPAL

:: ============================================
:: SAIR
:: ============================================

:SAIR
cls
echo.
echo ==============================================================================================
echo                               ENCERRANDO INSTALADOR
echo ==============================================================================================
echo.
echo  Obrigado por usar o Instalador Automatico Portatil v3.0!
echo.
echo  Desenvolvido para Diagonal/Allugga - 2025
echo.
echo ==============================================================================================
echo.
timeout /t 3
exit /b
