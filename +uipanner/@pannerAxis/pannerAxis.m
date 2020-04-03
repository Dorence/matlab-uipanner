classdef pannerAxis < dynamicprops
    %PANNERAXIS 此处显示有关此类的摘要
    %   此处显示详细说明
    
    % lint settings
    %#ok<*MCSUP>
    properties (GetAccess = public)
        figure % axes
        panner uipanner.panner % 1st dragLine
        axisM  % main axis
        axisB  % 
        rect   % Rectangle object
        mode   % x|y
        ratio  % axisM : axisB
        style
    end
    
    properties
        xdataRange (2,1) double
        ydataRange (2,1) double
        
        step      (1,1) double
        minValue  (1,1) double
        maxValue  (1,1) double
        minLength (1,1) double % interval length
        
        lineAlpha
        lineColor
        lineVisible
        lineWidth
        
        boxAlpha
        boxColor
        boxVisible
        
    end
    
    methods
        function obj = pannerAxis(varargin)
            %PANNERAXIS 构造此类的实例
            %   此处显示详细说明
            val = uipanner.loadVarargin(struct(...
                'figure', gcf, 'mode', 'x', ...
                'minValue', -Inf, 'maxValue', +Inf, ...
                'step', 0.01, 'minLength', 0.2, ... 
                'lineAlpha', 0.6, 'lineColor', '#D95319', 'lineVisible', 'on', ...
                'boxAlpha', 0.3, 'boxColor', '#D95319', 'boxVisible', 'on', ...
                'lineWidth', 2, 'ratio', [2 1]), varargin);
            
            obj.figure = val.figure;
            obj.mode = val.mode;
            obj.ratio = val.ratio;
            
            figure(obj.figure);
            if obj.mode == 'x'
                obj.axisM = subplot(obj.ratio(1) + obj.ratio(2), 1, ...
                    1:obj.ratio(1));
                obj.axisB = subplot(obj.ratio(1) + obj.ratio(2), 1, ...
                    (1:obj.ratio(2)) + obj.ratio(1));
            else
                obj.axisM = subplot(1, obj.ratio(1) + obj.ratio(2), ...
                    1:obj.ratio(1));
                obj.axisB = subplot(1, obj.ratio(1) + obj.ratio(2), ...
                    (1:obj.ratio(2)) + obj.ratio(1));
            end
            obj.axisB.Interactions = [];
            
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
            
            obj.panner = uipanner.panner('parent', obj.axisB, 'mode', obj.mode, ...
                'step', obj.step, 'minValue', obj.minValue, 'maxValue', obj.maxValue, 'minLength', obj.minLength, ...
                'lineAlpha', obj.lineAlpha, 'lineColor', obj.lineColor, 'lineVisible', obj.lineVisible, ...
                'boxAlpha', obj.boxAlpha, 'boxColor', obj.boxColor, 'boxVisible', obj.boxVisible, ...
                'lineWidth', obj.lineWidth);
            obj.panner.bindDragging = @obj.onBannerChange;
        end
        
        function plotdata(obj, xdata, ydata)
            obj.panner.delete();
            delete(obj.panner);
            
            plot(obj.axisM, xdata, ydata);
            plot(obj.axisB, xdata, ydata);
            obj.axisB.Interactions = [];
            
            obj.panner = uipanner.panner('parent', obj.axisB, 'mode', obj.mode, ...
                'step', obj.step, 'minValue', obj.minValue, 'maxValue', obj.maxValue, 'minLength', obj.minLength, ...
                'lineAlpha', obj.lineAlpha, 'lineColor', obj.lineColor, 'lineVisible', obj.lineVisible, ...
                'boxAlpha', obj.boxAlpha, 'boxColor', obj.boxColor, 'boxVisible', obj.boxVisible, ...
                'lineWidth', obj.lineWidth);
            obj.panner.bindDragging = @obj.onBannerChange;

            [L, R] = bounds(xdata);
            obj.xdataRange = [L, R];
            
            [L, R] = bounds(ydata);
            obj.ydataRange = [L, R];
            
            % fprintf('plot range %f %f', L, R);
            obj.restore();
        end
        
        function restore(obj, range)
            if obj.mode == 'x'
                r = obj.xdataRange;
            else
                r = obj.ydataRange;
            end
            
            if nargin > 1
               r = range;
            end

            
            if obj.mode == 'x'
                xlim(obj.axisM, r);
                xlim(obj.axisB, r);
                ylim(obj.axisM, obj.ydataRange);
                ylim(obj.axisB, obj.ydataRange);
            else
                xlim(obj.axisM, obj.xdataRange);
                xlim(obj.axisB, obj.xdataRange);
                ylim(obj.axisM, r);
                ylim(obj.axisB, r);
            end
            
            set(obj.axisM, 'XLimMode', 'manual');
            set(obj.axisM, 'YLimMode', 'manual');
            set(obj.axisB, 'XLimMode', 'manual');
            set(obj.axisB, 'YLimMode', 'manual');
            disableDefaultInteractivity(obj.axisM);
            obj.panner.setValue(r);
        end
        
    end
        
    methods (Access = private) 
        function onBannerChange(obj, varargin)
            %ONBANNERCHANGE 此处显示有关此方法的摘要
            %   此处显示详细说明
            if ~isempty(obj.panner)
                if obj.mode == 'x'
                    xlim(obj.axisM, obj.panner.value);
                else
                    ylim(obj.axisM, obj.panner.value);
                end
            end
        end
    end
end

