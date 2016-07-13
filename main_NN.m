%% initialize program
rmpath([relativePath,'/src/outage_scheduling']); %some functions are shared
%between NN and outageSechduling, so just remove the path of the opposite program
warning off
configuration
set_global_constants()
run('get_global_constants.m')
prefix_num = 1;
if(~strcmp(config.run_mode,'optimize'))
    %% When evaluating - load DB file first!
    % mat_file_path =  '~/mount/PSCC16_continuation/current_version/saved_runs/BDB_build_run_2016-06-02-18-04-49--case24';
    % load([mat_file_path,'/hermes_build_db.mat'],'fullRemoteParentDir');
    db_file_path = [full_localRun_dir,'/',config.SAVE_FILENAME];
    fractionOfFinishedJobs=0.95;
end
%% cluster job configuration
jobArgs = set_job_args(prefix_num,config);
%% set test case params
caseName = 'case5'; %case5,case9,case14,case24,case96
params=get_testCase_params(caseName,config);
%% build directory structure
[job_dirname_prefix,full_localRun_dir,job_data_filename,job_output_filename...
    ,full_remoteRun_dir,full_tempFiles_dir] = build_dirs(prefix_num,config,caseName);
%% meta-optimizer iterations
N_jobs=50; %500
pauseDuration=60; %seconds
timeOutLimit=60*pauseDuration*48;
%% start by killing all current jobs
killRemainingJobs(jobArgs);
% pause(3);
for i_job=1:N_jobs
    %% build iteration dir
    relativeIterDir=['/',job_dirname_prefix,num2str(i_job)];
    localIterDir=[full_localRun_dir,relativeIterDir];
    remoteIterDir=[full_remoteRun_dir,relativeIterDir];
    mkdir(localIterDir);
    %% prepere job and send it to cluster
    display([datestr(clock,'yyyy-mm-dd-HH-MM-SS'),' - Sending job num ',num2str(i_job), '...']);
    [argContentFilename] = perpareJobDir(localIterDir,i_job,job_data_filename,params);
    [funcArgs,jobArgs]= perpareJobArgs(i_job,localIterDir,argContentFilename,remoteIterDir,jobArgs);
    if(strcmp(config.run_mode,'optimize'))
        sendJob('build_NN_db_job',funcArgs,jobArgs);
    else 
         %this is a hack - we refer all jobs to the same file.
         %fullLocalParentDir is loaded from previous run
         funcArgs.argContentFilename = db_file_path; % this will be the 2nd argument to test_UC_NN_error_job
         sendJob('test_UC_NN_error_job',funcArgs,jobArgs);
    end
end
mostFinished=0;
jobsWaitingToFinish=N_jobs;
display([datestr(clock,'yyyy-mm-dd-HH-MM-SS'),' - ','Waiting for at least ', ...
    num2str(ceil(fractionOfFinishedJobs*jobsWaitingToFinish)),' of ',num2str(jobsWaitingToFinish),' jobs...']);
timeOutCounter=0;
numFinishedFiles=0;
%% wait for enough jobs to finish
while((~mostFinished && timeOutCounter<=timeOutLimit))
    pause(pauseDuration);
    [mostFinished,numFinishedFiles]= ...
        checkIfMostFinished(fractionOfFinishedJobs,jobsWaitingToFinish,fullLocalParentDir,job_output_filename);
    timeOutCounter=timeOutCounter+pauseDuration;
end
save([full_localRun_dir,'/',config.SAVE_FILENAME]);
%% after enough jobs finished - destroy remaining
display([num2str(timeOutCounter),' seconds passed. ','Num of finished files: ',num2str(numFinishedFiles)]);
killRemainingJobs(jobArgs);
deleteUnnecessaryTempFiles(tempFilesDir);
if(strcmp(config.run_mode,'optimize'))
    %% extract and build database
    tic
    [final_db,sample_matrix,finished_idx] = extract_data(fullLocalParentDir,N_jobs,job_dirname_prefix,job_output_filename,params);
    toc
    split_dir = '/split_data';
    [split_data_loc,num_data_chunks] = splitAndSaveData(final_db,sample_matrix,fullLocalParentDir,split_dir);
    save([full_localRun_dir,'/',config.SAVE_FILENAME],'-regexp','^(?!(final_db|sample_matrix)$).');
else 
    %% extract and build database
    % mat_test_file_path =  '~/mount/PSCC16_continuation/current_version/saved_runs/BDB_test_run_2016-04-14-15-19-37--case24/hermes_test_db.mat';
    % load(mat_test_file_path,'fullLocalParentDir','N_jobs','JOB_DIRNAME_PREFIX','job_output_filename','params');
    % params.N_samples_test = 15;
    KNN=params.KNN;
    %%
    tic
    [final_db_test,finished_idx,uc_samples] = extract_data_test(fullLocalParentDir,N_jobs,JOB_DIRNAME_PREFIX,job_output_filename,params);
    toc
    save([full_localRun_dir,'/',config.SAVE_FILENAME]);
    %%
    plot_stats
end
%% test how feasible NN solutions are
% N_test = 1000;
% feasbility_test = zeros(N_test,1);
% mod_interval=50;
% state = getInitialState(params);
% isStochastic=1;
% for j=1:N_test
%     if(mod(j,mod_interval)==1)
%         display(['Test iteration ',num2str(j),' out of ',num2str(N_test)]);
%         tic
%     end
%     uc_sample.windScenario = generateWind(1:params.horizon,params,state,isStochastic);
%     uc_sample.demandScenario = generateDemand(1:params.horizon,params,state,isStochastic);
%     params.windScenario = uc_sample.windScenario;
%     params.demandScenario = uc_sample.demandScenario;
%     NN_uc_sample = get_uc_NN(final_db,sample_matrix,uc_sample);
%     feasbility_test(j) = check_uc_feasibility(NN_uc_sample.onoff,params);
%     if(mod(j,mod_interval)==0)
%         toc
%     end
% end
% mean(feasbility_test)