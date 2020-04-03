classdef dragLine < matlab.mixin.SetGet
    %DRAGLINE Draggable constant line
    %   create a ConstantLine object with drag event
    
    % lint settings
    %#ok<*MCSUP>
    
    properties (GetAccess = public, SetAccess = immutable)
        parent % axes
        line   % ConstantLine object
        mode   % 'x' or 'y'
    end
    
    properties
        minValue (1,1) double
        maxValue (1,1) double
        value    (1,1) double % current x/y data
        step     (1,1) double % value step
        
        lineAlpha
        lineColor
        lineVisible
        lineWidth
        
        bindDragStart % eventDragStart
        bindDragging  % eventDraging
        bindDragEnd   % eventDragEnd
    end

    properties (Access = private, Hidden = true)
        dragPointer
        oriDragPointer
        saveWindowFcn
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
        function obj = dragLine(varargin)
            %DRAGLINE
            val = uipanner.loadVarargin(struct(...
                'parent', gca, 'mode', 'x', ...
                'minValue', -Inf, 'maxValue', Inf, 'value', NaN, 'step', 0.1, ...
                'lineAlpha', 0.6, 'lineColor', '#D95319', 'lineVisible', 'on', ...
                'lineWidth', 2), varargin);
            
            obj.parent = val.parent;
            
            obj.lineAlpha = val.lineAlpha;
            obj.lineColor = val.lineColor;
            obj.lineVisible = val.lineVisible;
            obj.lineWidth = val.lineWidth;
            
            obj.minValue = val.minValue;
            obj.maxValue = val.maxValue;
            obj.step = val.step;
            obj.mode = lower(val.mode);
            obj.setLim();
            
            if obj.mode == 'x'
                set(obj.parent, 'XLimMode', 'manual');
            else
                set(obj.parent, 'YLimMode', 'manual');
            end
            
            if isnan(val.value)
                obj.value = (obj.minValue + obj.maxValue) / 2;
            else
                obj.value = val.value;
            end
                    
            if obj.mode == 'x'
                obj.line = xline(obj.parent, obj.value, '-', num2str(obj.value), ...
                    'LineWidth', obj.lineWidth, 'Color', obj.lineColor, ...
                    'Alpha', obj.lineAlpha, 'Visible', obj.lineVisible, ...
                    'LabelHorizontalAlignment', 'center');
                obj.dragPointer = 'left'; % pointer when dragging
            else
                obj.line = yline(obj.parent, obj.value, '-', num2str(obj.value), ...
                    'LineWidth', obj.lineWidth, 'Color', obj.lineColor, ...
                    'Alpha', obj.lineAlpha, 'Visible', obj.lineVisible, ...
                    'LabelVerticalAlignment', 'middle');
                obj.dragPointer = 'top'; % pointer when dragging
            end
            
            set(obj.line, 'ButtonDownFcn', @obj.onDragStart);
            
            % axis limit change
            if obj.mode == 'x'
                obj.lstResize = addlistener(obj.parent, 'XLim', 'PostSet', @obj.setLim);
            else
                obj.lstResize = addlistener(obj.parent, 'YLim', 'PostSet', @obj.setLim);
            end
        end
        
        function v = get.minValue(obj)
            %MINVALUE
            L = obj.getLim();
            v = max(obj.minValue, L(1));
        end
        
        function v = get.maxValue(obj)
            %MAXVALUE
            L = obj.getLim();
            v = min(obj.maxValue, L(2));
        end
        
        function set.value(obj, v)
            if ishandle(obj.parent)
                posax = get(obj.parent, 'Position');
                posfg = get(obj.parent.Parent, 'Position');
                pos = posax .* posfg;
                if obj.mode == 'x'
                    pos = pos(3); % width
                else
                    pos = pos(4); % height
                end
                ofs = obj.lineWidth * (obj.maxValue - obj.minValue) / pos / 2;
            else
                ofs = 0;
            end
            
            if v <= obj.minValue + ofs
                obj.value = obj.minValue;
            elseif v >= obj.maxValue - ofs
                obj.value = obj.maxValue;
            else
                if ~isnan(obj.step)
                    v = round(v / obj.step) * obj.step;
                end
                obj.value = v;
            end
        
            if ishandle(obj.line)
                set(obj.line, 'value', obj.value);
                set(obj.line, 'label', num2str(obj.value));
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
            if isempty(obj.parent) || ~ishandle(obj.parent)
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
        
        % update line style
        function set.lineAlpha(obj, v)
            obj.lineAlpha = v;
            if ishandle(obj.line)
                set(obj.line, 'Alpha', v);
            end
        end
        
        function set.lineColor(obj, v)
            obj.lineColor = v;
            if ishandle(obj.line)
                set(obj.line, 'Color', v);
            end
        end
        
        function set.lineVisible(obj, v)
            obj.lineVisible = v;
            if ishandle(obj.line)
                set(obj.line, 'Visible', v);
            end
        end
        
        function set.lineWidth(obj, v)
            obj.lineWidth = v;
            if ishandle(obj.line)
                set(obj.line, 'lineWidth', v);
            end
        end
        
        function delete(obj)
            %DELETE
            delete(obj.line);
            delete(obj.lstDragStart);
            delete(obj.lstDragging);
            delete(obj.lstDragEnd);
            delete(obj.lstResize);
        end
    end
    
    methods (Access = private)
        % drag events
        function onDragStart(obj, varargin)
            % save pointer and windowfcn
            fig = obj.parent.Parent; % Figure, Panel or Tab
            
            obj.oriDragPointer = get(fig, 'pointer'); % 'arrow'
            set(fig, 'pointer', obj.dragPointer);
            
            obj.saveWindowFcn.Motion = get(fig, 'WindowButtonMotionFcn');
            obj.saveWindowFcn.Up     = get(fig, 'WindowButtonUpFcn');
            set(fig, 'WindowButtonMotionFcn', @obj.onDragging);
            set(fig, 'WindowButtonUpFcn',     @obj.onDragEnd);

            notify(obj, 'eventDragStart'); % notify for bindDragStart
        end
        
        function onDragging(obj, varargin)
            pos = get(obj.parent, 'CurrentPoint');
            if obj.mode == 'x'
                obj.value = pos(1, 1);
            else
                obj.value = pos(1, 2);
            end
            notify(obj, 'eventDragging');
        end
        
        function onDragEnd(obj, varargin)
            fig = obj.parent.Parent;
            set(fig, 'pointer', obj.oriDragPointer);
            set(fig, 'WindowButtonMotionFcn', obj.saveWindowFcn.Motion);
            set(fig, 'WindowButtonUpFcn', obj.saveWindowFcn.Up);
            notify(obj, 'eventDragEnd');
        end
    end
end
