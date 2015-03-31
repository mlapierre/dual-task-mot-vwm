ConfigurePath();

session_config.debug = 1;
session_config.InitialSpeed = 15;
session_config.doPractice = 0;
session_config.doTest = 1;
session_config.DotWidthScaleFactor = 0.6;
session_config.MinSepScaleFactor = 0.6;
session_config.NumTrialsPerCondition = 16;
session_config.NumPracticeTrialsPerCondition = 4;
session_config.NumVWMObjects = 5;
session_config.NumMOTObjects = 10;
session_config.NumMOTTargets = 5;
session_config.VWMObjectDisplayTime = 0.2;
session_config.TestConditionTypes = [Condition.PerformMOT Condition.PerformVWM Condition.PerformBoth Condition.PerformBoth];
session_config.VWMObjectColours = [255 0 0; 0 255 0; 255 255 0; 0 0 255; 0 255 255; 128 64 0; 255 0 255; 128 0 255; 255 128 0; 128 128 64]';

session_config.session_num = 18;
num_blocks = 1;
data_set = 1;

StartSession('ML1', session_config, num_blocks, data_set);