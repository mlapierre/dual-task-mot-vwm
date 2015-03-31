classdef QuadrantLayout
    properties (Constant)
        UnilateralLeftID = 1;
        UnilateralRightID = 2;
        BilateralAboveID = 3;
        BilateralBelowID = 4;
        AllID = 5;

        % Quadrants arranged clockwise from top-left
        UnilateralLeft = [1 0 0 1];
        UnilateralRight = [0 1 1 0];
        BilateralAbove = [1 1 0 0];
        BilateralBelow = [0 0 1 1];
        All = [1 1 1 1];
    end
    
    methods (Static)
        % Returns a randomised, counterbalanced list of quadrant configurations
        % Input: 
        %   numTrials: The total number of trials. Used to determine how many 
        %              times each layout must be included to ensure proper
        %              counterbalancing.
        function layoutList = GetLayoutList(numTrials)
           layoutTypes = [QuadrantLayout.UnilateralLeft
                          QuadrantLayout.UnilateralRight
                          QuadrantLayout.BilateralAbove
                          QuadrantLayout.BilateralBelow]';
           layoutList = repmat(layoutTypes, 1, numTrials/4);
           layoutList = layoutList(:, randperm(numTrials));
        end

        function layoutList = GetUnilateralLayoutList(numTrials)
           layoutTypes = [QuadrantLayout.UnilateralLeft
                          QuadrantLayout.UnilateralRight]';
           layoutList = repmat(layoutTypes, 1, numTrials/2);
        end

        function layoutList = GetBilateralLayoutList(numTrials)
           layoutTypes = [QuadrantLayout.BilateralAbove
                          QuadrantLayout.BilateralBelow]';
           layoutList = repmat(layoutTypes, 1, numTrials/2);
        end

        function name = GetLayoutName(layout)
           if isequal(layout, QuadrantLayout.UnilateralRight)
               name = 'UnilateralRight';
           elseif isequal(layout, QuadrantLayout.UnilateralLeft)
               name = 'UnilateralLeft';
           elseif isequal(layout, QuadrantLayout.BilateralAbove)
               name = 'BilateralAbove';
           elseif isequal(layout, QuadrantLayout.BilateralBelow)
               name = 'BilateralBelow';
           elseif isequal(layout, QuadrantLayout.All)
               name = 'All';
           else
               error('Specific layout does not match any of the predefined ones.');
           end
        end
        
        function id = GetLayoutID(layout)
           if isequal(layout, QuadrantLayout.UnilateralRight)
               id = QuadrantLayout.UnilateralRightID;
           elseif isequal(layout, QuadrantLayout.UnilateralLeft)
               id = QuadrantLayout.UnilateralLeftID;
           elseif isequal(layout, QuadrantLayout.BilateralAbove)
               id = QuadrantLayout.BilateralAboveID;
           elseif isequal(layout, QuadrantLayout.BilateralBelow)
               id = QuadrantLayout.BilateralBelowID;
           elseif isequal(layout, QuadrantLayout.All)
               id = QuadrantLayout.AllID;
           else
               error('Specific layout does not match any of the predefined ones.');
           end
        end
        
        function layout = Flip(in)
           if in == QuadrantLayout.UnilateralLeft
               layout = QuadrantLayout.UnilateralRight;
           elseif in == QuadrantLayout.UnilateralRight
               layout = QuadrantLayout.UnilateralLeft;
           elseif in == QuadrantLayout.BilateralAbove
               layout = QuadrantLayout.BilateralBelow;
           elseif in == QuadrantLayout.BilateralBelow
               layout = QuadrantLayout.BilateralAbove;
           else
               error('Specific layout does not match any of the predefined ones.');
           end
        end
    end
end        