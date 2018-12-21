function didExport = export_psd(sourcePath, exportPath, params, varargin)
    addpath('~/git/matlab/auxiliary'); % for makeWhereInString method
    addpath('~/git/padaco/'); % for PAData.unrollEvents method
    
    % initialize default parameters
    defaultParams.channelLabel = 'all';
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
        if(isdir(sourcePath))
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
            params.playList = 'dmStudiesList.csv';
            
            if(isnan(params.channelLabel))
                params.channelLabel = 'all';
            end
            
            if(numel(varargin)>0 && ~isempty(varargin{1}))
                params.channelLabel = varargin{1};
            end
            
            didExport = exportPSDFiles(sourcePath, exportPath, params);
        end
    end
end

function canExport = exportPSDFiles(psdPathname, exportPath, params)

    estimate_types = {'psd','power','percent'};
    
    filenamePrefix =  {'wake','stage1','stage2','stage3_4','REM','allSleep','wake_before_sleep','wake_after_sleep','wake_after_sleeponset'};
    
    filenamePrefix = {'wake_before_sleep','wake'};
    
    
    
    artifactLabels = {'has_artifact','artifact_removed'};
    artifactExcluded = {false, true};
    % studyListFile = params.playList;
    
    playlist = [];
    pathStruct = CLASS_batch.checkPathForExts(psdPathname,'psd',playlist);
    if(~iscell(params.channelLabel))
        params.channelLabel = {params.channelLabel};
    end
    
    if(any(strcmpi(params.channelLabel,'all')))
        params.channelLabel = pathStruct.channelLabels;
    end
    
    canExport = numel(pathStruct.filename_list)>0 && ~isempty(intersect(params.channelLabel,pathStruct.channelLabels));
    
    if(canExport)
        
        
        
        %% 'All' files include all header data found in the studyListFile
        % exportAllPath = fullfile(exportPath,'All');
        % if(~exist(exportAllPath,'dir'))
        %   mkdir(exportAllPath);
        % end
        
        %% 'PSD' or 'lite' files only include the subjectID and case/control groupings.
        exportPSDPath = fullfile(exportPath,'PSD');
        if(~exist(exportPSDPath,'dir'))
            mkdir(exportPSDPath)
        end

        patidColumnName = 'ID';
        groupIDColumnName = 'Group';
        caseControlColumnName = 'Case/Control';
                
        
        %     filenamePrefix =  {'wake','stage1','stage2','stage3_4','REM','allSleep'};
        %     stages = {0,1,2,[3,4],5,1:5};  %look or match these values for the corresponding stage label (e.g. fileNamePrefix).

        %% Loop through all studies
        tic
        for ch = 1:numel(params.channelLabel)
            firstStudy = true;
            channelLabel = params.channelLabel{ch};
            fprintf(1,'Exporting %s power spectrum.\n',channelLabel);
            
            exportPSDChannelPath = fullfile(exportPSDPath,channelLabel);
            if(~isormkdir(exportPSDChannelPath))
                fprintf(1,'Unable to make output folder %s - skipping\n',exportPSDChannelPath);
                continue;
            end
            for f=1:numel(pathStruct.basenames)
                curPatID = pathStruct.basenames{f};
                psdFilename = fullfile(psdPathname, [curPatID,'.',channelLabel,'.psd.txt']);
                
                if(~exist(psdFilename,'file'))
                    fprintf(1,'The following file is missing and will be skipped:\t%s\n',psdFilename);
                    continue;
                else
                    [psdData, psdSettings] = CLASS_codec.loadPSDFile(psdFilename);
                    
                    if(firstStudy)
                        % this will be frequency bins, slow, delta, theta,
                        % alpha, sigma, beta, gamma, mean0_30, sum0_30, a, s, e
                        removeColumns = {'Slow','Delta','Theta','Alpha','Sigma','Beta','Gamma','Mean0_30','Sum0_30','A','S','E'};
                        
                        psdHeader = strrep(makeWhereInString(psdSettings.column_names(1:end-numel(removeColumns)),'string',false),'"','');
                    end
                    psdStruct = CLASS_codec.getPSDStruct(psdData,psdSettings,filenamePrefix,artifactLabels,artifactExcluded);
                    
                    for e = 1:numel(estimate_types)
                        estimate_type = estimate_types{e};
                        
                        for s=1:numel(filenamePrefix)
                            curPrefix = filenamePrefix{s};
                            for a=1:numel(artifactExcluded)
                                curFilename = sprintf('%s_%s_%s.csv',curPrefix,estimate_type,artifactLabels{a});
                                
                                curPSDLiteFullFilename = fullfile(exportPSDChannelPath,curFilename);                                
                                if(firstStudy && exist(curPSDLiteFullFilename,'file'))
                                    delete(curPSDLiteFullFilename);
                                    %                     fprintf('Removing previous copy of %s\n',curFilename);
                                end
                                    
                                stagePSDLiteFid = fopen(curPSDLiteFullFilename,'a');
                                if(stagePSDLiteFid<0)
                                    errMsg = sprintf('Could not append to %s (lite)',curFilename);
                                    throw(MException('MATLAB:FID',errMsg));
                                else
                                    if(firstStudy) %we need to put a header in the first time.
                                        %fprintf(stagePSDLiteFid,'%s, %s, %s, %s\n',patidColumnName,groupIDColumnName,caseControlColumnName,psdHeader);
                                        fprintf(stagePSDLiteFid,'# %s, %s\n',patidColumnName,psdHeader);
                                    end
                                    curPSD = psdStruct.(estimate_type).(filenamePrefix{s}).(artifactLabels{a});
                                    if(~isempty(curPSD))
                                        curPSDLine = makeWhereInString(curPSD,'numeric',false);
                                        fprintf(stagePSDLiteFid,'%s, %s\n',curPatID, curPSDLine);
                                    else
                                        
                                    end
                                    fclose(stagePSDLiteFid);
                                end
                                
                            end
                        end
                    end
                    firstStudy = false;
                end
            end
        end
        fprintf(1,'Export complete.\n');
        toc
    end
end

function [patid, caseControlValue, groupingID] = getPatID(curLine)
    exp = '(\d+),(\d+),(\w+_\w+),.+';
    r=regexp(curLine,exp,'tokens');
    patid = r{1}{3};
    caseControlValue = r{1}{2};
    groupingID = r{1}{1};
end

