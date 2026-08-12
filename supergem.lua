--Заготовка для особых кристалов
local Gem = require("gem"); --база

--[[Особый кристалл. Наследование в Lua: метатаблица самой таблицы класса отправляет
    ненайденные поля в Gem. Это аналог "class SuperGem : Gem" из c#.]]
local SuperGem = setmetatable({}, { __index = Gem });
SuperGem.__index = SuperGem; --а это для экземпляров: метод ищем сначала здесь, потом в Gem

function SuperGem.new(colorIndex)
    local self = Gem.new(colorIndex);    -- вызов конструктора базы, аналог ": base(colorIndex)"
    return setmetatable(self, SuperGem); -- подменяем метатаблицу, что бы работали методы наследника
end

--Свой символ для отрисовки, что бы особый кристал было видно на поле
function SuperGem:getSymbol()
    return "*";
end

--Переопределённый эффект (override в c#). Вызывается из Gem:onDistroy
function SuperGem:effect(model, x, y)
    --todo здесь будет свой эффект (например снести соседние клетки)
end

return SuperGem; --что бы можно было подключить через require
