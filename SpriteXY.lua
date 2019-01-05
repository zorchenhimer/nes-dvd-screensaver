function drawXY()
  SpriteX = emu.read(emu.getLabelAddress("SpriteX"), emu.memType.cpuDebug)
  SpriteY = emu.read(emu.getLabelAddress("SpriteY"), emu.memType.cpuDebug)
  
  emu.drawString(12, 12, string.format("(%03d, %03d)", SpriteX, SpriteY), 0xFFFFFF, 0xFF000000, 1)
  --emu.drawString(12, 12, string.format("(%03d, %03d)"), 0xFFFFFF, 0xFF000000, 1)
  emu.drawPixel(SpriteX, SpriteY, 0xFF0000, 1, 0)
  
  PalIdx = emu.read(emu.getLabelAddress("PaletteIndex"), emu.memType.cpuDebug)
  emu.drawString(12, 24, string.format("%02d", PalIdx), 0xFFFFFF, 0xFF000000, 1)
end

emu.addEventCallback(drawXY, emu.eventType.endFrame)