classdef MockWin
    properties
        WinHandle
        InterFrameInterval
        ScreenRes
        WinCentre
        Buttons
        MouseX
        MouseY
        ClickCoords
        CurrentCoord
        CurrentTrial
    end
    
    properties (SetAccess = private, GetAccess = private)
        OldVisualDebugLevel
        OldSupressAllWarnings
    end
    
    methods
        function obj = MockWin()
            res.width = 1280;
            res.height = 800;
            res.pixelSize = 32;
            res.hz = 59;
            obj.WinHandle = 10;
            obj.InterFrameInterval = 0.0166815950541059;
            obj.ScreenRes = res;
            obj.WinCentre.x = round(res.width/2);
            obj.WinCentre.y = round(res.height/2);
        end
        
        function FillRect(obj, col, pad)
        end
        
        function DrawDots(obj, pos, width, colour)
        end
        
        function DrawRect(obj, frame, colour, ~)
        end
        
        function DrawFixation(obj, ~, ~)
        end
            
        function DisplayDots(obj, offsetPositions, dotWidth, color)
        end

        function DisplayFixation(obj, fixColor, fixPos)
        end
    
        function vbl = Flip(obj, vblOld)
            if nargin == 1
                vblOld = GetSecs;
            end
            vbl = vblOld + 0.0167;
        end    
        
        function obj = SetMouse(obj)
            obj.CurrentCoord = 1;
            obj.Buttons(1:8) = 0;
        end
        
        function [x,y,buttons,obj] = GetMouse(obj)
            x = 100;
            y = 100;
            
            if any(obj.Buttons)
                obj.Buttons(1:8) = 0;
                buttons(1:8) = 0;
                return;
            else
                buttons = obj.Buttons;
            end
            if ~isempty(obj.ClickCoords)
                x = obj.ClickCoords(obj.CurrentTrial, 1, obj.CurrentCoord);
                y = obj.ClickCoords(obj.CurrentTrial, 2, obj.CurrentCoord);
                obj.CurrentCoord = obj.CurrentCoord + 1;
                if obj.CurrentCoord > 4
                    obj.CurrentTrial = obj.CurrentTrial + 1;
                end
                obj.Buttons(1) = 1;
                buttons(1) = 1;
            end
        end
        
        function DisplayMessage(obj, message, colour, wrapat)
            %disp(message);
        end
        
        % Draw the specified message to the buffer, flip, and wait for a key press
        % colour & wrapat are optional
        function DisplayMessageAndWait(obj, message, colour, wrapat)
            %disp(message);
        end
        
        function DisplayMessageAndWaitForKey(obj, message, key, colour, wrapat)
        end
            
        function textures = MakeTexturesFromFiles(obj, path, filenames)
            for i = 1:length(filenames)
                textures(i) = MakeTextureFromFile(obj, [path filenames{i}]);
            end
        end
        
        function texture = MakeTextureFromFile(obj, filename)
            texture = randi(100);
        end
        
        function delete(obj)
        end
    end % methods
end % classdef
