classdef panner < matlab.mixin.SetGet
    %PANNER 此处显示有关此类的摘要
    %   此处显示详细说明
    
    % lint settings
    %#ok<*MCSUP>
    properties (GetAccess = public, SetAccess = immutable)
        parent % axes
        dlineA uipanner.dragLine % 1st dragLine
        dlineB uipanner.dragLine % 2nd dragLine
        rect   % Rectangle object
        mode   % x|y
    end
    
    properties
        minValue  (1,1) double
        maxValue  (1,1) double
        value     (2,1) double % current x/y data
        step      (1,1) double % value step
        minLength (1,1) double % interval length
        
        lineAlpha
        lineColor
        lineVisible
        lineWidth
        
        boxAlpha
        boxColor
        boxVisible % off|on
        
        visible    % off|on
        
        bindDragStart % eventDragStart
        bindDragging  % eventDraging
        bindDragEnd   % eventDragEnd
    end
    
    properties (Access = private, Hidden = true)
        isDragging (1,1) logical
        dragPointer
        oriDragPointer
        dragStartPos
        dragPrevDist
        saveWindowFcn
        lastOpLine = 1 % 1: dlineA, 2: dlineB
        lstDragStart % eventDragStart
        lstDragging  % eventDraging
        lstDragEnd   % eventDragEnd
        lstResize
    end
    
    events
        eventDragStart
        eventDragging
        eventDragEnd
    end
    
    methods
        function obj = panner(varargin)
            %PANNER 构造此类的实例
            %   此处显示详细说明
            val = uipanner.loadVarargin(struct(...
                'mode', 'x', 'parent', gca, ...
                'minValue', -Inf, 'maxValue', +Inf, 'value', [NaN NaN], ...
                'step', 0.01, 'minLength', 0.2, ... 
                'lineAlpha', 0.6, 'lineColor', '#D95319', 'lineVisible', 'on', ...
                'boxAlpha', 0.3, 'boxColor', '#D95319', 'boxVisible', 'on', ...
                'lineWidth', 2), varargin);
            
            obj.parent = val.parent;
            
            obj.lineAlpha   = val.lineAlpha;
            obj.lineColor   = val.lineColor;
            obj.lineVisible = val.lineVisible;
            obj.lineWidth   = val.lineWidth;
            obj.boxAlpha    = val.boxAlpha;
            obj.boxColor    = val.boxColor;
            obj.boxVisible  = val.boxVisible;
            
            obj.minValue = val.minValue;
            obj.maxValue = val.maxValue;
            obj.step = val.step;
            obj.minLength = val.minLength;

            obj.mode = lower(val.mode);
            set(obj.parent, 'XLimMode', 'manual');
            set(obj.parent, 'YLimMode', 'manual');
            obj.setLim();
            
            for i=1:2
                if isnan(val.value(i))
                    m = (obj.minValue + obj.maxValue) / 2;
                    obj.value(i) = m + (i - 1.5) * obj.minLength;
                    if ~isnan(obj.step)
                        obj.value = round(obj.value ./ obj.step) .* obj.step;
                    end
                else
                    obj.value(i) = val.value(i);
                end
            end
            obj.adjustValue();
            
            pos = obj.refreshBounce();
            obj.rect = annotation(obj.parent.Parent, 'rectangle', 'Position', pos, ...
                'FaceAlpha', obj.boxAlpha, 'FaceColor', obj.boxColor, ...
                'Visible', obj.boxVisible, 'LineStyle', 'none');
            obj.dragPointer = 'fleur';
            
            obj.dlineA = uipanner.dragLine('parent', obj.parent, 'mode', obj.mode, ...
                'value', obj.value(1), 'step', obj.step, ...
                'minValue', obj.minValue, 'maxValue', obj.maxValue, ...
                'lineAlpha', obj.lineAlpha, 'lineColor', obj.lineColor, ...
                'lineVisible', obj.lineVisible, 'lineWidth', obj.lineWidth);
            obj.dlineB = uipanner.dragLine('parent', obj.parent, 'mode', obj.mode, ...
                'value', obj.value(2), 'step', obj.step, ...
                'minValue', obj.minValue, 'maxValue', obj.maxValue, ...
                'lineAlpha', obj.lineAlpha, 'lineColor', obj.lineColor, ...
                'lineVisible', obj.lineVisible, 'lineWidth', obj.lineWidth);
            
            obj.lstResize = listener(obj.parent, 'Position', 'PostSet', @obj.setRect);
            set(obj.parent.Parent, 'SizeChangedFcn', @(hd, varargin)(obj.setRect()));
            
            set([obj.dlineA, obj.dlineB], 'bindDragStart', @obj.onLineDragStart);
            set([obj.dlineA, obj.dlineB], 'bindDragging', @obj.onLineDragging);
            set([obj.dlineA, obj.dlineB], 'bindDragEnd', @obj.onLineDragEnd);
            set(obj.rect, 'ButtonDownFcn', @obj.onRectDragStart);
        end
        
        function v = get.minValue(obj)
            %MINVALUE 此处显示有关此方法的摘要
            %   此处显示详细说明
            L = obj.getLim();
            v = max(obj.minValue, L(1));
            % fprintf('get.minValue[%f] ', v);
        end
        
        function v = get.maxValue(obj)
            %MAXVALUE 此处显示有关此方法的摘要
            %   此处显示详细说明
            L = obj.getLim();
            v = min(obj.maxValue, L(2));
            % fprintf('get.maxValue[%f] ', v);
        end
        
        adjustValue(obj)
        pos = refreshBounce(obj)
        transPanner(obj, v)
        
        function setRect(obj)
            if ishandle(obj.rect)
                set(obj.rect, 'Position', obj.refreshBounce());
            end
        end
        
        function setValue(obj, v)
            obj.value = v;
            obj.minValue = min(obj.minValue, obj.value(1));
            obj.maxValue = max(obj.maxValue, obj.value(2));
            
            obj.adjustValue();
            if ishandle(obj.parent)
                obj.setRect();
                obj.dlineA.value = obj.value(1);
                obj.dlineB.value = obj.value(2);
            end
        end
        
        function setLim(obj, varargin)
            L = obj.getLim();
            % fprintf('call setLim [%f,%f]\n', L(1), L(2));
            if obj.value < obj.minValue
                obj.value = obj.minValue;
            end
            if obj.value > obj.maxValue
                obj.value = obj.maxValue;
            end
        end
        
        function L = getLim(obj)
            if ~ishandle(obj.parent)
                L = [-Inf Inf];
                return;
            end
            if obj.mode == 'x'
                L = xlim(obj.parent);
            else
                L = ylim(obj.parent);
            end
        end
        
        % bind callback fcn
        function set.bindDragStart(obj, hfcn)
           delete(obj.lstDragStart);
           if isempty(hfcn)
                obj.bindDragStart = [];
           else
                obj.bindDragStart = hfcn;
                obj.lstDragStart = addlistener(obj, 'eventDragStart', hfcn);
           end
        end
        
        function set.bindDragging(obj, hfcn)
           delete(obj.lstDragging);
           if isempty(hfcn)
                obj.bindDragging = [];
           else
                obj.bindDragging = hfcn;
                obj.lstDragging = addlistener(obj, 'eventDragging', hfcn);
           end
        end
        
        function set.bindDragEnd(obj, hfcn)
           delete(obj.lstDragEnd);
           if isempty(hfcn)
                obj.bindDragEnd = [];
           else
                obj.bindDragEnd = hfcn;
                obj.lstDragEnd = addlistener(obj, 'eventDragging', hfcn);
           end
        end
        
        function delete(obj)
            %DELETE
            delete(obj.dlineA);
            delete(obj.dlineB);
            delete(obj.rect);
            delete(obj.lstResize);
            delete(obj.lstDragStart);
            delete(obj.lstDragging);
            delete(obj.lstDragEnd);
        end
    end
    
    methods (Access = private)
        % drag events
        function onLineDragStart(obj, varargin)
            if ~isnan(obj.minLength)
                obj.dlineA.maxValue = max(obj.dlineB.value - obj.minLength, obj.minValue);
                obj.dlineB.minValue = min(obj.dlineA.value + obj.minLength, obj.maxValue);
            end
            notify(obj, 'eventDragStart');
        end
        
        function onLineDragging(obj, varargin)
            val = [obj.dlineA.value, obj.dlineB.value];
            if val(1) > val(2)
               val = val([2 1]); 
            end
            if ~all(obj.value == val)
                obj.value = val;
                obj.setRect();
            end
            notify(obj, 'eventDragging');
        end
        
        function onLineDragEnd(obj, varargin)
            notify(obj, 'eventDragEnd');
        end
        
        function onRectDragStart(obj, varargin)
            if obj.isDragging
               obj.onRectDragEnd(); 
            end
            
            % 更改箭头，保存windowfcn
            fig = obj.parent.Parent; % Figure, Panel or Tab
            
            obj.oriDragPointer = get(fig, 'pointer'); % 'arrow'
            set(fig, 'pointer', obj.dragPointer);
            
            obj.saveWindowFcn.Motion = get(fig, 'WindowButtonMotionFcn');
            obj.saveWindowFcn.Up     = get(fig, 'WindowButtonUpFcn');
            set(fig, 'WindowButtonMotionFcn', @obj.onRectDragging);
            set(fig, 'WindowButtonUpFcn',     @obj.onRectDragEnd);
            
            pos = get(obj.parent, 'CurrentPoint');
            if obj.mode == 'x'
                obj.dragStartPos = pos(1, 1);
            else
                obj.dragStartPos = pos(1, 2);
            end
            obj.dragPrevDist = 0;
            obj.isDragging = true;

            notify(obj, 'eventDragStart'); % notify for bindDragStart
        end
        
        function onRectDragging(obj, varargin)
            pos = get(obj.parent, 'CurrentPoint');
            if obj.mode == 'x'
                pos = pos(1, 1);
            else
                pos = pos(1, 2);
            end
            v = pos - obj.dragStartPos;
            if ~isnan(obj.step)
                v = round(v / obj.step) * obj.step;
            end
            d = v - obj.dragPrevDist;
            % fprintf('%6f %6f[%6f]\n', pos, v, d);
            if d
                obj.dragPrevDist = v;
                obj.transPanner(d);
            end
            
            notify(obj, 'eventDragging');
        end
        
        function onRectDragEnd(obj, varargin)
            fig = obj.parent.Parent;
            set(fig, 'pointer', obj.oriDragPointer);
            set(fig, 'WindowButtonMotionFcn', obj.saveWindowFcn.Motion);
            set(fig, 'WindowButtonUpFcn', obj.saveWindowFcn.Up);
            obj.isDragging = false;
            notify(obj, 'eventDragEnd');
        end
    end
end

