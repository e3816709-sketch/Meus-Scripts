-- AIMBOT MOBILE PREMIUM (FILTRO DE PAREDE + MIRA SUAVE)
local AimbotAtivo = true
local TravarNaCabeca = false -- Foca no peito para o movimento ficar mais natural
local RaioFOV = 120 -- Reduzido levemente para evitar puxadas bruscas

-- AUMENTADO PARA DEIXAR A MIRA BEM MAIS LENTA E SUAVE (Valores maiores = mira mais lenta)
local Suavidade = 15 

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Círculo FOV Visual
local CirculoFOV = Drawing.new("Circle")
CirculoFOV.Color = Color3.fromRGB(0, 255, 255) -- Ciano
CirculoFOV.Thickness = 1.5
CirculoFOV.NumSides = 20
CirculoFOV.Radius = RaioFOV
CirculoFOV.Filled = false
CirculoFOV.Visible = true

-- FUNÇÃO PARA VERIFICAR SE O INIMIGO ESTÁ ATRÁS DA PAREDE (RAYCAST)
local function estaVisivel(origem, destino, personagemInimigo)
    local parametros = RaycastParams.new()
    parametros.FilterDescendantsInstances = {LocalPlayer.Character, personagemInimigo}
    parametros.FilterType = Enum.RaycastFilterType.Exclude

    local resultadoRaycast = workspace:Raycast(origem, destino - origem, parametros)
    return resultadoRaycast == nil
end

-- FUNÇÃO PRINCIPAL DE BUSCA
local function obterInimigoMaisProximo()
    local alvoMaisProximo = nil
    local menorDistancia = RaioFOV
    local centroTela = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then 
        return nil 
    end

    for _, jogador in ipairs(Players:GetPlayers()) do
        if jogador ~= LocalPlayer and jogador.Character then
            local personagem = jogador.Character
            local parteAlvo = TravarNaCabeca and personagem:FindFirstChild("Head") or personagem:FindFirstChild("HumanoidRootPart")
            local humanoide = personagem:FindFirstChildOfClass("Humanoid")

            if parteAlvo and humanoide and humanoide.Health > 0 then
                local posicaoTela, visivelNaTela = Camera:WorldToViewportPoint(parteAlvo.Position)

                if visivelNaTela then
                    local distanciaDaMira = (Vector2.new(posicaoTela.X, posicaoTela.Y) - centroTela).Magnitude

                    if distanciaDaMira < menorDistancia then
                        local posicaoOlhos = Camera.CFrame.Position
                        if estaVisivel(posicaoOlhos, parteAlvo.Position, personagem) then
                            menorDistancia = distanciaDaMira
                            alvoMaisProximo = {parte = parteAlvo, tela = Vector2.new(posicaoTela.X, posicaoTela.Y)}
                        end
                    end
                end
            end
        end
    end
    return alvoMaisProximo
end

-- LOOP DE ATUALIZAÇÃO AJUSTADO
RunService.Heartbeat:Connect(function()
    local centroX = Camera.ViewportSize.X / 2
    local centroY = Camera.ViewportSize.Y / 2
    if centroX and centroY then
        CirculoFOV.Position = Vector2.new(centroX, centroY)
    end

    if AimbotAtivo then
        local alvoInfo = obterInimigoMaisProximo()
        if alvoInfo then
            local centroTela = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            local diferenca = (alvoInfo.tela - centroTela)
            
            pcall(function()
                UserInputService.MouseDeltaSensitivity = 1
                -- Multiplicado por math.rad de forma muito menor para suavizar a rotação
                Camera.CFrame = Camera.CFrame * CFrame.Angles(0, -math.rad(diferenca.X / Suavidade), 0)
                Camera.CFrame = Camera.CFrame * CFrame.Angles(-math.rad(diferenca.Y / Suavidade), 0, 0)
            end)
        end
    end
end)
