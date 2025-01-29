local basalt = require("/GUI/basalt")

-- Peripherals setup
local function loadPeripherals()
    local file = fs.open("peripherals.dat", "r")
    if not file then
        print("Error: Unable to load peripherals data.")
        return nil
    end
    local peripheralsData = file.readAll() 
    file.close() 
    local peripheralsTable = textutils.unserialize(peripheralsData)
    return peripheralsTable
end

local peripheralsTable = loadPeripherals()
if not peripheralsTable then
    return 
end

-- Loop through the peripherals table and wrap the peripherals dynamically
for _, peripheralData in ipairs(peripheralsTable) do
    local peripheralType = peripheralData.type
    local peripheralName = peripheralData.name
    local label = peripheralData.label

    -- Check for the peripheral type and wrap accordingly
    if peripheralType == "minecraft:chest" then
        if label == "emerald" then
            emeraldChest = peripheral.wrap(peripheralName)
        elseif label == "cash" then
            cashChest = peripheral.wrap(peripheralName)
        end
    elseif peripheralType == "minecraft:dispenser" and label == "dispenser" then
        emeraldDispenser = peripheral.wrap(peripheralName)
    end
end

local emeraldValue = 10
local function terminateHandler()
    while true do
        local event = os.pullEventRaw()
        if event == "terminate" then
            print("Termination detected. Rebooting...")
            os.reboot()
        end
    end
end

local function safeEventLoop()
	basalt.onEvent(function(event)
   	 if(event=="terminate")then
        os.reboot()
        return
    end
	end)
end

local function roundNumber(num)
    local intPart, decimalPart = math.modf(num)
    if decimalPart >= 0.5 then
        return math.ceil(num)
    else
        return math.floor(num)
    end
end

-- GUI Setup
local mainFrame = basalt.createFrame()
    :setBackground(colors.white)
	
local mainLogo = mainFrame:addTextfield()
	:setBackground(colors.white)
	:setForeground(colors.green)
	:setPosition(17,5)
	:setSize(20,1)
	mainLogo:addKeywords(colors.orange, {"first", "Exchange", "third"})
	mainLogo:addLine("Emerald Exchange")

local mainText = mainFrame:addFlexbox()
	:setPosition(8, 12)
	:setSize(36,7)
	:setBackground(colors.lightGray)
	:setWrap("wrap")
local warpSetting = mainText:getWrap()

local emeraldInput = mainFrame:addInput()
    :setSize(15, 1)
    :setPosition(10, 9)
	:setBackground(colors.lightGray, "#", colors.lightGray)
	:setForeground(colors.black)
    :setDefaultText("Enter Quantity")
    :setInputType("number")


local outputTextBox = mainText:addTextfield()
    :setPosition(8, 12)
	:setSize(35,6)
	:setBackground(colors.green, "#", colors.lightGray)
	:setForeground(colors.black)
		outputTextBox:addLine(" ")
   		outputTextBox:addLine(" ")
    	outputTextBox:addLine(" ")
    	outputTextBox:addLine(" ")
		outputTextBox:addLine(" ")

local emeraldCheckbox = mainFrame:addTextfield()
	:setPosition(36,1)
	:setSize(18,3)
	:setBackground(colors.white, "#", colors.black)
	:setForeground(colors.lime)
	:addLine(" ")

local exchangeButton = mainFrame:addButton()
    :setPosition(28, 8)
    :setSize(10, 3)
    :setText("Exchange")

-- Payment values table
local paymentValues = {
    ["jackseconomy:penny"] = 0.01,
    ["jackseconomy:nickel"] = 0.05,
    ["jackseconomy:dime"] = 0.10,
    ["jackseconomy:quarter"] = 0.25,
    ["jackseconomy:dollar_bill"] = 1,
    ["jackseconomy:five_dollar_bill"] = 5,
    ["jackseconomy:ten_dollar_bill"] = 10,
    ["jackseconomy:twenty_dollar_bill"] = 20,
    ["jackseconomy:fifty_dollar_bill"] = 50,
    ["jackseconomy:hundred_dollar_bill"] = 100,
	["jackseconomy:thousand_dollar_bill"] = 1000,
}
local termThread = mainFrame:addThread()
-- Function to check for cash in the dispenser
local function checkDispenserCash()
    local totalCash = 0
    local items = emeraldDispenser.list()

    for slot, item in pairs(items) do
        local itemValue = paymentValues[item.name]
        if itemValue then
            totalCash = totalCash + (itemValue * item.count)
        end
    end

    return totalCash
end

-- Function to move cash to the cash chest
local function moveCashToChest()
    for slot, item in pairs(emeraldDispenser.list()) do
        emeraldDispenser.pushItems(peripheral.getName(cashChest), slot, item.count)
    end
end

-- Function to dispense change
local function dispenseChange(changeDue)
    local changeDispensed = {}

    for slot, item in pairs(cashChest.list()) do
        local itemValue = paymentValues[item.name] or 0
        while changeDue >= itemValue and item.count > 0 do
            cashChest.pushItems(peripheral.getName(emeraldDispenser), slot, 1)
            changeDue = changeDue - itemValue
            item.count = item.count - 1

            -- Track what has been dispensed
            if changeDispensed[item.name] then
                changeDispensed[item.name] = changeDispensed[item.name] + 1
            else
                changeDispensed[item.name] = 1
            end
        end
    end

    return changeDispensed
end

-- Function to check the emerald chest
local function checkEmeraldChest()
    local items = emeraldChest.list()
    local totalEmeralds = 0

    for _, item in pairs(items) do
        if item.name == "minecraft:emerald" then
            totalEmeralds = totalEmeralds + item.count
        end
    end

    return totalEmeralds
end

-- Function to process payment
local function processPayment(totalCost)
    local totalReceived = 0
    local isPaid = false
    while not isPaid do
		parallel.waitForAny(terminateHandler,function()
        totalReceived = checkDispenserCash()

        if totalReceived >= totalCost then
            isPaid = true
            outputTextBox:editLine(2,"Payment received: $" .. totalReceived)
			outputTextBox:editLine(3, "  ")
            moveCashToChest() -- Move cash to the chest

            return totalReceived
        else
            outputTextBox:editLine(2, "Total received: $" .. totalReceived .. ". ")
			outputTextBox:editLine(3, "Please add cash into the dispenser")
            sleep(0.1) -- Pause for a bit to allow for more payment
        end
		end)
    end
end

-- Function to move emeralds from the chest to the dispenser, using the correct slot
local function moveEmeraldsToDispenser(emeraldsToExchange)
    local remainingEmeralds = emeraldsToExchange

    -- Loop through all the slots in the chest
    for slot, item in pairs(emeraldChest.list()) do
        if item.name == "minecraft:emerald" then
            local emeraldsInSlot = item.count
            local emeraldsToMove = math.min(emeraldsInSlot, remainingEmeralds)
            emeraldChest.pushItems(peripheral.getName(emeraldDispenser), slot, emeraldsToMove)
            remainingEmeralds = remainingEmeralds - emeraldsToMove
            if remainingEmeralds <= 0 then
                break
            end
        end
    end
    return emeraldsToExchange - remainingEmeralds
end

-- Main function to handle emerald exchange
local function handleExchange(emeraldsToExchange, totalCost, currentEmeralds)
    local totalEmeralds = checkEmeraldChest()
	termThread:start(safeEventLoop)
    emeraldCheckbox:editLine(1, "Available E$:" .. totalEmeralds):setForeground(colors.lime)

    if emeraldsToExchange <= currentEmeralds then
        -- Process payment and wait for the exact amount
        local totalReceived = processPayment(totalCost)
		if totalRecived ~= nil then
        	local changeDue = totalReceived - totalCost
		else
			return
		end
        if changeDue > 0 then
            local dispensed = dispenseChange(changeDue)
            outputTextBox:editLine(3, "Change dispensed: $" .. changeDue)
        else
            outputTextBox:editLine(3, "No change due.")
        end

        -- Move emeralds from multiple slots to the dispenser
        local emeraldsMoved = moveEmeraldsToDispenser(emeraldsToExchange)

        if emeraldsMoved == emeraldsToExchange then
            outputTextBox:editLine(4, "Exchanged " .. emeraldsToExchange .. " emerald(s).")
        else
            outputTextBox:editLine(4, "Only " .. emeraldsMoved .. " emerald(s) could be exchanged.")
        end
        local totalEmeralds = checkEmeraldChest()
    	emeraldCheckbox:editLine(1, "Available E$:" .. totalEmeralds):setForeground(colors.lime)
        emeraldInput:setValue("")
        sleep(4)
		outputTextBox:editLine(1," ")
   		outputTextBox:editLine(2," ")
    	outputTextBox:editLine(3," ")
    	outputTextBox:editLine(4," ")
		outputTextBox:editLine(5," ")
    else
        outputTextBox:editLine(4, "Not enough emeralds available.")
		outputTextBox:editLine(5,"Current: " .. currentEmeralds)
	end
end

-- Setup button click action
local function exchangeButtonClick()
		local totalEmeralds = checkEmeraldChest()
		outputTextBox:editLine(1," ")
   		outputTextBox:editLine(2," ")
    	outputTextBox:editLine(3," ")
    	outputTextBox:editLine(4," ")
		outputTextBox:editLine(5," ")
   		emeraldCheckbox:editLine(1, "Available E$:" .. totalEmeralds):setForeground(colors.lime)
    local emeraldsToExchange = tonumber(emeraldInput:getValue()) -- Get the input as a number
	if emeraldsToExchange == nil then
		emeraldCheckbox:editLine(1, "Available E$:" .. totalEmeralds):setForeground(colors.lime)
	else
    	if emeraldsToExchange > 0 then
            local emeraldsToExchange = roundNumber(emeraldsToExchange)
        	local currentEmeralds = checkEmeraldChest()
        	local totalCost = emeraldValue * emeraldsToExchange
        	outputTextBox:editLine(1, "Waiting for payment of $" .. totalCost)
			parallel.waitForAny(
            	function() handleExchange(emeraldsToExchange, totalCost, currentEmeralds) end,
            	function() basalt.autoUpdate() end -- Keep GUI responsive
        	)

    	else
        	outputTextBox:editLine(4,"Invalid input. Please enter a valid number.")
    	end
	end
end
local totalEmeralds = checkEmeraldChest()
	
    emeraldCheckbox:editLine(1, "Available E$:" .. totalEmeralds):setForeground(colors.lime)
	termThread:start(safeEventLoop)
	exchangeButton:onClick(exchangeButtonClick)
	basalt.autoUpdate()
