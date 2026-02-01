--[[
    BSS Monitor - Bridge Module Configuration Example
    
    This file shows how to configure the bridge module for mobile automation.
    Copy the configuration to your config.lua file.
]]

-- Example configuration for bridge module:
--[[

-- =============================================
-- BRIDGE SETTINGS (Mobile Automation Bridge)
-- =============================================
Config.BRIDGE_ENABLED = true        -- Enable bridge for mobile automation
Config.BRIDGE_URL = "https://your-app.vercel.app"  -- Your Vercel deployment URL
Config.BRIDGE_API_KEY = "your-secret-key-here"     -- Your API key (32+ characters)
Config.BRIDGE_TIMEOUT = 5           -- Request timeout in seconds

]]

-- How to use:
-- 1. Deploy the bridge server to Vercel (see bss-bridge-server/README.md)
-- 2. Set up the Android automation app (see bss-automation-app/README.md)
-- 3. Update Config.BRIDGE_URL with your Vercel deployment URL
-- 4. Generate a secure API key and set Config.BRIDGE_API_KEY
-- 5. Set Config.BRIDGE_ENABLED = true
-- 6. The bridge module will automatically be used on mobile devices

-- Note: The bridge module will be created in task 5 of the implementation plan
