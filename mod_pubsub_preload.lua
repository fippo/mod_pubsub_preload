-- Copyright (C) 2014 &yet LLC and otalk contributors
-- This file is MIT/X11 licensed. 
-- this creates some pubsub nodes and configures publishers on them
local config = require "core.configmanager";
local st = require "util.stanza";
local modulemanager = require "modulemanager";
local pubsub = modulemanager.get_module(module:get_host(), "pubsub")

--[[
Component "your.pubsub.serivce " "pubsub"
    modules_enabled = { "pubsub_preload" }
    pubsub_preload = {
        -- list of nodes and publishers
        videobridge = { "list", "of", "publishers" }
    }
]]

local function preload() 
    local nodes = module:get_option("pubsub_preload") or {};
    for nodename, affiliations in pairs(nodes) do
        local ok, err = pubsub.service:create(nodename, true);
        -- ignore return value
        for i, publisher in ipairs(affiliations) do
            ok, err = pubsub.service:set_affiliation(nodename, true, publisher, "publisher")
            module:log("info", "mod_pubsub_preload set affil %s %s", tostring(ok), tostring(err))
        end
    end
end

module:add_timer(1, preload)
log("info", "mod_pubsub_preload loaded")

-- FIXME: server-started does not seem to be hook-able from a component?
