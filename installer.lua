-- Installer Program for GitHub Files and Basalt UI
local github_url = "https://raw.githubusercontent.com/ClassicBiz/EmeExchange/refs/heads/main/startup.lua" -- Replace with the URL of your program

local peripheralsTable = {}

function downloadFile(url, savePath)
    print("Downloading from: " .. url)
    local response = http.get(url)
    if response then
        local file = fs.open(savePath, "w")
        file.write(response.readAll())
        file.close()
        print("Downloaded and saved to " .. savePath)
    else
        print("Failed to download from " .. url)
    end
end

function createDirectory(dir)
    if not fs.exists(dir) then
        fs.makeDir(dir)
        print("Created directory: " .. dir)
    end
end

function installBasalt()
    print("Installing Basalt UI...")
    local command = "wget run https://basalt.madefor.cc/install.lua release latest.lua"
    shell.run(command)
end

function moveBasaltToGUI(dir)
    local basaltFile = "basalt.lua"
    local targetDir = dir .. "/basalt.lua" 

    if not fs.exists(dir) then
        fs.makeDir(dir)  -- Create the directory if it doesn't exist
        print("Created directory: " .. dir)
    end

    if fs.exists(basaltFile) then
        local success, err = pcall(function() 
            fs.move(basaltFile, targetDir)
        end)
        -- Handle potential errors
        if success then
            print("Moved Basalt UI into /GUI/")
        else
            print("Error moving file: " .. err)
        end
    else
        print("Basalt UI file not found, skipping move.")
    end
end

function scanPeripherals()
    local peripheralNames = peripheral.getNames()
    local labels = {
        ["minecraft:chest"] = {"emerald", "cash"},
        ["minecraft:dispenser"] = {"dispenser"}
    }

    local labelIndex = {
        ["minecraft:chest"] = 1,
        ["minecraft:dispenser"] = 1
    }

    for _, name in ipairs(peripheralNames) do
        local peripheralType = peripheral.getType(name)
        if name == "bottom" then
			print("skip")
		else
        	if peripheralType == "minecraft:chest" or peripheralType == "minecraft:dispenser" then
            	local currentLabelIndex = labelIndex[peripheralType]
            	local label = labels[peripheralType][currentLabelIndex]

            	if label then
                -- Extract only the number from the peripheral name
                	local number = tonumber(name:match("_(%d+)$")) or name
                	table.insert(peripheralsTable, {
                    	type = peripheralType,
                    	name = number,
                    	label = label
                	})

                	print("Assigned " .. peripheralType .. " " .. name .. " as " .. label)
                	labelIndex[peripheralType] = currentLabelIndex + 1
            	end
        	end
    	end
 	end
    -- Save to file for persistence
    local file = fs.open("peripherals.json", "w")
    file.write(textutils.serialize(peripheralsTable))
    file.close()
end

-- Main program logic
function runInstaller()
   createDirectory("/GUI/")
    downloadFile(github_url, "startup.lua") 
    installBasalt()
    moveBasaltToGUI("/GUI/")
    scanPeripherals()
    print("Installation complete.")
    print("Peripherals found:", #peripheralsTable)
end

runInstaller()
