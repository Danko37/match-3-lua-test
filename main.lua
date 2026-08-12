local View = require("view");
local Model = require("model");

-- Пауза между тиками, секунд.
local TICK_DELAY = 1;

--[[Направления: буква -> сдвиг по x и y.
y растёт вниз, поэтому "вверх" это -1.]]
local DIRECTIONS = {
    l = { x = -1, y = 0 },
    r = { x = 1, y = 0 },
    u = { x = 0, y = -1 },
    d = { x = 0, y = 1 },
};

--[[ Пауза. В стандартном Lua нет функции sleep, поэтому просто
-- крутим пустой цикл и смотрим на часы. Для консольной игры этого хватает.]]
local function sleep(seconds)
    local start = os.clock();
    while os.clock() - start < seconds do
        -- ждём
    end
end

local function parseCommand(line)
    line = line:lower();

    --[[Шаблоны в Lua: %s - пробел, %d - цифра, ^ и $ - начало и конец строки,
    -- скобки - то, что нужно вернуть, + - "один или больше"]]
    if line:match("^%s*q%s*$") then
        return { quit = true };
    end

    local x, y, dir = line:match("^%s*m%s+(%d+)%s+(%d+)%s+([lrud])%s*$");
    if not x then
        return nil;
    end

    return { x = tonumber(x), y = tonumber(y), dir = dir };
end

-- Правка кодировки текста консоли
local function setupConsole()
    if package.config:sub(1, 1) == "\\" then
        os.execute("chcp 65001 > nul")
    end
end

--[[Обрабатывает один ход игрока: сам ход, потом каскад тиков,
-- потом проверка на тупик.]]
local function playTurn(model, view, command)
    -- Игрок вводит 0..9, а таблицы в Lua нумеруются с 1.
    local from = { x = command.x + 1, y = command.y + 1 }
    local delta = DIRECTIONS[command.dir]
    local to = { x = from.x + delta.x, y = from.y + delta.y }

    local ok, reason = model:move(from, to)
    if not ok then
        view:message("Ход невозможен: " .. reason)
        return
    end

    --Показываем поле сразу после обмена кристаллов.
    model:render()
    sleep(TICK_DELAY)

    --Крутим тики, пока на поле хоть что-то меняется.
    while model:tick() do
        model:render()
        sleep(TICK_DELAY)
    end

    --Ходов не осталось - мешаем поле, чтобы игра могла продолжаться.
    if not model:hasPossibleMove() then
        view:message("Возможных ходов нет, перемешиваю поле")
        model:mix()
        model:render()
    end
end

local function main()
    setupConsole();
    math.randomseed(os.time()); -- иначе поле будет одинаковым при каждом запуске

    local view = View.new();
    local model = Model.new(view, 10, 10, 6);

    view:help();
    model:init();
    model:render();

    while true do
        local line = io.read();
        if not line then
            break; -- поток ввода закончился (Ctrl+Z / Ctrl+D)
        end

        local command = parseCommand(line);

        if not command then
            view:message("Не понял команду. Формат: m x y d (например m 3 0 r) или q");
        elseif command.quit then
            view:message("Выход");
            break
        else
            playTurn(model, view, command);
        end
    end
end

main();