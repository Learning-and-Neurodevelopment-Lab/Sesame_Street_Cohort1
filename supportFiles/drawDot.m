function drawDot(window,W,H,clr)
barLength = 16; % in pixels
barWidth = 2; % in pixels
barColor = clr; % number from 0 (black) to 1 (white)
Screen('FillOval', window, barColor ,[ (W-barWidth)/2 (H-barLength)/2 (W+barWidth)/2 (H+barLength)/2]);
end