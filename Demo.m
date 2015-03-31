session_config.debug = 1;
session_config.InitialSpeed = 25;
session_config.doPractice = 1;
session_config.doTest = 0;
session_config.DotWidthScaleFactor = 1;
session_config.MinSepScaleFactor = 1.5;
session_config.NumTrialsPerCondition = 4;
session_config.NumPracticeTrialsPerCondition = 4;
session_config.TestConditionTypes = [Condition.PerformMOT Condition.PerformVWM Condition.PerformBoth Condition.PerformBoth];
session_config.NumVWMObjects = 4;

StartSession('Demo', session_config);