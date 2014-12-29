-- Copyright (C) 2014 &yet LLC and otalk contributors
-- This file is MIT/X11 licensed. 
-- this creates some pubsub nodes and configures publishers on them
local config = require "core.configmanager";
local st = require "util.stanza";
local modulemanager = require "modulemanager";
local pubsub = modulemanager.get_module(module:get_host(), "pubsub")
local service = hosts[module.host].modules.pubsub.service
local nodes = module:get_option("pubsub_preload") or {};

local xmlns_colibri = "http://jitsi.org/protocol/colibri";
--[[
Component "your.pubsub.serivce " "pubsub"
    modules_enabled = { "pubsub_preload" }
    pubsub_preload = {
        -- list of nodes and publishers
        videobridge = { "list", "of", "publishers" }
    }
]]

module:hook_object_event(service.events, "item-published", function (event) 
    local node, item = event.node, event.item

    if not nodes[node] then return; end

    for stats in item:childtags("stats", xmlns_colibri) do
        local statstable = {}
        for stat in stats:childtags("stat", xmlns_colibri) do
            statstable[stat.attr.name] = stat.attr.value
        end
        --module:log("debug", "%s stats: %s", event.actor, serialization.serialize(statstable))

        module:fire_event("colibri-stats", { stats = statstable, bridge = event.actor })
    end
end)

local function preload() 
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
