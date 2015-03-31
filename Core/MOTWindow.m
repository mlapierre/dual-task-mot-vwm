classdef MOTWindow
    properties
        WinHandle
        InterFrameInterval
        ScreenRes
        WinCentre
        BackgroundColour = [125 125 125];
    end
    
    properties (SetAccess = private, GetAccess = private)
        OldVisualDebugLevel
        OldSupressAllWarnings
    end
    
    methods
        function obj = MOTWindow()
            % Force java garbage collection because something is causing the java heap
            % to overflow TODO need to find out where the leak is. Possibly
            % only occurs when the program is terminated prematurely,
            % however it may help to clear the heap at the start
            java.lang.Runtime.getRuntime.gc;
            
            %obj.OldVisualDebugLevel = Screen('Preference', 'VisualDebugLevel', 4);
            %obj.OldSupressAllWarnings = Screen('Preference', 'SuppressAllWarnings', 0);
            %Screen('Preference','Verbosity',4); 
            obj.OldVisualDebugLevel = Screen('Preference', 'VisualDebugLevel', 1);
            obj.OldSupressAllWarnings = Screen('Preference', 'SuppressAllWarnings', 0);
            Screen('Preference','Verbosity',1); 
            FlushEvents; HideCursor; ListenChar(2); 
            
            % Open the screen window and places it on the secondary monitor,
            % if there is one, else use the main monitor
            ScreenVector = Screen('Screens');
            ScreenNumber = max(ScreenVector);
            obj.WinHandle = Screen('OpenWindow', ScreenNumber, obj.BackgroundColour);
            Screen('BlendFunction', obj.WinHandle, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            AssertOpenGL;
            
            % Initialize text parameters
            Screen('TextSize', obj.WinHandle, 24); 
            Screen('TextFont', obj.WinHandle,'Courier');

            % Get actual refresh interval
            obj.InterFrameInterval = Screen('GetFlipInterval', obj.WinHandle);

            obj.ScreenRes = Screen('Resolution', ScreenNumber);
            obj.WinCentre.x = round(obj.ScreenRes.width/2);
            obj.WinCentre.y = round(obj.ScreenRes.height/2);
        end
        
        function FrameOval(obj, colour, rect)
            Screen('FrameOval', obj.WinHandle, colour, rect, 3, 3); 
        end
        

        function DrawCubes(obj, cubes, cube_colours)
            for i = 1:size(cubes,2)
                obj.DrawCube(cubes(1,i), cubes(2,i), cubes(3,i), cube_colours(:,:,i));
            end
        end
        
        function DrawCube(obj, cx, cy, orientation, colours)
            if orientation == 1
                vertices(:,:,1) = [cx cy-50; cx+50 cy-25; cx cy; cx-50 cy-25];
                vertices(:,:,2) = [cx cy; cx+50 cy-25; cx+50 cy+25; cx cy+50];
                vertices(:,:,3) = [cx cy; cx cy+50; cx-50 cy+25; cx-50 cy-25];
            else
                vertices(:,:,1) = [cx cy+50; cx+50 cy+25; cx cy; cx-50 cy+25];
                vertices(:,:,2) = [cx cy; cx+50 cy+25; cx+50 cy-25; cx cy-50];
                vertices(:,:,3) = [cx cy; cx cy-50; cx-50 cy-25; cx-50 cy+25];
            end
            obj.FillPoly(vertices, colours);
        end
        
        function FillPoly(obj, vertices, colours)
            isConvex = 1;
            Screen('FillPoly', obj.WinHandle, colours(:,1), vertices(:,:,1), isConvex);
            Screen('FillPoly', obj.WinHandle, colours(:,2), vertices(:,:,2), isConvex);
            Screen('FillPoly', obj.WinHandle, colours(:,3), vertices(:,:,3), isConvex);
        end
        
        function FillRect(obj, colour, rect)
            Screen('FillRect', obj.WinHandle, colour, rect); 
        end
        
        function DrawDots(obj, offsetPositions, dotWidth, color)
            Screen('DrawDots', obj.WinHandle, offsetPositions, dotWidth, color, [], 2); 
        end

        function DrawFixation(obj, fixColor, fixPos)
            if nargin < 3
                cx = obj.WinCentre.x;
                cy = obj.WinCentre.y;
                fixPos = [cx cy cx cy; cx cy cx cy]' + 1;
            end
            
            if nargin < 2
                fixColor = [0 0 0];
            end
                
            Screen('FillRect', obj.WinHandle, fixColor, fixPos);
        end
    
        function DrawRect(obj, frameRect, colour, width)
            if nargin < 4
                width = 1;
            end
            if nargin < 3
                colour = [0 0 0];
            end
            Screen('FrameRect', obj.WinHandle, colour, frameRect, width);
        end

        function vbl = Flip(obj, vblOld)
            if nargin == 1
                vblOld = GetSecs;
            end
            vbl = Screen('Flip', obj.WinHandle, vblOld);
            if obj.DidPressQuit()
                quit
            end
        end    
        
        function obj = SetMouse(obj)
            SetMouse(obj.WinCentre.x, obj.WinCentre.y, obj.WinHandle);
            ShowCursor('Arrow');
        end
        
        function [x,y,buttons,obj] = GetMouse(obj)
            [x,y,buttons] = GetMouse(obj.WinHandle);
        end
        
        function DrawTextAt(obj, message, colour, x, y)
            DrawFormattedText(obj.WinHandle, message, x, y, colour);
        end
        
        function textures = MakeTexturesFromFiles(obj, path, filenames)
            for i = 1:length(filenames)
                textures(i) = MakeTextureFromFile(obj, [path filenames{i}]);
            end
        end
        
        function texture = MakeTextureFromFile(obj, filename)
            img = imread(filename);
            texture = Screen('MakeTexture', obj.WinHandle, img);
        end
        
        function DrawTextures(obj, texturePointers, destinationRects)
            Screen('DrawTextures', obj.WinHandle, texturePointers,[], destinationRects);
        end
        
        function DrawImages(obj, textures, positions, imageWidth)
            for i = 1:length(positions)
               destRects(1,i) = positions(1,i) - imageWidth/2; % left border of image
               destRects(2,i) = positions(2,i) - imageWidth/2; % top border of image
               destRects(3,i) = positions(1,i) + imageWidth/2; % right border of image
               destRects(4,i) = positions(2,i) + imageWidth/2; % bottom border of image
            end
            obj.DrawTextures(textures, destRects)
        end
        
        function DisplayMessage(obj, message, colour, wrapat)
            if nargin < 4
                wrapat = 50;
            end
            if nargin < 3
                colour = [0 0 0];
            end
            DisplayMessageAt(obj, message, 'center', 'center', colour, wrapat)
        end

        function DisplayMessageAt(obj, message, sx, sy, colour, wrapat)
            if nargin < 4
                wrapat = 50;
            end
            if nargin < 3
                colour = [0 0 0];
            end
            DrawFormattedText(obj.WinHandle, message, sx, sy, colour, wrapat);
            Screen('Flip', obj.WinHandle);
        end
        
        % Draw the specified message to the buffer, flip, and wait for a key press
        % colour & wrapat are optional
        function DisplayMessageAndWait(obj, message, colour, wrapat)
            if nargin < 4
                wrapat = 50;
            end
            if nargin < 3
                colour = [0 0 0];
            end
            obj.DisplayMessage(message, colour, wrapat);
            SitNWait(obj.WinHandle);
        end

        % Draw the specified message to the buffer, flip, and wait for a 
        % specific key press
        % colour & wrapat are optional
        function DisplayMessageAndWaitForKey(obj, message, key, colour, wrapat)
            if nargin < 5
                wrapat = 50;
            end
            if nargin < 4
                colour = [0 0 0];
            end
            obj.DisplayMessage(message, colour, wrapat);
            SitNWaitForKey(key);
        end
        
        function [yes, time] = GetYN(obj)
            time = -1;
            doLoop=1;
            yNum = KbName('y');
            nNum = KbName('n');
            while KbCheck; end % Make sure no keys are down
            while doLoop
                WaitSecs(0.001);
                [keyIsDown, secs, keyCode, ~] = KbCheck;
                if keyCode(yNum)==1
                    yes = 1;
                    doLoop=0;
                    time = secs;
                elseif keyCode(nNum)==1
                    yes = 0;
                    doLoop=0;
                    time = secs;
                end
            end

            % Now wait for key to be released
            while keyIsDown
                WaitSecs(0.01);
                [keyIsDown, ~, ~, ~] = KbCheck;
            end
        end
        
        function string = GetEchoString(obj, message, colour)
            KbName('UnifyKeyNames');
            
            % What follows is copied and altered from PsychToolBox/PsychOneLiners/GetEchoString.m

            FlushEvents;
            % Write the message
            DrawFormattedText(obj.WinHandle, message, 'center', 'center', colour, 40);
            Screen('Flip', obj.WinHandle, 0, 1);

            string = '';
            while true
                char = GetKbChar();

                switch (abs(char))
                    case {13, 3, 10}
                        % ctrl-C, enter, or return
                        break;
                    case 8
                        % backspace
                        if ~isempty(string)
                            string = string(1:length(string)-1);
                        end
                    otherwise
                        string = [string, char]; %#ok<AGROW>
                end

                output = [message, ' ', string];
                DrawFormattedText(obj.WinHandle, output, 'center', 'center', colour, 40);
                Screen('Flip', obj.WinHandle);
            end
            
        end
        
        function result = DidPressQuit(obj)
            result = 0;
            [keyIsDown, ~, keyCode, ~] = KbCheck;
            if keyIsDown
                if keyCode == KbName('z') & KbName('LeftControl')
                    result = 1;
                end
            end
        end
        
        function DrawArrow(obj, direction)
           colour = [0 0 0];
           tx = obj.WinCentre.x;
           ty = obj.WinCentre.y;
           Screen('FillRect', obj.WinHandle, colour, [tx-30 ty+60 tx+30 ty+90]);
           switch direction
               case 'Right'
                   pointList = [tx+30 ty+50; tx+60 ty+75; tx+30 ty+100];
           end
           Screen('FillPoly', obj.WinHandle, colour, pointList); 
        end
            
        function delete(obj)
            Screen('CloseAll'); ShowCursor; FlushEvents; ListenChar(0);
            Screen('Preference', 'VisualDebugLevel', obj.OldVisualDebugLevel);
            Screen('Preference', 'SuppressAllWarnings', obj.OldSupressAllWarnings);
            % Force java garbage collection because something is causing the java heap
            % to overflow TODO need to find out where the leak is. Possibly
            % only occurs when the program is terminated prematurely
            java.lang.Runtime.getRuntime.gc;
        end
    end % methods
end % classdef

%%%%%%%%%%%
% SitNWait - wait for any key to be pressed
%%%%%%%%%%%
function SitNWait(win)
    keyIsDown = 0;
    while KbCheck; end % Make sure no keys are down
    [~,~,mouseButtonsDown] = GetMouse(win);
    while any(mouseButtonsDown) % Make sure no mouse buttons are down
        WaitSecs(0.001);
        [~,~,mouseButtonsDown] = GetMouse(win);
    end

    while keyIsDown ~= 1 && ~any(mouseButtonsDown)
        WaitSecs(0.001);
        [keyIsDown, ~, ~, ~] = KbCheck;
        [~,~,mouseButtonsDown] = GetMouse(win);
    end
    %if keyCode(27)==1 || keyCode(41)==1
    %    error('User aborted experiment');
    %end
    while keyIsDown
        WaitSecs(0.001);
        keyIsDown = KbCheck;
    end
    while any(mouseButtonsDown)
        WaitSecs(0.001);
        [~,~,mouseButtonsDown] = GetMouse(win);
    end
end

%%%%%%%%%%%
% SitNWaitForKey - wait for a specific key to be pressed
%%%%%%%%%%%
function SitNWaitForKey(key)
    keyIsDown = 0;
    keyPressed = 0;
    while KbCheck; end % Make sure no keys are down
    while keyPressed == 0
        WaitSecs(0.001);
        [keyIsDown, ~, keyCode, ~] = KbCheck;
        if keyCode(27)==1 || keyCode(41)==1
            error('User aborted experiment');
        elseif keyCode(KbName(key)) == 1
            keyPressed = 1;
        end
    end
    while keyIsDown
        WaitSecs(0.001);
        keyIsDown = KbCheck;
    end
end
