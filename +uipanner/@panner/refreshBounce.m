function pos = refreshBounce(obj)
%REFRESHBOUNCE 此处显示有关此函数的摘要
%   此处显示详细说明
    if ishandle(obj.parent)
        posax = get(obj.parent, 'Position');
        posfg = get(obj.parent.Parent, 'Position');
        posfg = posax .* posfg;
        ofs = obj.lineWidth / posfg(3);
        
        if obj.mode == 'x'
            % ylm = ylim(obj.parent);
            ylm = [obj.minValue obj.maxValue];
            fz = @(z) (z - ylm(1)) ./ (ylm(2) - ylm(1)) .* posax(3) + posax(1);
            val = fz(obj.value);
            pos = [val(1) + ofs / 2, posax(2), val(2) - val(1) - ofs, posax(4)];
        else
            ylm = ylim(obj.parent);
            % xlm = [obj.minValue obj.maxValue];
            fz = @(z) (z - ylm(1)) ./ (ylm(2) - ylm(1)) .* posax(4) + posax(2);
            val = fz(obj.value);
            pos = [posax(1), val(1) + ofs / 2, posax(3), val(2) - val(1) - ofs];
        end
    else
        pos = [0 1 0 1];
    end
end
