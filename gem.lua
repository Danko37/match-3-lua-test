local Gem = {};
Gem.__index = Gem; --для использования объекта Gem как родителя через setmetatable - надо сетапить Gem.__index

-- Буквы для отрисовки: цвет 1 - "A", цвет 2 - "B" и так далее
local LETTERS = { "A", "B", "C", "D", "E", "F" };

function Gem.new(colorIndex)
    local self = setmetatable({}, Gem);--новый объект наследуется от Gem
    self.color = colorIndex;            -- число от 1 до 6
    return self;
end

--Метод получает сивол для отрисовки по цвету
function Gem:getSymbol()
    return LETTERS[self.color];
end

--[[Эффект кристалла. Аналог virtual-метода в c#: у обычного кристалла тело пустое,
    наследники его переопределяют.]]
function Gem:effect(model, x, y)

end

--Событие на удаление кристала. Простые кристалы ничего не делают. Но если особенны (наследник Gem) - выполнит свой effect
function Gem:onDistroy(model, x, y)
    self:effect(model, x, y);
end

return Gem; --что бы можно было подключить чере require в main