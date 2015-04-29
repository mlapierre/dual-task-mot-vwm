classdef MOT_SessionConfig < SessionConfig
    properties (Constant = true)
        StimuliType = StimuliType.Dot;
        ExperimentName = 'MOT_VWM_2';
        ExperimentVersion = '2.1.1';
        TaskTypes = [TaskType.MOT TaskType.VWM];
        ResponseType = ResponseType.Probe;
        TargetCueColour = [255 0 0]';
        TargetColour = [0 0 0]';
        DistractorColour = [0 0 0]';
        ResponseColour = [0 255 255]';
        CorrectColour = [0 255 0]';
    end
    
    properties
        % 'Both' is included twice because once is for MOT performance and once for VWM performance
        TestConditionTypes = [Condition.PerformMOT Condition.PerformVWM Condition.PerformBoth Condition.PerformBoth];
        PracticeConditionTypes = [Condition.PerformMOT Condition.PerformVWM Condition.PerformBoth];
        
        NumTestBlocks = 1; 
        NumTrialsPerCondition = 16; %16
        NumTrialsPerTestBlock;
        NumPracticeTrialsPerCondition = 8; %8
        InterQuadrantPadding;
        QuadrantWidthInDegrees = 15.3;
        QuadrantHeightInDegrees = 11.5;
        FlipConditionOrder;
        NumMOTObjects = 8;
        NumMOTTargets = 4;
        NumVWMObjects = 4;
        VWMObjectDistanceFactor = 5;
        VWMObjectDistance
        VWMObjectColours = [255 0 0; 0 255 0; 255 255 0; 0 0 255; 0 255 255; 128 64 0; 255 0 255; 128 0 255; 255 128 0; 128 128 64]';
        %VWMObjectColours = [255 0 0; 0 255 0; 255 255 0; 0 0 255; 0 255 255; 128 64 0; 128 0 255; 255 128 0]';
        %VWMObjectColours = [255 0 0; 0 255 0; 255 255 0; 0 0 255; 0 255 255; 128 64 0; 255 0 255]';
        %VWMObjectColours = [255 0 0; 0 255 0; 255 255 0; 0 0 255; 0 255 255]';
        VWMObjectDisplayTime = 0.2;
        VWMStimArraySize = [4 3];
        ProbeTime = 1.5;
        ShowFixation = 0;
        ProvideMOTFeedback = 0;
        ProvideVWMFeedback = 0;
    end % properties

    methods
        function obj = MOT_SessionConfig(window, subjectName, num, viewParams)
            super_args{1} = window;
            if nargin >= 2
                super_args{2} = subjectName;
                super_args{3} = num;
            end
            
            if nargin >= 4
                super_args{7} = viewParams;
            end
            
            obj = obj@SessionConfig(super_args{:});
            
            obj.InterQuadrantPadding = obj.DotWidth/2;
            obj.Threshold = 0.75;
            obj.Gamma = 0.5;

            if obj.Debug == 1
                obj.NumTrialsPerCondition = 2;
                obj.NumPracticeTrialsPerCondition = 2; 
                obj.NumQUESTTrials = 4; 
                obj.TrialTimePractice = 2;
                obj.TimeTrialTest = 2;
            else
                obj.NumQUESTTrials = 40; 
            end
            obj.NumTrialsPerTestBlock = obj.NumTrialsPerCondition * length(obj.TestConditionTypes);
            obj.FlipConditionOrder = ~mod(num, 2);
            % Load and override observer-specfic settings
            %obj = obj.LoadUserConfig(obj.SubjectID);
            obj.TimeTrialTotal = obj.TimeTrialTest;
            obj.NumFrames = round(obj.TimeTrialTotal / obj.Window.InterFrameInterval);            

            obj.VWMObjectDistance = round(obj.VWMObjectDistanceFactor/obj.DegPerPixel);
            
            if mod(obj.NumPracticeTrialsPerCondition,2) == 1
                error('NumPracticeTrialsPerCondition must be even');
            elseif mod(obj.NumTrialsPerCondition,2) == 1
                error('NumTrialsPerCondition must be even');
            end
        end
    end
end