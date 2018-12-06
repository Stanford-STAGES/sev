function didExport = export_psd(sourceFilename, destFilename, params, varargin)

    % initialize default parameters
    defaultParams.channelLabel = 'C3-M2';
    defaultParams.sleepCategory = 'all';  % {'wake','stage1','stage2','stage3_4','REM','allSleep','wake_before_sleep','wake_after_sleep','wake_after_sleeponset'};
    % wake_before_sleep
    % defaultParams.excludeArtifact = 'yes'; %{ 'yes','no', 'yesno','both'}
    defaultParams.minStageDuration_sec = 90;    
    defaultParams.minDuration_sec = 30;  % now update this to look at at least 3 epochs.
    defaultParams.minShaveTime_sec = 30;  % and shave off the leading and trailing epochs.
    
    
    % return default parameters if no input arguments are provided.
    if(nargin==0)
        didExport = defaultParams;
    else
        didExport = false;
        if(exist(sourceFilename,'file'))
            if(nargin<2 || isempty(params))
                
                pfile =  strcat(mfilename('fullpath'),'.plist');
                
                if(exist(pfile,'file'))
                    %load it
                    params = plist.loadXMLPlist(pfile);
                else
                    %make it and save it for the future
                    params = defaultParams;
                    plist.saveXMLPlist(pfile,params);
                end
            end
            if(exist(destFilename,'file'))
                delete(destFilename);
            end
            
            didExport = exist(destFilename,'file');
        end
    end
end

function exportPSDFiles(psgPathname, studyListFile)
    
    addpath('~/git/sev/auxiliary/');
    
    if(nargin<2)
        studyListFile = 'dmStudiesList.csv';
        if(nargin<1)
            psgPathname = '~/Data/sleep/dm/sev_output/PSD'; %'~/Data/sleep/dm/PSD/'; %'/Volumes/PATRIOT/dm/testing/PSD/';
            psgPathname = '~/Data/sleep/dm/sev_output/PSD_aggressive_artifact_deectors';
        end
    end
    
    % 'All' files include all header data found in the studyListFile
    % while the 'PSD' or 'lite' files only include the subjectID and
    % case/control groupings.
    exportAllPath = fullfile(pwd,'exportAll_aggressive');
    exportPSDPath = fullfile(pwd,'exportPSD_aggressive');
    
    if(~exist(exportAllPath,'dir'))
        mkdir(exportAllPath);
    end
    
    if(~exist(exportPSDPath,'dir'))
        mkdir(exportPSDPath)
    end
    
    estimate_types = {'psd','power','percent'};
    
    channelLabel = 'C3-M2';
    %     filenamePrefix =  {'wake','stage1','stage2','stage3_4','REM','allSleep'};
    %     stages = {0,1,2,[3,4],5,1:5};  %look or match these values for the corresponding stage label (e.g. fileNamePrefix).
    
    filenamePrefix =  {'wake','stage1','stage2','stage3_4','REM','allSleep','wake_before_sleep','wake_after_sleep','wake_after_sleeponset'};
    
    artifactLabels = {'has_artifact','artifact_removed'};
    artifactExcluded = {false, true};
    
    fidStudyList = fopen(studyListFile,'r');
    
    headerLine = fgetl(fidStudyList);
    
    demographicColumnNames = strsplit(headerLine,',');
    groupIDColumnName = demographicColumnNames{1};
    caseControlColumnName = demographicColumnNames{2};
    patidColumnName = demographicColumnNames{3};
    
    firstStudy = true;
    curPatID = '';
    while(~feof(fidStudyList))
        %         while(~strcmpi(curPatID,'SSC_2013_421') && ~feof(fidStudyList))
        curLine = fgetl(fidStudyList);
        [curPatID, curCaseControlValue, curGroupID] = getPatID(curLine);
        %         end
        psdFilename = fullfile(psgPathname, [curPatID,'.',channelLabel,'.psd.txt']);
        
        if(~exist(psdFilename,'file'))
            fprintf(1,'The following file is missing and will be skipped:\t%s\n',psdFilename);
            continue;
        else
            [psdData, psdSettings] = loadPSDFile(psdFilename);
            
            psdHeader = strrep(makeWhereInString(psdSettings.column_names,'string',false),'"','');
            
            psdStruct = getPSDStruct(psdData,psdSettings,filenamePrefix,artifactLabels,artifactExcluded);
            
            for e = 1:numel(estimate_types)
                estimate_type = estimate_types{e};
                
                for s=1:numel(filenamePrefix)
                    curPrefix = filenamePrefix{s};
                    for a=1:numel(artifactExcluded)
                        curFilename = sprintf('%s_%s_%s.csv',curPrefix,estimate_type,artifactLabels{a});
                        curPSDAllFullFilename = fullfile(exportAllPath,curFilename);
                        curPSDLiteFullFilename = fullfile(exportPSDPath,curFilename);
                        
                        if(firstStudy && exist(curPSDAllFullFilename,'file'))
                            delete(curPSDAllFullFilename);
                            fprintf('Removing previous copy of %s\n',curFilename);
                        end
                        if(firstStudy && exist(curPSDLiteFullFilename,'file'))
                            delete(curPSDLiteFullFilename);
                            %                     fprintf('Removing previous copy of %s\n',curFilename);
                        end                        
                        stagePSDFid = fopen(curPSDAllFullFilename,'a');
                        if(stagePSDFid<0)
                            errMsg = sprintf('Could not append to %s',curFilename);
                            throw(MException('MATLAB:FID',errMsg));
                        else
                            if(firstStudy) %we need to put a header in the first time.
                                fprintf(stagePSDFid,'%s, %s\n',headerLine,psdHeader);
                            end                            
                            curPSDLine = makeWhereInString(psdStruct.(estimate_type).(filenamePrefix{s}).(artifactLabels{a}),'numeric',false);
                            fprintf(stagePSDFid,'%s, %s\n',curLine, curPSDLine);
                            fclose(stagePSDFid);
                            
                            stagePSDLiteFid = fopen(curPSDLiteFullFilename,'a');
                            if(stagePSDLiteFid<0)
                                errMsg = sprintf('Could not append to %s (lite)',curFilename);
                                throw(MException('MATLAB:FID',errMsg));
                            else
                                if(firstStudy) %we need to put a header in the first time.
                                    fprintf(stagePSDLiteFid,'%s, %s, %s, %s\n',patidColumnName,groupIDColumnName,caseControlColumnName,psdHeader);
                                end
                                
%                                 curPSDLine = makeWhereInString(psdStruct.(estimate_type).(filenamePrefix{s}).(artifactLabels{a}),'numeric',false);
                                fprintf(stagePSDFid,'%s, %s, %s, %s\n',curPatID,curGroupID, curCaseControlValue, curPSDLine);
                                fclose(stagePSDLiteFid);
                            end
                        end
                    end
                end                
            end        
        end
        firstStudy = false;
    end
    
    fclose(fidStudyList);
    
    fprintf(1,'Export complete.\n');
    
end



%> @param psd_settings
%> - winlen_sec
%> - interval_sec 'fft interval (taken ever _ seconds)'
%> - samplerate 'final sample rate(hz)'
%> - spectrum_type
%> - u_psd
%> - u_power
function outputStruct = getPSDStruct(data, psd_settings, stageStringLabels,artifactLabels,artifactExcluded)
    % Algorithm to pullout at least 30 seconds or more each sleep stage
    % while separated from at least 15 seconds from a separate sleep stage.
    
    % Standardize artifact exclusion to the second cell index; swap them if
    % need be.
    if(artifactExcluded{1})
       tmp = artifactExcluded{1};
       artifactExcluded{1} = artifactExcluded{2};
       artifactExcluded{2} = tmp;
       
       tmpLabel  = artifactLabels{1};
       artifactLabels{1} = artifactLabels{2};
       artifactLabels{2} = tmpLabel;
    end
    
    minStageDuration_sec = 90;
    %     minDuration_sec = 30;
    %     minShaveTime_sec = 15;
    
    minDuration_sec = 30;  % now update this to look at at least 3 epochs.
    minShaveTime_sec = 30;  % and shave off the leading and trailing epochs.
    
    winlen_sec = psd_settings.winlen_sec;
    interval_sec = psd_settings.interval_sec;
    samplerate = psd_settings.samplerate;
    U_psd = psd_settings.u_psd;
    U_power = psd_settings.u_power;
    
    windows2shave = ceil(minShaveTime_sec/interval_sec);
    
    actualShaveTime_sec = windows2shave*interval_sec;  % time to cutoff on each side of the periodogram groups
    actualMinDuration_sec = minDuration_sec+2*actualShaveTime_sec;  % Turns out to be 90 seconds now
    
    columnNames = psd_settings.column_names;
    [~,maxFrequencyIndex] = max(str2double(columnNames));
    
    %     minFrequencyToDisplay = 0.75;
    %     minFrequencyToDisplayIndex = find(str2double(all_column_names)>=minFrequencyToDisplay,1,'first');
    
    stageIndex = strcmpi(columnNames,'S');
    artifactIndex = strcmpi(columnNames,'A');
    artifactIndices = data(:,artifactIndex)==true;
    
    %     column_names = psd_settings.column_names;
    %     stageStringLabels =  {'wake','stage1','stage2','stage3_4','REM','allSleep'};
    
    for s=1:numel(stageStringLabels)
        
        stageIndices = getStageIndices(data(:,stageIndex),stageStringLabels{s});        
        stageGroups = thresholdcrossings(stageIndices);        
        if(isempty(stageGroups))
            stagePSD = [];
            stagePower = [];
            stagePercentPower = [];
            
            artifactFreeStagePSD = [];
            artifactFreeStagePower = [];
            artifactFreeStagePercentPower = [];
        else
            stageGroupDuration_sec = (stageGroups(:,2)-stageGroups(:,1))*interval_sec + (winlen_sec-interval_sec);
            okayStages = stageGroupDuration_sec >= actualMinDuration_sec;
            okayStageDurationTotal_sec = sum(stageGroupDuration_sec(okayStages));
            
            validStageGroups = stageGroups(okayStages,:);
            stageIndices = PAData.unrollEvents(validStageGroups,numel(stageIndices));
            %             stageIndices = stageIndices(okayIndices);
            
            artifactRemovedIndices = stageIndices & ~artifactIndices;
            artifactFreeStageDurationSec = sum(artifactRemovedIndices)*interval_sec+(winlen_sec-interval_sec);
            
            if(okayStageDurationTotal_sec>=minStageDuration_sec)
                meanData =mean(data(stageIndices,1:maxFrequencyIndex));
                stagePSD = meanData/(U_psd*samplerate);
                stagePower = meanData/U_power;
                
                stagePercentPower = meanData/sum(meanData,2)*100;
            else
                stagePSD = [];
                stagePower = [];
                stagePercentPower = [];
            end
            
            if(artifactFreeStageDurationSec>=minStageDuration_sec)
                meanData = mean(data(artifactRemovedIndices,1:maxFrequencyIndex));
                artifactFreeStagePSD = meanData/(U_psd*samplerate);
                artifactFreeStagePower = meanData/U_power;               
                artifactFreeStagePercentPower = meanData/sum(meanData,2)*100;
            else
                artifactFreeStagePSD = [];
                artifactFreeStagePower = [];
                artifactFreeStagePercentPower = [];
            end
        end
        
        % this means that we exclude artifacts in the second case
        outputStruct.psd.(stageStringLabels{s}).(artifactLabels{1}) = stagePSD;
        outputStruct.power.(stageStringLabels{s}).(artifactLabels{1}) = stagePower;
        outputStruct.percent.(stageStringLabels{s}).(artifactLabels{1}) = stagePercentPower;
        
        outputStruct.psd.(stageStringLabels{s}).(artifactLabels{2}) = artifactFreeStagePSD;
        outputStruct.power.(stageStringLabels{s}).(artifactLabels{2}) = artifactFreeStagePower;
        outputStruct.percent.(stageStringLabels{s}).(artifactLabels{2}) = artifactFreeStagePercentPower;
    end
end

function [data, psd_settings] = loadPSDFile(psdFilename)
    %> @retval data is a cell array of cells. The outer cell contains the same number
    %> of elements as files found in the pathname directory.
    %> The next inner cell array contains as many columns as found in each file
    %> (same number as the number of elements in column_names).
    %> The innermost values at this point correspond to the rows found in each
    %> column and represent the time-ordered power density values.
    %> @retval psd_settings A struct with the settings from the psd files.  Fields
    %> include:
    %> - channel
    %> - winlen_sec 
    %> - interval_sec 'fft interval (taken ever _ seconds)'
    %> - samplerate 'final sample rate(hz)'
    %> - spectrum_type
    %> - u_psd
    %> - u_power
    %> - column_names The column headers found in the first non-# delimited
    %> row of the input file
    %
    % files is a structure array corresponding to the filenames of where the data in
    % each cell of data (output variable) was pulled from.
    %
    % Hyatt Moore IV
    % October 23, 2010
    %> @note Example PSD header content:
    %> - #Power Spectral Density values from FFTs with the following parameters: (Batch ID: 2016Aug05_17_32_52)
    %> - #	CHANNEL:	C3-x
    %> - #	window length (seconds):	6.0
    %> - #	FFT length (samples):	600
    %> - #	FFT interval (taken every _ seconds):	3.0
    %> - #	Initial Sample Rate(Hz):	100
    %> - #	Final Sample Rate(Hz):	100
    %> - #	Spectrum Type:	none
    %> - #	U_psd:	225.375000
    %> - #	U_power:	90300.250000
    %> - 0.0 	0.2 	0.4 	0.6 	0.8 	1.0 	1.2 	1.4 	1.6 	1.8 	2.0 	2.2 	2.4 	2.6	...	49.8	50.0	Slow	Delta	Theta	Alpha	Sigma	Beta	Gamma	Mean0_30	Sum0_30	A	A_type	S	E
    
    delimiter = '#';
    
    fprintf(1,'Parsing %s\n',psdFilename);
    fid = fopen(psdFilename,'r');
    
    hdr_data = fgetl(fid);
    % isempty(hdr_data) will get any empty lines
    while(isempty(hdr_data)||strcmp(hdr_data(1),delimiter))
        hdr_data = fgetl(fid);
        hdr_content = strsplit(hdr_data,':');
        switch(lower(strtrim(strrep(hdr_content{1},'#',''))))
            case 'channel'
                psd_settings.channel = strtrim(hdr_content{end});
            case 'window length (seconds)'
                psd_settings.winlen_sec = str2double(hdr_content{end});
            case 'fft interval (taken every _ seconds)'
                psd_settings.interval_sec = str2double(hdr_content{end});
            case 'final sample rate(hz)'
                psd_settings.samplerate = str2double(hdr_content{end});
            case 'spectrum type'
                psd_settings.spectrum_type = strtrim(hdr_content{end});
            case 'u_psd'
                psd_settings.u_psd = str2double(hdr_content{end});
            case 'u_power'
                psd_settings.u_power = str2double(hdr_content{end});
        end
    end
    
    all_column_names = regexp(hdr_data,'\s+','split');
    maxFrequencyToDisplay = 50; %change this if you want to show a smaller portion of the entire spectrum.
    minFrequencyToDisplay = 0.75;

    minFrequencyToDisplayIndex = find(str2double(all_column_names)>=minFrequencyToDisplay,1,'first');
    maxFrequencyToDisplayIndex = find(str2double(all_column_names)<=maxFrequencyToDisplay,1,'last');
    
    maxFrequencyIndex = find((max(str2double(all_column_names))==str2double(all_column_names)));
    numFrequencyFieldsAfterMaxDisplayFrequency = maxFrequencyIndex-maxFrequencyToDisplayIndex;  % there are ignored.
    
    column_names = all_column_names([minFrequencyToDisplayIndex:maxFrequencyToDisplayIndex,maxFrequencyIndex+1:end]);  %in case we show a subset of freqs, then we want to adjsut the column names displayed according to the subset.
    numMetaDataFields = numel(all_column_names)-maxFrequencyIndex;
    
    % Create the scan string expression, which is float for all
    % frequencies of interest, skipped floats for the non interested
    % frequencies, some floats for the meta data and the artifact flag,
    % an ignored string (%*s) for the artifact_type column, and then
    % floats for the remaing 'S'tage and 'E'poch columns
    scanStr = [repmat('%f\t',1,maxFrequencyToDisplayIndex),repmat('%*f\t',1,numFrequencyFieldsAfterMaxDisplayFrequency),repmat('%f\t',1,numMetaDataFields-3),'%*s\t%f\t%f'];
    
    column_names(strcmpi(column_names,'A_type'))=[]; %get rid of this column in the name since we have removed it at the end of our scanStr with %*s
    
    psd_settings.column_names = column_names;
%     psd_settings.U_psd = U_psd;
%     psd_settings.U_power = U_power;
%     psd_settings.samplerate = samplerate;
%     psd_settings.win_length_sec = win_length_sec;
%     psd_settings.fft_interval_sec = fft_interval_sec;
%     psd_settings.spectrum_type = spectrum_type;
    
    tic
    data = cell2mat(textscan(fid,scanStr));
    toc
    
    data = data(:,minFrequencyToDisplayIndex:end);
    
    fclose(fid);
end

function [patid, caseControlValue, groupingID] = getPatID(curLine)
    exp = '(\d+),(\d+),(\w+_\w+),.+';
    r=regexp(curLine,exp,'tokens');
    patid = r{1}{3};
    caseControlValue = r{1}{2};
    groupingID = r{1}{1};
end
