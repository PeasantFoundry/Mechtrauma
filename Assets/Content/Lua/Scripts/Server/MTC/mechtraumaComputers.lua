

-- table of item tags that will be discovered by item diagnosticTags
MT.C.diagnosticTags = { -- may want to move this to a part fault tag table? or have both? jesus
  blocked = {
    tag = "blocked",
    description = " appears to be blocked.",
    fixable = true,
    fixSkill = "mechanical",
    requiredSkill = 30
  },
  blown = {
    tag = "blown",
    description = " appears to be blown.",
    fixable = false,
    fixSkill = "mechanical",
    requiredSkill = 30
  },
  contaminated = {
    tag = "contaminants",
    description = " appears to be contaminated.",
    fixable = true,
    fixSkill = "mechanical",
    requiredSkill = 30
  },
  cracked = {
    tag = "cracked",
    description = " appears to be cracked.",
    fixable = true,
    fixSkill = "mechanical",
    requiredSkill = 30
  },
  warped = {
    tag = "wapred",
    description = " appears to be warped.",
    fixable = false,
    fixSkill = "mechanical",
    requiredSkill = 30
  },
  water = {
    tag = "water",
    description = " appears to have water in it.",
    fixable = true,
    fixSkill = "mechanical",
    requiredSkill = 30
  }

}

MT.C.Sample = {
  messages={
    type="DIR",
    name="messages",
    sent={
      type="DIR",
      name="sent",
    },
    received={
      type="DIR",
      name="received",
    },
    messages={
      type = "EXE",
      name = "messager",
      functionToCall = "MT.CLI.textcolor"
    },
  }
}
-- this function will need to be refactored to generate randomized contents for each MTC (based on item)
function MT.C.buildMTC(item, rebuild)
  if not rebuild then rebuild = false end -- default to build not rebuild
  if MT.C.HD[item] and not rebuild then return MT.C.HD[item].MTC end -- if there is already a DB, return
  if MT.C.HD[item] and rebuild then MT.C.HD[item] = nil end -- if there is already a DB and we are rebuilding, delete it

  --buildMTC
  local MTC={
    root={
      mtos={
        type="DIR",
        name="MTOS",
        kernel={
          type="SYS",
          name="kernel",
          ver="1.0"
        }
      },
      messages={
        type="DIR",
        name="messages",
        sent={
          type="DIR",
          name="sent",
        },
        received={
          type="DIR",
          name="received",
        },
        msger={
          type="EXE",
          name="msger",
          functionToCall = "MT.CLI.textcolor"
        },
      },
      user={
        type="DIR",
        name="user",
        pbank={
          type="EXE",
          name="pbank",
          functionToCall = "MT.C.pBankWelcome",
        },
      },
      programs={
        type="DIR",
        name="programs",
        textcolor={
          type="EXE",
          name="textcolor",
          functionToCall = "MT.CLI.textcolor",
        },
        register={
          type="EXE",
          name="register",
          functionToCall = "MT.CLI.register"
        },
        notes={
          type="DIR",
          name="notes",
        },
      dangerous={
        type="DIR",
        name="dangerous",
      }
    }
  },
  counters={
    smsIN=0,
    smsOUT=0
  }
}
-- install MTOS dependencies and calculate registration keys
  for command, v in pairs(MT.CLI.commands) do
    -- probably need to check if command is allowed on device?

    -- if the command requires a SYS dependency and it's not installed, install it
    if v.requireSYS and not MTC.root.mtos[v.requireSYS] then
      MTC.root.mtos[v.requireSYS]={type="SYS",name=v.requireSYS,key=MT.CLI.encode(string.lower(v.requireSYS) .. tostring(item.ID))}
    end
  end
  return MTC
end

-- function to test an item contained in a mechtrauma tablet
function MT.C.tabletDiagnoseItem(item, targetItem, terminal)
  local terminal = MTUtils.GetComponentByName(item, "Mechtrauma.AdvancedTerminal")
  local dataBox = MTUtils.GetComponentByName(item, "Mechtrauma.DataBox")
  local thermal = MTUtils.GetComponentByName(item, "Mechtrauma.Thermal")

  terminal.TextColor = Color.Gray
  MT.HF.BlankTerminalLines(terminal, 10)
  terminal.SendMessage("PROCESSING REQUEST...", Color.Gray)
  MT.HF.BlankTerminalLines(terminal, 1)
  terminal.TextColor = Color(250,100,60,255)
  --Timer.Wait(MT.HF.BlankTerminalLines(terminal, 1),1000)
  --Timer.Wait(MT.HF.BlankTerminalLines(terminal, 1),1000)
  --Timer.Wait(MT.HF.BlankTerminalLines(terminal, 1),1000)

  -- check for an item to diagnose
  if targetItem ~= nil then
    local tagTable = MT.HF.Split(string.lower(targetItem.Tags),",")
    local diagnosticTags = false

   --terminal.TextColor = Color(250,100,60,255)
    terminal.SendMessage("*****DIAGNOSTIC RESULT*****")
      if targetItem.ConditionPercentage < 1 then terminal.SendMessage(targetItem.name .. " is not functional.") end

      -- diagnostic tags
      --terminal.TextColor = Color(250,100,60,255)
      for k, tag in pairs(tagTable) do
        if MT.C.diagnosticTags[tag] then
          diagnosticTags = true
          terminal.SendMessage(targetItem.name .. MT.C.diagnosticTags[tag].description, Color(250,100,60,255))
        end
      end
      if not diagnosticTags and targetItem.ConditionPercentage > 1 then terminal.SendMessage(targetItem.name .. " appears to be functional.") end
      terminal.SendMessage("**********END REPORT**********")
  else
    -- nothing to diagnose
    terminal.TextColor = Color(250,100,60,255)
    terminal.SendMessage("******DIAGNOSTICS RESULT******")
    terminal.SendMessage("!THERE IS NOTHING TO DIAGNOSE!")
    terminal.SendMessage("**********END REPORT**********")
  end
end

-- ----- REPORT PARTS -----
Hook.Add("maintenanceTablet_rparts.OnUse", "MT.partsInventoryReport", function(effect, deltaTime, item, targets, worldPosition, client)
  MT.F.reportTypes.parts(item)
end)

-- -------------------------------------------------------------------------- --
--                                MTC PROGRAMS                                --
-- -------------------------------------------------------------------------- --



-- -------------------------------------------------------------------------- --
--                              HELPER FUNCTIONS                              --
-- -------------------------------------------------------------------------- --
