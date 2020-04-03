function adjustValue(obj)
%ADJUSTVALUE 此处显示有关此函数的摘要
%   此处显示详细说明
    if obj.value(1) > obj.value(2)
        obj.value = obj.value([2 1]);
    end

    if obj.value(1) < obj.minValue
        obj.value(1) = obj.minValue;
        obj.lastOpLine = 1;
    end
    if obj.value(2) > obj.maxValue
       obj.value(2) = obj.maxValue;
       obj.lastOpLine = 2;
    end

    if obj.value(2) - obj.value(1) < obj.minLength
        if obj.lastOpLine == 1
            v = obj.value(1) + obj.minLength;
            if ~isnan(obj.step)
                v = ceil(v / obj.step) * obj.step;
            end
            obj.value(2) = v;
        else
            v = obj.value(2) - obj.minLength;
            if ~isnan(obj.step)
                v = floor(v / obj.step) * obj.step;
            end
            obj.value(1) = v;
        end
    end
end
