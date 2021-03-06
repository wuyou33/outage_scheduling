function [reliability,n1_matrix,connected] = evaluate_UC_reliability(uc_sample,params)
%% initialize
run('get_global_constants.m')
mpopt = mpoption('out.all', 0,'verbose', 0,'pf.alg','NR'); %NR(def), FDXB, FDBX, GS
% mpopt = mpoption('out.all', 0,'verbose', 0,'model','DC','opf.dc.solver', 'CPLEX');
% mpopt = mpoption('out.all', 0,'verbose', 0,'model','DC','opf.dc.solver', 'CPLEX','cplex.opts.output.clonelog',-1);
cont_list_length = params.nl;
sz = [cont_list_length,params.horizon];
reliability = zeros(1,params.horizon);
pf_success = zeros(sz);
pf_violation = zeros(sz);
pg_prec_violation = zeros(sz);
n1_matrix = zeros(sz);
connected=1;
AC = 1;
%% iterate on all hours of the day
for t = 1:params.horizon
    try
        updatedMpcase = get_hourly_mpcase( t , uc_sample.onoff , uc_sample.Pg , uc_sample.windSpilled , uc_sample.loadLost, ...
            uc_sample.demandScenario , uc_sample.windScenario , uc_sample.line_status, params , uc_sample.voltage_setpoints );
        %% if with no contingency it is not connected - finish
        i_branch=0;
        if((~checkConnectivity(updatedMpcase,params)))
            display('Not Connected for no contingencies!');
            connected=1; %currently drop the 'connected' concept. Always assume connected, and set reliability to be 0
            return;
        end
        %% N-1 criterion - N(=nl) possible single line outage
        for i_branch = 1:cont_list_length
            newMpcase=updatedMpcase;
            newMpcase.branch(i_branch,BR_STATUS)=0;
            if(~checkConnectivity(newMpcase,params))
                display(['Not Connected for ',num2str(i_branch)]);
                pfRes.success=0;
            elseif(sum(newMpcase.branch(:,BR_STATUS))==0)
                pfRes.success=0;
            else
                try
                    display('before');
                    pfRes=runpf(newMpcase,mpopt); %when chaning, also change mpopt and AC variables
                    display('after');
                catch  ME
                    warning(['Problem using runpf for t = ' num2str(t),' i_branch = ',num2str(i_branch)]);
                    msgString = getReport(ME);
                    display(msgString);
                    pfRes.success=0;
                    pf_violation(i_branch,t) = 1;
                    pf_success(i_branch,t) = 0;
                end
            end
            pf_success(i_branch,t)=pfRes.success;
            if(pfRes.success)
                idx=find(uc_sample.onoff(:,t));
                pg_prec_violation(i_branch,t)=sum(abs(pfRes.gen(idx,PG)-newMpcase.gen(idx,PG)))/sum(newMpcase.gen(idx,PG));
                pf_violation(i_branch,t)=pfConstraintViolation(pfRes,params,AC);
            end
        end
    catch ME
        warning(['Problem using evaluate_UC_reliability for t = ' num2str(t),' i_branch = ',num2str(i_branch)]);
        msgString = getReport(ME);
        display(msgString);
        pfRes.success=0;
        pf_violation(:,t) = 1;
        pf_success(:,t) = 0;
    end
    n1_matrix(:,t) = pf_violation(:,t) | (1-pf_success(:,t));
    reliability(t)=1-mean(pf_violation(:,t) | (1-pf_success(:,t)));
    % OPF case: i think there has to be no violation in case there's success
end
end

%consider using matpower bult-in function:
%function [Fv, Pv, Qv, Vv] = checklimits(mpc, ac, quiet)
function violation = pfConstraintViolation(pfRes,params,AC)
percentageTolerance=params.reliability_percentageTolerance; %how much of a percentage violation do we tolerate
[Fv, Pv] = checklimits(pfRes, AC, 1);
violation=1-(isempty(Fv.p) || max(Fv.p) <= percentageTolerance)*...
    (isempty(Pv.p) || max(Pv.p) <= percentageTolerance)*...
    (isempty(Pv.P) || max(Pv.P) <= percentageTolerance);
%Fv is flow violations, Fv.p is max flow percentage violations, Pv is
%generator violations (real power), Pv.p and Pv.P are upper and lower
%limit violations.
end

function updatedMpcase = get_hourly_mpcase( current_hour , onoff , Pg , windSpilled , loadLost , demandScenario , windScenario ...
    , line_status, params ,voltage_setpoints )
%% initialize
run('get_global_constants.m');
mpcase = params.mpcase;
updatedMpcase = mpcase;

%% remove objective
% updatedMpcase.gencost(:,2:end)=zeros(size(mpcase.gencost(:,2:end)));

%% set net demand
netDemand = demandScenario(:,current_hour) - (windScenario(:,current_hour) - windSpilled(:,current_hour)) - loadLost(:,current_hour);
% updatedMpcase.bus(:,PD) = max(netDemand,0); max with zero causes trouble,
% since in the uc calculation there is no max there and we do use the
% remaining wind, while here we don't (if we put the max)
updatedMpcase.bus(:,PD) = netDemand;


%% set generation commitment and levels
updatedMpcase.gen(:,GEN_STATUS) = onoff(:,current_hour);
updatedMpcase.gen(:,PG) = Pg(:,current_hour);
%% set voltage set points for case of runopf day-ahead plan - currently just for case96
if(~isempty(voltage_setpoints))
    updatedMpcase.gen(:,VG)=voltage_setpoints(:,current_hour);
end
%% set topology
updatedMpcase.branch(:,BR_STATUS)=line_status;
end
