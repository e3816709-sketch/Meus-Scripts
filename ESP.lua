-- Serviços principais
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Função para aplicar a linha vermelha (ESP) em um personagem
local function criarESP(player)
    -- Evita colocar o ESP no seu próprio personagem
    if player == LocalPlayer then return end

    local function aplicarHighlight(character)
        -- Remove ESP antigo se já existir para não acumular
        if character:FindFirstChild("EspVermelho") then
            character.EspVermelho:Destroy()
        end

        -- Cria o efeito de linha
        local highlight = Instance.new("Highlight")
        highlight.Name = "EspVermelho"
        highlight.FillTransparency = 1 -- Deixa o interior invisível (apenas a linha aparece)
        highlight.OutlineColor = Color3.fromRGB(255, 0, 0) -- Cor vermelha
        highlight.OutlineTransparency = 0 -- Linha totalmente visível
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop -- Visível através das paredes
        highlight.Parent = character
    end

    -- Aplica se o personagem já existir no mapa
    if player.Character then
        aplicarHighlight(player.Character)
    end

    -- Aplica novamente sempre que o jogador renascer
    player.CharacterAdded:Connect(aplicarHighlight)
end

-- Ativa o ESP para todos os jogadores que já estão no servidor
for _, player in ipairs(Players:GetPlayers()) do
    criarESP(player)
end

-- Ativa o ESP para novos jogadores que entrarem no jogo depois
Players.PlayerAdded:Connect(criarESP)
