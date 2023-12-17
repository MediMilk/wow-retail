--
-- Copyright (c) 2023 by Ludicrous Speed, LLC
-- All rights reserved.
--
local provider={name=...,data=3,region="tw",date="2023-12-12T09:27:50Z",numCharacters=30769,lookup={},recordSizeInBytes=2,encodingOrder={0,1,3}}
local F

-- chunk size: 38
F = function() provider.lookup[1] = ";\4?\29?\29?\29?\29?\29?\29?\29?\29?\29;\4?\29?\29?\29?\29?\29?\29?\29;\4" end F()

F = nil
RaiderIO.AddProvider(provider)
