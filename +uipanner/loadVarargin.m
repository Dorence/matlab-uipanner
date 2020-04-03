function val = loadVarargin(val, varargin)
%LOADVARARGIN �˴���ʾ�йش˺�����ժҪ
%   �˴���ʾ��ϸ˵��
    if isempty(varargin{1})
       return;
    end
    
    arg = varargin{1};
    for i = 1 : 2 : length(arg)
        if ischar(arg{i})
            if isfield(val, arg{i})
                val.(arg{i}) = arg{i + 1};
            else
                throw(MException('musicGenerator:loadVarargin:unknownField', ...
                'Unknown field %s', arg{i}));
            end
        else
            throw(MException('musicGenerator:loadVarargin:unknownInput', ...
                'Unknown input'));
        end
    end
end

