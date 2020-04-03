% Author: Dorence DENG
% a demo for uipanner
% pannerAxis <- panner <- dragLine
% inspired by chen xinfeng's 'drag Line with callback'
fg = figure();
pa = uipanner.pannerAxis('mode', 'x', 'figure', fg);
pa.step = 100;
x = 1:10000;
pa.plotdata(x, sin(x ./ 500 .* pi) ./ x .^ 0.2);
