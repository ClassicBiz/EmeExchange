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
    local basaltFile = "basalt.lua"  -- The file we want to move
    local targetDir = dir .. "/basalt.lua"  -- Full target path including the filename

    -- Ensure the target directory exists
    if not fs.exists(dir) then
        fs.makeDir(dir)  -- Create the directory if it doesn't exist
        print("Created directory: " .. dir)
    end

    -- Check if the basalt file exists before moving it
    if fs.exists(basaltFile) then
        local success, err = pcall(function() 
            fs.move(basaltFile, targetDir)  -- Move the file into the target directory
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
    -- Get a list of all peripheral names
    local peripheralNames = peripheral.getNames()

    -- Print all the peripheral names for debugging
    print("Peripheral names found: ")
    for _, name in ipairs(peripheralNames) do
        print(name)
    end

    -- Labels for different peripheral types
    local labels = {
        ["minecraft:chest"] = {"emerald", "cash"},  -- Label list for chests
        ["minecraft:dispenser"] = {"dispenser"}    -- Label list for dispensers
    }
    
    -- Label index for assigning labels to peripherals
    local labelIndex = {
        ["minecraft:chest"] = 1,   -- To track which label to assign to chests
        ["minecraft:dispenser"] = 1  -- To track which label to assign to dispensers
    }

    for _, name in ipairs(peripheralNames) do
        -- Get the type of each peripheral
        local peripheralType = peripheral.getType(name)

        -- Print the peripheral type for debugging
        print("Checking peripheral: " .. name .. " of type " .. peripheralType)

        -- Check if the peripheral is of type "minecraft:chest" or "minecraft:dispenser"
        if peripheralType == "minecraft:chest" or peripheralType == "minecraft:dispenser" then
            -- Get the label for the peripheral type, adjusting based on the type
            local currentLabelIndex = labelIndex[peripheralType]
            local label = labels[peripheralType][currentLabelIndex]

            -- Ensure the label exists before proceeding
            if label then
                -- Store the peripheral name, type, and label in the peripheralsTable
                table.insert(peripheralsTable, {name = name, type = peripheralType, label = label})
                print("Found " .. peripheralType .. ": " .. name .. " labeled as " .. label)

                -- Increment the label index for the next peripheral of the same type
                labelIndex[peripheralType] = currentLabelIndex + 1
            else
                print("No label available for " .. peripheralType .. ": " .. name)
            end
        end
    end
end

function savePeripheralsToFile()
    local file = fs.open("peripherals.dat", "w")  -- Open the file to write
    if file then
        file.write(textutils.serialize(peripheralsTable))  -- Serialize the table to string
        file.close()
        print("Peripherals saved to peripherals.dat")
    else
        print("Failed to save peripherals to file")
    end
end

-- Main program logic
function runInstaller()
    -- Create the /GUI/ directory if it doesn't exist
   createDirectory("/GUI/")
    -- Download the program from GitHub
    downloadFile(github_url, "startup.lua") 
    -- Install Basalt
    installBasalt()
    -- Move Basalt into /GUI/
    moveBasaltToGUI("/GUI/")
    scanPeripherals()
    savePeripheralsToFile()
    print("Installation complete.")
    print("Peripherals found:", #peripheralsTable)
end

-- Run the installer
runInstaller()
