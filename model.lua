local Gem = require("gem"); --импортируем кристал

local Model = {};
Model.__index = Model;

--кол-во кристалов вряд для мэтча
local MIN_MATCH_CONNT = 3;

function Model.new(view, width, height, colorsCount)
    local self = setmetatable({},Model);--указываем Model как родитель новому объекту
    self.view = view;
    self.width = width;
    self.height = height;
    self.colors = colorsCount;
    self.grid = {};
    return self;
end

function Model:init()
    self.grid = {};
    for y = 1, self.height do
        self.grid[y] = {} -- создаем строку в таблице
        for x = 1, self.width do
            self.grid[y][x] = self:randomGem(); --записываем случайный кристал
        end
    end

    self:mix();
end

--Метод проверяет не вышли мы за пределы сетки
function Model:isInside(x,y)
    return x >= 1 and x <= self.width and y >= 1 and y <= self.height;
end


--Метод проверяет есть ли возможные ходы на сетке (иначе играть нет смысла)
function Model:hasPossibleMove()
    --ходим по сетке
    for y = 1, self.height do
        for x = 1, self.width do
            local from = {x = x, y = y}; --начало проверки соседей
            local neighbours =           --соседи кристалла(справа и снизу)
            {
                {x = x + 1, y = y},
                {x = x, y = y + 1}
            }

            for _ , to in pairs(neighbours) do
                if self:isInside(to.x, to.y) then
                    --что бы понять есть ли мэтч - нам надо сымитировать ход
                    self:swap(from, to);
                    local _, found = self:findMatches();
                    self:swap(from, to); --откатываем пробный ход

                    if found then
                        return true;
                    end
                end
            end
        end
    end

    return false --не найдено возможных ходов;
end

--Метод меняет местами ячейки
function Model:swap(from, to)
    self.grid[from.y][from.x], self.grid[to.y][to.x] = self.grid[to.y][to.x], self.grid[from.y][from.x];
end

--[[перемешивание поля.Берём те же самые кристаллы и раскладываем их заново так,
    чтобы готовых троек не было, но ход при этом нашёлся.]]
function Model:mix()
    --то, что сейчас есть в сетке - помещаес во временный список
    local tempList = {};
    for y = 1, self.height do
        for x = 1, self.width do
            table.insert(tempList, self.grid[y][x]);
        end
    end

    local ok = false;
    local attempts = 0;
    local attemptsMaxCount = 100;

    repeat -- аналог do...while в c#, на сколько я понял
        self:shuffle(tempList);
        self:layout(tempList);

        local _, found = self:findMatches();
        ok = (not found) and self:hasPossibleMove();
        attempts = attempts + 1;
    until ok or attempts >= attemptsMaxCount --если долго не будет выпадать комбинация с возможными ходами - не вешаем компьютер
end

function Model:move(from, to)
    if not self:isInside(from.x, from.y) or not self:isInside(to.x, to.y) then
        return false, "координаты за пределами поля"
    end

    --[[Манхэттенское расстояние: сумма сдвигов по осям. У соседа по горизонтали
        это 1 + 0, у соседа по вертикали 0 + 1. Любая другая клетка даёт не 1.]]
    local distance = math.abs(from.x - to.x) + math.abs(from.y - to.y);
    if distance ~= 1 then
        return false, "меняться могут только соседние кристаллы"
    end

    self:swap(from, to);

    --todo можно отрендерить, поставить паузу

    local _, found = self:findMatches();

    if not found then
        self:swap(from, to);
        --todo можно отрендерить
        return false, "такой ход не собирает линию из трёх"
    end

    return true; -- ход удался, main ждёт именно true
end

--Метод ичет мэтчи. И если они есть возвращает координаты клеток и флаг (нашли/не нашли)
function Model:findMatches()
    local marked = {}; --кристалы на удаление
    for y = 1, self.height do
        marked[y] = {}; --инициализируем пустую сетку
    end

    local found = false;

   for y = 1, self.height do --идем по строкам
        local x = 1;
        while x <= self.width do
            local length = 1; --длинна мэтча
            while x + length <= self.width--пока не дошли до конца строки
                and self.grid[y][x + length].color == self.grid[y][x].color do -- ицвет клетки = цвету следующей клетки
                length = length + 1;
            end

            if length >= 3 then --если есть мэтч
                for i = x, x + length - 1 do
                    marked[y][i] = true; --сохраняем координаты
                end
                found = true; --флаг, что есть мэтч
            end

            x = x + length; --прыгаем через мэтч или на следующую клетку
        end
    end

    --фто же самое, но по колонкам
    for x = 1, self.width do
        local y = 1
        while y <= self.height do
            local length = 1;
            while y + length <= self.height
                and self.grid[y + length][x].color == self.grid[y][x].color do
                length = length + 1;
            end

            if length >= 3 then
                for i = y, y + length - 1 do
                    marked[i][x] = true;
                end
                found = true;
            end

            y = y + length;
        end
    end

    return marked, found
end

-- tick() - один шаг игры: удалить тройки, сдвинуть вниз, досыпать сверху
function Model:tick()
    local marked, found = self:findMatches()
    if not found then
        return false -- ничего не изменилось, каскад зАакончен
    end

    self:removeMatches(marked)
    self:applyGravity()
    self:refill()
    return true
end

--[[Метод опускает все ячейки вниз, что были над мэтчем.
    По каждому столбу идем снизу вверх (верх это y = self.height) и запоминам первую попавшуюся пустую клетку в writeY.
    потом шагаем дальше вниз по пустым клеткам до первой не пустой, и кладем её в self.grid (writeY, x). Клетку откуда взяли зануляем]]
function Model:applyGravity()
    for x = 1, self.width do
        local writeY = self.height -- строка, куда положим следующий кристалл

        for y = self.height, 1, -1 do
            if self.grid[y][x] then --если клетка не пустая
                if y ~= writeY then 
                    --спускаем ячейку в пустую часть
                    self.grid[writeY][x] = self.grid[y][x]
                    self.grid[y][x] = nil
                end
                writeY = writeY - 1
            end
        end
    end
end

-- Досыпает новые случайные кристаллы во все пустые клетки. (например когда после спуска сверху есть пустые)
function Model:refill()
    for y = 1, self.height do
        for x = 1, self.width do
            if not self.grid[y][x] then
                self.grid[y][x] = self:randomGem()
            end
        end
    end
end

-- Метод удаляет мэтчи по координатам
function Model:removeMatches(marked)
    for y = 1, self.height do
        for x = 1, self.height do
            local gem = self.grid[y][x];
            if marked[y][x] then -- если в списке marked есть ячейкуа с такими координатами
                gem:onDistroy(self, x, y); -- обычный кристал ничего не делает, особый (наследник) выполнит свой эффект
                self.grid[y][x] = nil;
            end
        end
    end
end

--[[Достроит ли кристалл цвета color тройку, если положить его в клетку (x, y).
    Смотрим только влево и вверх. клетки справа и снизу ещё не разложены.]]
function Model:makesLine(x, y, color)
    if x >= MIN_MATCH_CONNT -- мэтч только если кристалов в ряд >=MIN_MATCH_CONNT по условию
        and self.grid[y][x - 1].color == color
        and self.grid[y][x - 2].color == color then
        return true
    end

    if y >= MIN_MATCH_CONNT
        and self.grid[y - 1][x].color == color
        and self.grid[y - 2][x].color == color then
        return true
    end

    return false;
end

--[[Раскладывает кристаллы из списка по полю слева направо, сверху вниз.
    В каждую клетку кладём первый кристалл, который не достраивает тройку.]]
function Model:layout(list)
    -- рабочая копия списка, из неё будем вынимать кристаллы
    local pool = {}
    for i = 1, #list do
        pool[i] = list[i]
    end

    for y = 1, self.height do
        for x = 1, self.width do
            local index = 1 -- запасной вариант, если подходящего не нашлось

            for i = 1, #pool do
                if not self:makesLine(x, y, pool[i].color) then
                    index = i
                    break
                end
            end

            -- table.remove достаёт элемент из списка и сдвигает остальные
            self.grid[y][x] = table.remove(pool, index)
        end
    end
end

--Тасование Фишера-Йетса
function Model:shuffle(list)
    for i = #list, 2, -1 do  -- #list аналог list.count в c#
        local j = math.random(i);
        list[i], list[j] = list[j], list[i]; -- случайное число число с индексом j меняем местами с list[i]
    end
end

-- Новый кристалл случайного цвета
function Model:randomGem()
    return Gem.new(math.random(self.colors)) -- случайное число от 0 до кол - ва цветов
end

--модель не занимается отрисовкой. Просим это сделать вьюшку
function Model:render()
    self.view:render(self.grid, self.width, self.height)
end

return Model;