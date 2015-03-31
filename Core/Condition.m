classdef Condition
    properties (Constant)
        PerformMOT = 1;
        PerformVWM = 2;
        PerformBoth = 3;
        MOTResponse = 4;
        VWMResponse = 5;
        Dual = 6;
        Single = 7;
        MOT = 8;
        VWM = 9;
    end
    
    methods (Static)
        function names = GetNames(conditions)
            names = [];
            for i=1:size(conditions,2)
                names = [names ' ' Condition.GetName(conditions(i))]; 
            end
        end
        
        function name = GetName(condition)
           switch condition
               case Condition.Single
                    name = 'Single';
               case Condition.Dual
                    name = 'Dual';
               case Condition.PerformMOT
                    name = 'PerformMOT';
               case Condition.PerformVWM
                    name = 'PerformVWM';
               case Condition.PerformBoth
                    name = 'PerformBoth';
               case Condition.MOTResponse
                    name = 'MOTResponse';
               case Condition.VWMResponse
                    name = 'VWMResponse';
               case Condition.MOT
                    name = 'MOT';
               case Condition.VWM
                    name = 'VWM';
           end
        end
    end
end