-- Serviços do Roblox
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

-- Variáveis do Jogador Local
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Configurações e Estados Iniciais do Painel
local Flags = {
    AimbotAtivo = true,
    EspAtivo = true,
    FovAtivo = true
}

local Config = {
    AimbotSuave = 0.15,
    RaioFov = 150,
    CorFov = Color3.fromRGB(0, 255, 150),
    CorESP = Color3.fromRGB(255, 0, 0),
    TeclaAtivacao = Enum.UserInputType.MouseButton2
}

local SegurandoBotaoAtivacao = false

------------------------------------------------------------------------
-- 🎨 CRIAÇÃO DA INTERFACE GRÁFICA (PAINEL)
------------------------------------------------------------------------

-- Container Principal no CoreGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PainelExecutores"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

-- Janela Principal (Menu)
local FramePrincipal = Instance.new("Frame")
FramePrincipal.Size = UDim2.new(0, 250, 0, 300)
FramePrincipal.Position = UDim2.new(0.05, 0, 0.3, 0)
FramePrincipal.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
FramePrincipal.BorderSizePixel = 0
FramePrincipal.Active = true
FramePrincipal.Draggable = true -- Permite arrastar o painel com o mouse
FramePrincipal.Parent = ScreenGui

-- Canto arredondado para o painel
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = FramePrincipal

-- Título do Menu
local Titulo = Instance.new("TextLabel")
Titulo.Size = UDim2.new(1, 0, 0, 40)
Titulo.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Titulo.Text = "   Premium Hub v1.0"
Titulo.TextColor3 = Color3.fromRGB(255, 255, 255)
Titulo.TextXAlignment = Enum.TextXAlignment.Left
Titulo.Font = Enum.Font.SourceSansBold
Titulo.TextSize = 18
Titulo.Parent = FramePrincipal

local TituloCorner = Instance.new("UICorner")
TituloCorner.CornerRadius = UDim.new(0, 8)
TituloCorner.Parent = Titulo

-- Função auxiliar para criar botões de ligar/desligar (Toggles)
local function criarBotaoToggle(texto, posicaoY, flagName)
    local Botao = Instance.new("TextButton")
    Botao.Size = UDim2.new(0, 210, 0, 40)
    Botao.Position = UDim2.new(0, 20, 0, posicaoY)
    Botao.Font = Enum.Font.SourceSansSemibold
    Botao.TextSize = 16
    Botao.BorderSizePixel = 0
    Botao.Parent = FramePrincipal
    
    local BotaoCorner = Instance.new("UICorner")
    BotaoCorner.CornerRadius = UDim.new(0, 6)
    BotaoCorner.Parent = Botao

    -- Função para atualizar visualmente o estado do botão
    local function atualizarVisual()
        if Flags[flagName] then
            Botao.BackgroundColor3 = Color3.fromRGB(0, 180, 100) -- Verde (Ativado)
            Botao.Text = texto .. ": LIGADO"
            Botao.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            Botao.BackgroundColor3 = Color3.fromRGB(50, 50, 50) -- Cinza (Desativado)
            Botao.Text = texto .. ": DESLIGADO"
            Botao.TextColor3 = Color3.fromRGB(150, 150, 150)
        end
    end

    Botao.MouseButton1Click:Connect(function()
        Flags[flagName] = not Flags[flagName]
        atualizarVisual()
    end)

    atualizarVisual()
end

-- Instanciando os botões no painel
criarBotaoToggle("Aimbot Suave", 60, "AimbotAtivo")
criarBotaoToggle("Visualização ESP", 110, "EspAtivo")
criarBotaoToggle("Círculo de FOV", 160, "FovAtivo")

-- Texto informativo no rodapé
local InfoTexto = Instance.new("TextLabel")
InfoTexto.Size = UDim2.new(1, 0, 0, 30)
InfoTexto.Position = UDim2.new(0, 0, 1, -30)
InfoTexto.BackgroundTransparency = 1
InfoTexto.Text = "Aperte 'Insert' para abrir/fechar"
InfoTexto.TextColor3 = Color3.fromRGB(120, 120, 120)
InfoTexto.Font = Enum.Font.SourceSansItalic
InfoTexto.TextSize = 14
InfoTexto.Parent = FramePrincipal

-- Alternar visibilidade do painel com a tecla INSERT
UserInputService.InputBegan:Connect(function(input, processado)
    if not processado and input.KeyCode == Enum.KeyCode.Insert then
        FramePrincipal.Visible = not FramePrincipal.Visible
    end
end)

------------------------------------------------------------------------
-- ⚙️ LOGICA DO AIMBOT, ESP E FOV (INTEGRADOS AS FLAGS)
------------------------------------------------------------------------

-- Inicializa o Círculo de FOV usando a API Drawing
local CirculoFOV = Drawing.new("Circle")
CirculoFOV.Thickness = 1.5
CirculoFOV.Radius = Config.RaioFov
CirculoFOV.Color = Config.CorFov
CirculoFOV.Filled = false
CirculoFOV.Transparency = 0.8

-- Checagem de paredes (Raycasting)
local function inimigoVisivel(posicaoAlvo, personagemInimigo)
    local origem = Camera.CFrame.Position
    local direcao = posicaoAlvo - origem
    local parametrosRaycast = RaycastParams.new()
    parametrosRaycast.FilterType = Enum.RaycastFilterType.Exclude
    parametrosRaycast.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    
    local resultado = Workspace:Raycast(origem, direcao, parametrosRaycast)
    if not resultado or resultado.Instance:IsDescendantOf(personagemInimigo) then
        return true
    end
    return false
end

-- Busca o alvo mais próximo do mouse
local function obterInimigoValido()
    local alvoMaisProximo = nil
    local menorDistanciaMouse = Config.RaioFov
    local centroTela = Camera.ViewportSize / 2

    for _, jogador in ipairs(Players:GetPlayers()) do
        if jogador ~= LocalPlayer and jogador.Team ~= LocalPlayer.Team then
            local personagem = jogador.Character
            if personagem and personagem:FindFirstChild("Head") and personagem:FindFirstChild("Humanoid") then
                if personagem.Humanoid.Health > 0 then
                    local posicaoCabeca = personagem.Head.Position
                    local posicaoTela, visivelNaTela = Camera:WorldToViewportPoint(posicaoCabeca)
                    
                    if visivelNaTela then
                        local vetorDistancia = Vector2.new(posicaoTela.X, posicaoTela.Y) - centroTela
                        local distanciaMouse = vetorDistancia.Magnitude

                        if distanciaMouse < menorDistanciaMouse then
                            if inimigoVisivel(posicaoCabeca, personagem) then
                                menorDistanciaMouse = distanciaMouse
                                alvoMaisProximo =  personagem
                            end
                        end
                    end
                end
            end
        end
    end
    return alvoMaisProximo
end

-- Gerenciador do ESP (Highlight) controlado pela flag
local function gerenciarESP()
    for _, jogador in ipairs(Players:GetPlayers()) do
        if jogador ~= LocalPlayer then
            local personagem = jogador.Character
            if personagem then
                local destaque = personagem:FindFirstChild("CaixaESP")
                if Flags.EspAtivo and jogador.Team ~= LocalPlayer.Team then
                    -- Cria se não existir
                    if not destaque then
                        destaque = Instance.new("Highlight")
                        destaque.Name = "CaixaESP"
                        destaque.FillTransparency = 0.8
                        destaque.OutlineTransparency = 0
                        destaque.FillColor = Config.CorESP
                        destaque.OutlineColor = Config.CorESP
                        destaque.Adornee = personagem
                        destaque.Parent = personagem
                    end
                else
                    -- Remove se a flag foi desligada
                    if destaque then destaque:Destroy() end
                end
            end
        end
    end
end

-- Inputs do mouse para ativar a trava do Aimbot
UserInputService.InputBegan:Connect(function(input, processado)
    if processado then return end
    if input.UserInputType == Config.TeclaAtivacao then SegurandoBotaoAtivacao = true end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Config.TeclaAtivacao then SegurandoBotaoAtivacao = false end
end)

-- Loop principal executado a cada frame do jogo
RunService.RenderStepped:Connect(function()
    local centroTela = Camera.ViewportSize / 2
    
    -- Atualiza e renderiza o Círculo de FOV com base na Flag
    CirculoFOV.Position = Vector2.new(centroTela.X, centroTela.Y)
    CirculoFOV.Visible = Flags.FovAtivo

    -- Executa a atualização do ESP periodicamente
    gerenciarESP()

    -- Executa o movimento do Aimbot se estiver ativo e o botão estiver pressionado
    if Flags.AimbotAtivo and SegurandoBotaoAtivacao then
        local alvo = obterInimigoValido()
        if alvo and alvo:FindFirstChild("Head") then
            local cframeAtual = Camera.CFrame
            local cframeAlvo = CFrame.new(cframeAtual.Position, alvo.Head.Position)
            Camera.CFrame = cframeAtual:Lerp(cframeAlvo, Config.AimbotSuave)
        end
    end
end)

-- Garante que novos jogadores também passem pelo fluxo do ESP ao entrar ou reviver
Players.PlayerAdded:Connect(function(jogador)
    jogador.CharacterAdded:Connect(function() task.wait(0.5); gerenciarESP() end)
end)
