# Dual-task Multiple Object Tracking (MOT) & Visual Working Memory (VWM) Study

## Instructions
===============

Before starting the experiment be sure to update view_params at the top of StartSession.m to reflect the screen width and viewing distance of the computer used for the session. And be sure to add the 'core' and 'data' folders to the path.

Use StartSession to begin each session of the experiment:

    StartSession(subject_name, session_num, num_trials_per_condition)

The only required argument is subject_name. The name can only contain letters, numbers, or underscores. E.g.

    StartSession('mark_l')

The 2nd argument, session_num, specifies the number of sessions that will be run, one after the other. If the argument is not specified one session will be run. Finally, num_trials_per_condition specifies how many trials there will be percondition, per session. The default is 16. Thus the command above would execute one session with 16 trials per condition. However, the following would execute 3 sessions with 32 trials per condition:

    StartSession('mark_l', 3, 32)

Note that there are 4 conditions, but each condition is split across 2 blocks of half the number of trials. So the default setting of 16 trials per condition will execute 8 blocks of 8 trials each.

The participant will be guided through calibration if they have no done so already. It's possible to execute calibration separately (and individually for each task type), but that is not necessary if StartSession is used, unless calibration must be repeated. See the instructions below for details of the procedure.

By default a practice session will precede the test session each time StartSession is executed. However, if multiple sessions are specified there will be only one practice session. The practice session will involve 8 trials per condition (this should be sufficient, but can be modified in StartSession.m)

Results are saved after each session to a .mat file in the data folder with the participant's name. Make sure the name is unique to each participant.

### Calibration Instructions - MOT
==================================

Use StartMOTMCS to conduct MOT calibration for each participant. The only required argument is subject_name. The name can only contain letters, numbers, or underscores. E.g.

    StartMOTMCS('mark_l')

The calibration will be conducted in 2 stages each composed of 50 trials. In the first stage the tested speeds will be 6, 8, 10, 12, and 14. In the second stage the speeds will be more narrowly centred around the 75% correct threshold estimated from the results of the first stage. E.g., if performance is estimated to be 75% correct at a speed of 10, the speeds for the second stage will be 8, 9, 10, 11, and 12. 

After the second stage a speed will be suggested based on the results of both stages. That speed should result in performance around 70% correct.

It is possible that the first attempt at calibration will be unclear. After the first stage is complete you will see the suggested speed as well as a graph of performance for each speed tested. Performance should decrease with increasing speed. If this is not the case it might be best to repeat the calibration with different parameters. Do this using MOT_MCS:

    MOT_MCS(subject_name, num_trials, base_speed, speed_inc)

E.g.

    MOT_MCS('mark_l', 50, 5, 2)

This will test participant mark_l on 50 trials evenly distributed over speeds 1, 3, 5, 7, and 9. It will then display the estimated 75% threshold speed and a graph of performance for each speed. See MOT_MCS.m for more details.

### Calibration Instructions - VWM
==================================

The participant should have completed the MOT calibration first. Use StartVWMCS to conduct VWM calibration for each participant. The only required argument is subject_name. The name can only contain letters, numbers, or underscores. E.g.

    StartVWMMCS('mark_l')

The calibration will be conducted in 2 stages each composed of 50 and 60 trials respectively. In the first stage the participant will see 3, 4, 5, 6, or 7 VWM discs. There will be 4 MOT discs moving at the speed determined during MOT calibration. In the second stage the number of VWM discs will be more narrowly centred around the 75% correct threshold estimated from the results of the first stage. E.g., if performance is estimated to be 75% correct with 4 discs, the number of VWM discs displayed in the second stage will be 3, 4, and 5. 

After the second stage an estimate will be output of the number of discs that should result in performance around 70% correct.

After the first stage is complete you will see the threshold number of discs as well as a graph of performance for each number of discs. Performance should decrease with increasing disc count. If this is not the case it might be best to repeat the calibration with different parameters. Do this using VWM_MCS:

    VWM_MCS(subject_name, num_trials, disc_range, speed)

E.g.,

    VWM_MCS('mark_l', 60, 4:6, 10)

This will test participant mark_l on 60 trials with 4, 5, or 6 discs (with MOT discs moving at a speed of 10). The number of trials is set to 60 because the number of discs must be able to be evenly distributed over the 60 trials (i.e., 20 trials of each disc count). It will then display the estimated 75% threshold speed and a graph of performance for disc count. Note that the disc count should not be set to less than 3. See VWM_MCS.m for more details.

## Data Analysis
================

Use `analyse` to analyse the data for a participant. E.g:

    [raw_data, stats, anovatab] = analyse('mark_l');

This will display a graph of the performance for each condition for all sessions. Error bars represent 95% confidence intervals. It will also return the results of inferential tests.

You analyse a subset of sessions, e.g., if you need to see the performance for a single session:

    [raw_data, stats, anovatab] = analyse('mark_l', 4);

Or for a range of sessions:

    [raw_data, stats, anovatab] = analyse('mark_l', 1:7);

To analyse the data for all participants at once, leave out the participant name:

    [raw_data, stats, anovatab] = analyse();

To analyse a subset of sessions for all participants, enter an empty array instead of the subject name and then specify the sessions:

    [raw_data, stats, anovatab] = analyse([], 1:5);

### Return values

'raw_data' contains a table for each participant. Each table contains the raw data captured during the experiment. Each row of the table is one observation of:
  session       - The session in which the observation was made
  condition     - Which tasks were performed, MOT, VWM, or Both.
  correct       - Whether or not the response was correct
  response_type - Whether the observer was to make an MOT or a VWM response
  valid_probe   - Whether or not the probe was placed on a valid target
  speed         - The speed at which the MOT discs moved
  vwm_discs     - The number of VWM discs

'stats' contains summaries and the results of statistical analyses.
  name          - The observer's name (or 'Group' for the aggregate analyses)
  avg           - Mean correct per condition (MOT only, MOT dual, VWM only, VWM dual)
  ci            - 95% confidence interval per condition (upper and lower values)
  comparisons   - Results of planned comparisons (t-test for aggregate data and logistic regression for each observer)
  samples_size  - Number of observations per condition

'anovatab' contains the results of a two-way task (MOT, VWM) by load (single, dual) ANOVA of all observers' mean accuracy 