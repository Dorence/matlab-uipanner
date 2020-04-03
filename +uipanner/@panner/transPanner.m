function transPanner(obj, v)
%TRANSPANNER 此处显示有关此函数的摘要
%   此处显示详细说明
    obj.value = obj.value + v;
    obj.dlineA.maxValue = max(obj.minValue + obj.minLength, ...
        min(obj.dlineA.maxValue + v, obj.value(2) - obj.minLength));
    obj.dlineB.minValue = min(obj.maxValue - obj.minLength, ...
        max(obj.dlineB.minValue + v, obj.value(1) + obj.minLength));
    if obj.value(2) > obj.dlineB.maxValue
       obj.dlineB.maxValue = obj.maxValue; 
    end
    obj.adjustValue();
    
    obj.dlineA.value = obj.value(1);
    obj.dlineB.value = obj.value(2);
    obj.setRect();
end

