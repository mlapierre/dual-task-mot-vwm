classdef MOT_Trial
    properties
        Speed
        Positions
        Displacement
        Config
        Window
        SwapColours
        QuadActive
        UniqueIdentities
        ResponseType
        ObjectType
        StimuliTexturePointers
        Mask
        TaskTypes
        FlipQuadTargets
        Elements % Objects to be tracked
        NumTargets
        NumObjects
        Condition
        ValidProbe
        VWMObjectColours
        NumVWMObjects
    end % properties
    
    methods
        % Constructor
        function obj = MOT_Trial(conf, win, taskTypes, speed, layout, stim)
            if nargin < 6
                stim = [];
            end
            if nargin < 5
                layout = QuadrantLayout.GetLayoutList(conf.NumTestTrials);
            end
            if nargin < 4
                obj.Speed = 5;
            else
                obj.Speed = speed;
            end
            obj.Config = conf;
            obj.Window = win;
            obj.NumTargets = conf.NumMOTTargets;
            obj.NumObjects = conf.NumMOTObjects + conf.NumVWMObjects;
            obj.SwapColours = 0;
            obj.Displacement = obj.Speed * win.InterFrameInterval / conf.DegPerPixel;
            obj.UniqueIdentities = 0;
            obj.ResponseType = ResponseType.Probe;
            obj.ObjectType = ObjectType.Dot;
            obj.QuadActive = layout;
            obj.StimuliTexturePointers = stim;
            obj.TaskTypes = taskTypes;
            obj.FlipQuadTargets = 0;
            obj.Elements = [];

            index = Shuffle(1:size(obj.Config.VWMObjectColours,2));
            obj.VWMObjectColours = obj.Config.VWMObjectColours(:, index(1:obj.Config.NumVWMObjects));
        end
        
        function positions = ChangeLayout(obj, positions)
            qFrame = obj.GetBoundaries();

            frameLeft = qFrame(1,1);
            frameRight = qFrame(3,2);
            
            frameWidth = ((frameRight - frameLeft)/2) + obj.Config.InterQuadrantPadding;
            
            % QuadActive represents the new layout. The original layout must be the appropriate
            % alternative. This isn't checked!
            if obj.QuadActive == QuadrantLayout.UnilateralLeft
                positions(1,:,:) = positions(1,:,:) - frameWidth;
            elseif obj.QuadActive == QuadrantLayout.UnilateralRight
                positions(1,:,:) = positions(1,:,:) + frameWidth;
            elseif obj.QuadActive == QuadrantLayout.BilateralAbove
                positions(2,:,:) = positions(2,:,:) - frameWidth;
            elseif obj.QuadActive == QuadrantLayout.BilateralBelow
                positions(2,:,:) = positions(2,:,:) + frameWidth;
            else
                error('Specific layout does not match any of the predefined ones.');
            end
        end
        
        function positions = MirrorPositions(obj, positions)
            qFrame = obj.GetBoundaries();

            if obj.QuadActive == QuadrantLayout.UnilateralLeft
                qMid = (qFrame(3,1) + qFrame(1,1))/2;
                positions(1,:,:) = qMid - positions(1,:,:) + qMid;
            elseif obj.QuadActive == QuadrantLayout.UnilateralRight
                qMid = (qFrame(3,2) + qFrame(1,2))/2;
                positions(1,:,:) = qMid - positions(1,:,:) + qMid;
            else
                error('Specific layout does not match any of the predefined ones or mirroring operation not defined.');
            end
        end
       
        function DrawObjectsAndCues(obj, positions, objectState, maskOn)
            if nargin < 4
                maskOn = 0;
            end
            colours = [zeros(3, obj.Config.NumMOTObjects) repmat([255 255 255]',1, obj.Config.NumVWMObjects)];
            ovals = zeros(4, obj.NumTargets);
            oval_index = 1;
            rad = obj.Config.DotWidth*.75;
            for i=1:obj.Config.NumMOTObjects
                if objectState.Cue(i) == 1
                    ovals(:,oval_index) = [positions(1,i)-rad positions(2,i)-rad positions(1,i)+rad positions(2,i)+rad];
                    oval_index = oval_index + 1;
                end
            end
            
            % Display the VWM object colours during the cue phase
            if any(objectState.Cue(objectState.ObjectState == ObjectState.VWM) == 1)
                colours(:, obj.Config.NumMOTObjects+1:obj.NumObjects) = obj.VWMObjectColours;
            end

            obj.Window.FrameOval(repmat([255 255 255]',1, obj.NumTargets), ovals);
            obj.Window.DrawDots(positions, obj.Config.DotWidth, colours);
        end % end DrawObjects
        
        function DrawInterQuadrantPadding(obj)
            frame = obj.GetBoundaries();
            pad(1,1) = frame(3,1);
            pad(2,1) = frame(2,1);
            pad(3,1) = frame(1,2);
            pad(4,1) = frame(4,4);
            pad(1,2) = frame(1,1);
            pad(2,2) = frame(4,1);
            pad(3,2) = frame(3,2);
            pad(4,2) = frame(2,3);
            obj.Window.FillRect(obj.Config.InterQuadrantPaddingColour, pad);
            obj.Window.DrawRect(frame, obj.Config.InterQuadrantPaddingColour, 1);
        end
        
        % Execute a single trial
        function [finPos missedFrames] = DisplayTrial(obj, showTargetsFrames, targetsOn)
            if nargin < 3
                targetsOn = 0;
            end
            if nargin < 2
                showTargetsFrames = 0;
            else
                if showTargetsFrames > size(obj.Positions,3)/2
                    error('Don''t reveal the targets for more than half the trial length');
                end
            end

            % Set coordinates & colour of fixation cross
            win = obj.Window;
            cx = win.WinCentre.x;
            cy = win.WinCentre.y;
            fixPos = [cx cy cx cy; cx cy cx cy]' + 1/obj.Config.DegPerPixel*[ -0.05 -0.25 0.05 0.25; -0.25 -0.05 0.25 0.05]';
            fixColor = 0*ones(3,2);

            missedFrames = 0;
            cueFreq = obj.Config.CueFreq;
            cueOnCount = round((1/win.InterFrameInterval)*cueFreq);
            cueFrameCount = 0;

            % Reveal targets briefly at random points during the trial
            % Divide the revealed frames into 40 frame blocks, randomly
            % distributed throughout the trial after the cue period
            revealTargets = zeros(1,size(obj.Positions,3));
            if showTargetsFrames > 0
                lastColouredFrame = ceil(obj.Config.CueTime/win.InterFrameInterval);
                numBlocks = floor(showTargetsFrames/40)-1;
                if numBlocks > 0
                    trackPortion = size(obj.Positions,3) - lastColouredFrame;
                    framesPerBlock = floor(trackPortion/numBlocks);
                    for i = 1:numBlocks
                        blockStart = lastColouredFrame + (framesPerBlock * i-1) + randi(framesPerBlock);
                        if size(obj.Positions,3) > blockStart + 100
                            % Set the frames to be displayed
                            revealTargets(blockStart:blockStart+40) = 1;
                        else
                            break;
                        end
                    end
                end
            end
            
            % Determine if objects will be cued
            %objectState = obj.GetObjectState(1, isSingleTask);
            frame = 1;
            isCueOn = 1;
            obj.Elements = obj.GetElementState(frame, isCueOn);

            % Render the stimuli
            Priority(2);

            % Display static stimuli for FixationTime seconds.
            %obj.DrawImages(obj.Positions(:,:,1));
            %obj.DrawCues(1, [1 2 5 6], obj.Config.TargetColour);
            obj.DrawObjectsAndCues(obj.Positions(:,:,1), obj.Elements);
            
            if obj.Config.ShowFixation
                win.DrawFixation(fixColor, fixPos);
            end
            
            win.Flip();
            WaitSecs(obj.Config.FixationTime);

            vblNew = GetSecs;
            vblOld = vblNew;

            % Display the remaining frames
            for i=2:size(obj.Positions,3)
                if (targetsOn || revealTargets(i) || i < round(obj.Config.CueTime / obj.Config.InterFrameInterval))
                    isCueOn = 1;
                else
                    isCueOn = 0;
                end
                obj.Elements = obj.GetElementState(i, isCueOn);
                
                obj.DrawObjectsAndCues(obj.Positions(:,:,i), obj.Elements);
                if obj.Config.ShowFixation
                    win.DrawFixation(fixColor, fixPos);
                end
                vblNew = win.Flip(vblOld);

                if vblNew - vblOld > 1.5 * win.InterFrameInterval
                    missedFrames = missedFrames + 1;
                end
                vblOld = vblNew;
            end
            finPos = obj.Positions(:,:,i);
            Priority(0);
        end
        
        function DrawImages(obj, positions, mask)
            if nargin < 3
                mask = 0;
            end
            if mask == 0 
                stim = obj.StimuliTexturePointers;
            else
                stim = obj.Mask;
            end
            obj.Window.DrawImages(stim, positions, obj.Config.ImageWidth);
        end
        
        function DrawCues(obj, frame, targets, colour)
            for i = 1:length(targets)
                rects(1,i) = obj.Positions(1, targets(i), frame) - obj.Config.ImageWidth/2 - 1;
                rects(2,i) = obj.Positions(2, targets(i), frame) - obj.Config.ImageWidth/2 - 1;
                rects(3,i) = obj.Positions(1, targets(i), frame) + obj.Config.ImageWidth/2 + 1;
                rects(4,i) = obj.Positions(2, targets(i), frame) + obj.Config.ImageWidth/2 + 1;
            end
            obj.Window.DrawRect(rects, colour, 3);
        end
        
        function DrawFeedback(obj, positions, colours)
            if sum(sum(colours)) ~= 0
                for i = 1:length(positions)
                    rects(1,i) = positions(1, i) - obj.Config.ImageWidth/2 - 3;
                    rects(2,i) = positions(2, i) - obj.Config.ImageWidth/2 - 3;
                    rects(3,i) = positions(1, i) + obj.Config.ImageWidth/2 + 3;
                    rects(4,i) = positions(2, i) + obj.Config.ImageWidth/2 + 3;
                    if sum(colours(:,i)) == 0
                        colours(:,i) = [255 255 255]';
                    end
                end
                obj.Window.DrawRect(rects, colours, 4);
            end
        end
        function DrawProbe(obj, pos, probe, colour)
            if nargin < 4
                colour = obj.Config.TargetColour;
            end
                
            rect(1) = pos(1, probe) - obj.Config.ImageWidth/2 - 3;
            rect(2) = pos(2, probe) - obj.Config.ImageWidth/2 - 3;
            rect(3) = pos(1, probe) + obj.Config.ImageWidth/2 + 3;
            rect(4) = pos(2, probe) + obj.Config.ImageWidth/2 + 3;
            obj.Window.DrawRect(rect, colour, 4);
        end
        
        function DisplayProbe(obj, positions, probe_is_valid)
            colours = [zeros(3, obj.Config.NumMOTObjects) repmat([255 255 255]',1, obj.Config.NumVWMObjects)];
            ovals = zeros(4, obj.NumTargets);
            index = Shuffle(obj.Config.NumMOTObjects+1:obj.NumObjects);
            if probe_is_valid
                % 50% chance of probing a valid object/position
                colours(:, index(1)) = obj.VWMObjectColours(:, index(1)-obj.Config.NumMOTObjects);
                MOT_probe = 1;
            else
                % Otherwise swap the colour at the location of one object
                % with the colour of a different object
                colours(:, index(1)) = obj.VWMObjectColours(:, index(2)-obj.Config.NumMOTObjects);
                % and probe a distractor
                MOT_probe = (obj.Config.NumMOTObjects/2) + 1;
            end
            %colours(:, MOT_probe) = obj.Config.TargetCueColour;
            rad = obj.Config.DotWidth*.75;
            oval = [positions(1,MOT_probe)-rad positions(2,MOT_probe)-rad positions(1,MOT_probe)+rad positions(2,MOT_probe)+rad];
            
            if obj.Config.ShowFixation
                cx = obj.Window.WinCentre.x;
                cy = obj.Window.WinCentre.y;
                fixPos = [cx cy cx cy; cx cy cx cy]' + 1/obj.Config.DegPerPixel*[ -0.05 -0.25 0.05 0.25; -0.25 -0.05 0.25 0.05]';
                fixColor = 0*ones(3,2);
                obj.Window.DrawFixation(fixColor, fixPos);
            end

            obj.Window.FrameOval([255 255 255]', oval);
            obj.Window.DrawDots(positions, obj.Config.DotWidth, colours);            
            obj.Window.Flip();
            WaitSecs(obj.Config.ProbeTime);
            obj.Window.Flip();
        end
        

        function output = GetResponse(obj, positions, task_type, probe_is_valid)
            if obj.Condition == Condition.PerformMOT || (obj.Condition == Condition.PerformBoth && task_type == TaskType.MOT)
                switch obj.ResponseType
                    case ResponseType.Probe
                        output = obj.GetProbeResponse(probe_is_valid);
                    case ResponseType.ClickAll
                        [overallCorrect output obj] = obj.GetClickAllResponse(positions);
                    otherwise
                        error('Unknown ResponseType');
                end
            elseif obj.Condition == Condition.PerformVWM || (obj.Condition == Condition.PerformBoth && task_type == TaskType.VWM)
                output = obj.GetVWMResponse(probe_is_valid);
            else
                error('Invalid Task Type');
            end
        end

        function response = GetVWMResponse(obj, probe_is_valid)
            obj.Window.DisplayMessage('Was the coloured dot in the same position before (y/n)?', [0 0 255], 40);
            response.probe_message_display_time = GetSecs;
            [res, time] = obj.Window.GetYN();
            if res == probe_is_valid
                response.correct = 1;
                message = 'Correct!';
            else
                response.correct = 0;
                message = 'Sorry, that was wrong.';
            end
            response.probe_message_response_time = time;
            
            if obj.Config.ProvideVWMFeedback == 1
                message = [message '\n\nPlease press a key to continue.'];
                obj.Window.DisplayMessageAndWait(message, [0 0 255], 40);
            end
        end      
        
        function output = GetProbeResponse(obj, testTarget)
            correct = 0;
            incorrect = 0;
            win = obj.Window;
            win.DisplayMessage('Was the marked moving dot a target (y/n)?', [0 0 255], 40);
            output.probe_message_display_time = GetSecs;

            % Get response
            [response, time] = win.GetYN();
            if response == testTarget
                correct = 1;
                incorrect = 0;
            else
                correct = 0;
                incorrect = 1;
            end

            % Output results
            output.correct = correct;
            output.incorrect = incorrect;
            output.repeatTrial = 0;
            output.validProbe = testTarget;
            output.probe_message_response_time = time;
            
            if obj.Config.ProvideMOTFeedback == 1
                if correct == 1 
                    message = 'Correct!\n\n';
                    feedbackColour = obj.Config.CorrectColour;
                else
                    message = 'Sorry, that was wrong.\n\n';
                    feedbackColour = obj.Config.TargetCueColour;
                end
            
                %obj.DrawImages(offsetPositions)
                %obj.DrawProbe(offsetPositions, probe, feedbackColour);

                message = [message 'Please press a key to continue.'];
                win.DisplayMessageAndWait(message, [0 0 255]);
            end
        end
                
        function [overallCorrect output, obj] = GetClickAllResponse(obj, positions) 
            obj.Window = obj.Window.SetMouse();

            cx = obj.Window.WinCentre.x;
            cy = obj.Window.WinCentre.y;
            fixPos = [cx cy cx cy; cx cy cx cy]' + 1/obj.Config.DegPerPixel*[ -0.05 -0.25 0.05 0.25; -0.25 -0.05 0.25 0.05]';
            fixColor = 0*ones(3,2);
            
            buttonDownPrev = 0;        
            correct = 0;
            incorrect = 0;
            
            %colours  = zeros(3, obj.NumObjects);
            selected = zeros(1, obj.NumObjects);

            numTargets = obj.NumTargets;
            if find(obj.Condition == Condition.SingleTask | obj.Condition == Condition.SingleSet)
                numTargets = obj.NumTargetsPerSet;
            end
            
            isCueOn = 0;
            objectState = obj.GetElementState(size(obj.Positions,2), isCueOn);
            for i=1:length(objectState.ObjectState)
                if objectState.ObjectState(i) == ObjectState.TargetA 
                    colourFeedback(:,i) = obj.Config.TargetCueColour;
                    colours(:,i) = obj.Config.TargetAColour;
                elseif objectState.ObjectState(i) == ObjectState.TargetB
                    colourFeedback(:,i) = obj.Config.TargetCueColour;
                    colours(:,i) = obj.Config.TargetBColour;
                elseif objectState.ObjectState(i) == ObjectState.DistractorA
                    colourFeedback(:,i) = obj.Config.DistractorAColour;
                    colours(:,i) = obj.Config.DistractorAColour;
                elseif objectState.ObjectState(i) == ObjectState.DistractorB
                    colourFeedback(:,i) = obj.Config.DistractorBColour;
                    colours(:,i) = obj.Config.DistractorBColour;
                end
            end
            
            responseCount = 0;
            while responseCount < numTargets
                % Show display and ask subject to click on target dots
                %obj.Window.DrawImages(obj.Mask, positions, obj.Config.ImageWidth);
                %obj.DrawImages(positions, 1);
                %obj.DrawFeedback(positions, colours);
                obj.Window.DrawDots(positions, obj.Config.DotWidth, colours);
                if find(obj.Condition == Condition.Unilateral | obj.Condition == Condition.Bilateral)
                    obj.DrawInterQuadrantPadding();
                end
                if obj.Config.ShowFixation
                    obj.Window.DrawFixation(fixColor, fixPos);
                end
                obj.Window.DisplayMessage('Click each target', [0 0 255], 40);

                % Get mouse click
                [x,y,buttons,obj.Window] = obj.Window.GetMouse();
                if any(buttons) && buttonDownPrev==0
                    buttonDownPrev = 1;
                    aa = (positions - [x*ones(1,obj.NumObjects); y*ones(1,obj.NumObjects)]).^2;
                    bb = (sum(aa,1)).^0.5;
                    [Y, I] = min(bb);
                    if Y < obj.Config.ImageWidth/2
                        if ~selected(I(1,1))
                            selected(I(1,1)) = 1;
                            if objectState.ObjectState(I(1,1)) == ObjectState.TargetA || ...
                               objectState.ObjectState(I(1,1)) == ObjectState.TargetB
                                correct = correct+1;
                                colourFeedback(:,I(1,1)) = obj.Config.CorrectColour;
                            else
                                incorrect = incorrect + 1;
                            end
                            colours(:,I(1,1)) = obj.Config.ResponseColour;
                            responseCount = responseCount + 1;
                        else
                            selected(I(1,1)) = 0;
                            if objectState.ObjectState(I(1,1)) == ObjectState.TargetA
                                correct = correct-1;
                                colourFeedback(:,I(1,1)) = obj.Config.TargetAColour;
                            elseif objectState.ObjectState(I(1,1)) == ObjectState.TargetB
                                correct = correct-1;
                                colourFeedback(:,I(1,1)) = obj.Config.TargetBColour;
                            else
                                incorrect = incorrect-1;
                            end
                            %colours(:,I(1,1)) = [0 0 0]';
                            if objectState.ObjectState(I(1,1)) == ObjectState.TargetA 
                                colours(:,I(1,1)) = obj.Config.TargetAColour;
                            elseif objectState.ObjectState(I(1,1)) == ObjectState.TargetB
                                colours(:,I(1,1)) = obj.Config.TargetBColour;
                            elseif objectState.ObjectState(I(1,1)) == ObjectState.DistractorA
                                colours(:,I(1,1)) = obj.Config.DistractorAColour;
                            elseif objectState.ObjectState(I(1,1)) == ObjectState.DistractorB
                                colours(:,I(1,1)) = obj.Config.DistractorBColour;
                            end
                            responseCount = responseCount - 1;
                        end
                    end
                elseif any(buttons)==0
                    buttonDownPrev = 0;
                end
            end
            HideCursor;

            % Output results
            output.correct = correct;
            output.incorrect = incorrect;
            output.selected = selected;
            output.repeatTrial = 0;

            overallCorrect = correct == numTargets;
           
            %obj.DrawImages(positions)
            %obj.DrawFeedback(positions, colourFeedback);
            obj.Window.DrawDots(positions, obj.Config.DotWidth, colourFeedback);
            if find(obj.Condition == Condition.Unilateral | obj.Condition == Condition.Bilateral)
                obj.DrawInterQuadrantPadding();
            end
            if obj.Config.ShowFixation
                obj.Window.DrawFixation(fixColor, fixPos);
            end

            message = ['You got ' num2str(correct) ' correct.\n\n'];
            message = [message 'Please press a key to continue.'];
            obj.Window.DisplayMessageAndWait(message, [0 0 255]);
        end
        
        % Create an array of integer values to indicate the state of an object, e.g. if it is a 
        % target or a distractor.
        % The default assignment is for the first half of the object positions per quad to be 
        % classed as targets and the second half as distractors. Since object positions are
        % randomised, this effectively randomises the assignment of targets and distractors.
        function elementState = GetElementState(obj, frame, isCueOn)
            if nargin < 3
                isCueOn = 0;
            end
            
            targets = repmat(ObjectState.Target, 1, obj.NumTargets);
            distractors = repmat(ObjectState.Distractor, 1, obj.Config.NumMOTObjects - obj.NumTargets);
            vwm_objects = repmat(ObjectState.VWM, 1, obj.Config.NumVWMObjects);
            
            obj.Elements.ObjectState = [targets distractors vwm_objects];
            
            % Don't cue any objects by default
            obj.Elements.Cue = zeros(1, obj.NumObjects);
            
            % Cue targets during cue phase of the trial
            % Display VWM colours too, but only briefly
            if isCueOn == 1 && (frame < round(obj.Config.CueTime / obj.Config.InterFrameInterval))
                obj.Elements.Cue(obj.Elements.ObjectState == ObjectState.Target) = 1;
                if frame < round(obj.Config.VWMObjectDisplayTime / obj.Config.InterFrameInterval)
                    obj.Elements.Cue(obj.Elements.ObjectState == ObjectState.VWM) = 1;
                end
            end
            elementState = obj.Elements;
        end
        
        % Generate the dot positions and colours for each frame of one trial
        function [allPositions] = GeneratePositions(obj)
            % Initialize dot positions
            [positions, d] = obj.initializePositions();

            % Counters
            cont = obj.Config.TimeTrialTotal - obj.Config.InterFrameInterval;
            frameCount = 1;
            
            % record the dot positions & colour
            allPositions = zeros(2, obj.NumObjects, obj.Config.NumFrames);
            allPositions(:,:,frameCount) = positions;
            
            obj.Displacement = obj.Speed * obj.Window.InterFrameInterval / obj.Config.DegPerPixel;            
            
            while cont > 0
                % Update the counters
                cont = cont - obj.Config.InterFrameInterval;
                frameCount = frameCount + 1;
                
                [positions, d] = obj.updateDotPositions(positions, d);

                allPositions(:,:,frameCount) = positions;
            end    
        end

        % Initialize positions
        %   Object positions refer to the centre of the image, whether dots
        %   or square images
        function [positions d] = initializePositions(obj)
            % Determine coordinates of boundaries of each quadrant
            [qFrame aR] = obj.GetBoundaries();
            
            if obj.NumObjects > 25
                error('Too many objects');
            end
            a(1,:) = round([1 2 3 4 5 1 2 3 4 5 1 2 3 4 5 1 2 3 4 5 1 2 3 4 5]*aR.width*0.1 + qFrame(1,1));
            a(2,:) = round([1 1 1 1 1 2 2 2 2 2 3 3 3 3 3 4 4 4 4 4 5 5 5 5 5]*aR.height*0.1 + qFrame(2,1));
            nn = Shuffle(1:25);
            positions = [a(:,nn(1:obj.Config.NumMOTObjects)) obj.GetVWMObjectPositions()];
            
            % Initialize speed
            displacement = 10*obj.Config.InterFrameInterval/obj.Config.DegPerPixel;
            d = rand(2,obj.NumObjects)-0.5;
            aa = 1./((sum(d.^2,1)).^0.5);
            d = displacement*[aa;aa].*d;
            
            for i=1:60
                [positions, d] = obj.updateDotPositions(positions, d);
            end

            % ReInitialize speed
            d = rand(2,obj.NumObjects)-0.5;
            aa = 1./((sum(d.^2,1)).^0.5);
            d = obj.Displacement*[aa;aa].*d;
        end
        
        % Update the object positions and displacement according to wall and inter-object repulsion factors
        function [positions, d] = updateDotPositions(obj, positions, d)
            % Determine coordinates of boundaries of each quadrant
            qFrame = obj.GetBoundaries();
            
            % Bounce the object off the side walls of each quadrant
            if obj.Config.StimuliType == StimuliType.Dot
                objectWidth = obj.Config.DotWidth;
            elseif obj.Config.StimuliType == StimuliType.Image
                objectWidth = obj.Config.ImageWidth;
            end
            
            % As speed increases the distance the object can move during a frame may exceed the
            % distance between the object and the edge of the boundary. This results in objects
            % partially overlapping the edge. So we'll add an inertia factor to the calculation of
            % dot position to account for the influence of speed.
            iF = objectWidth/2+obj.Displacement;
            
            I = find(positions(1,:)<(qFrame(1,1)+iF));
            d(1,I) = abs(d(1,I)+rand);
            I = find(positions(2,:)<(qFrame(2,1)+iF));
            d(2,I) = abs(d(1,I)+rand);
            I = find(positions(1,:)>(qFrame(3,1)-iF));
            d(1,I) = -abs(d(1,I)-rand);
            I = find(positions(2,:)>(qFrame(4,1)-iF));
            d(2,I) = -abs(d(1,I)-rand);
            
            % Calculate the inter-object repulsion factors
            xdist = ones(obj.NumObjects,1)*positions(1,:) - positions(1,:)'*ones(1,obj.NumObjects);
            ydist = ones(obj.NumObjects,1)*positions(2,:) - positions(2,:)'*ones(1,obj.NumObjects);
            dist = (xdist.^2+ydist.^2).^0.5;
            %jitter_factor = 100;
            R = [sum(sign(xdist)./((max(dist-obj.Config.MinSep,0.001)).^obj.Config.SF),1); sum(sign(ydist)./((max(dist-obj.Config.MinSep,0.001)).^obj.Config.SF),1)];
            %boids.velocity(:,index) = [cosd(angle) -sind(angle); sind(angle) cosd(angle)] * boids.velocity(:,index);
            angle = rand*15;
            R = [cosd(angle) -sind(angle); sind(angle) cosd(angle)] * R;

            % Update object positions
            d = d + R;
            aa = 1./((sum(d.^2,1)).^0.5);
            d = obj.Displacement*[aa;aa].*d;
            positions = positions+d;
            
            % Static VWM object positions
            positions(:, obj.Config.NumMOTObjects+1:obj.NumObjects) = obj.GetVWMObjectPositions();
        end
        
        % Get the rect coordinates of the 4 quadrants of the display
        function [qFrame aR] = GetBoundaries(obj)
            aR = obj.Window.ScreenRes;
            cx = obj.Window.WinCentre.x;
            cy = obj.Window.WinCentre.y;
            
            qWidth = round(obj.Config.QuadrantWidthInDegrees/obj.Config.DegPerPixel);
            qHeight = round(obj.Config.QuadrantHeightInDegrees/obj.Config.DegPerPixel);
            
            qFrame(1,1) = cx-obj.Config.InterQuadrantPadding-qWidth;
            qFrame(2,1) = cy-obj.Config.InterQuadrantPadding-qHeight;
            qFrame(3,1) = cx+obj.Config.InterQuadrantPadding+qWidth;
            qFrame(4,1) = cy+obj.Config.InterQuadrantPadding+qHeight;
        end
        
        function positions = GetVWMObjectPositions(obj)
            %aR = obj.Window.ScreenRes;
            cx = obj.Window.WinCentre.x;
            cy = obj.Window.WinCentre.y;
            
            r = obj.Config.VWMObjectDistance;
            n = obj.Config.NumVWMObjects;
            
            theta = linspace(0, 2*pi, n+1);
            theta = theta - ((360/n/2) * pi/180);
            %theta = (360/n+1)*(pi/180) + theta;
            rho = ones(1, n+1)*r;
            [X, Y] = pol2cart(theta, rho);
            positions(1,:) = X(2:n+1) + cx;
            positions(2,:) = Y(2:n+1) + cy;
            
%             positions(1,1) = cx - cosd(45)* obj.Config.VWMObjectDistance;
%             positions(2,1) = cy - sind(45)* obj.Config.VWMObjectDistance;
%             positions(1,2) = cx + cosd(45)* obj.Config.VWMObjectDistance;
%             positions(2,2) = cy - sind(45)* obj.Config.VWMObjectDistance;
%             positions(1,3) = cx + cosd(45)* obj.Config.VWMObjectDistance;
%             positions(2,3) = cy + sind(45)* obj.Config.VWMObjectDistance;
%             positions(1,4) = cx - cosd(45)* obj.Config.VWMObjectDistance;
%             positions(2,4) = cy + sind(45)* obj.Config.VWMObjectDistance;
        end
    end % methods
end % classdef
