--Объект содержит методы визуального представления игры
local View = {};
View.__index = View;

function View.new()
    local self = setmetatable({},View);
    return self;
end

function View:render(grid, width, height)
    local header = "    " --отступ от левого края;
    for x = 1, width do
        --[[ Число само превращается в строку если сложить со строкой.
             Понимаю, что таком образом создаются аллокации в куче. Надо использовать table.concat, но здесь пойдет]]
        header = header .. (x - 1) .. " ";
    end
    print(header);

    -- Разделительная линия. string.rep повторяет строку нужное число раз
    print("    " .. string.rep("- ", width));

    --заполнение строк
    for y = 1, height do
        --Номер строки для отображение. Наинается с 0. Плюс разделитель
        local row = (y - 1) .. " | ";
        for x = 1, width do
            local gem = grid[y][x];
            if gem then                         -- расстояние между клетками по горизонтали
                row = row .. gem:getSymbol() .. " "; 
            else
                row = row .. "."; -- пустая клетка
            end
        end
        print(row);
    end
    print("") --перенос строки
end

function View:help()
    print("Match 3. Команды:")
    print("  m x y d  - двинуть кристалл: x и y от 0 до 9,")
    print("  d - направление: l (влево), r (вправо), u (вверх), d (вниз)")
    print("  q - выход")
    print("  Пример: m 3 0 r")
    print("")
end

--Вывод сообщений в консоль
function View:message(text)
    print(text);
end

return View;