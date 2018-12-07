classdef CLASS_batchExport_figure < IN_FigureController
    properties(Constant)
        figureFcn = @batch_export;
    end
    properties(SetAccess=protected)
        playList;
        methodsStruct;
        methodSelectionIndex = 1;
        edfData = struct('labels',[],'selectedIndices',[]);
        exportInfFilename = 'export.inf';
    end
    methods
        function this =  CLASS_batchExport_figure(varargin)
            this = this@IN_FigureController(varargin{:});
            this.methodsStruct = CLASS_batch.getExportMethods();
            this.updateWidgets();
        end
        

       function settingStruct = getMethodSettingsStruct(this)
           mInd = this.getExportMethodIndex();
           settingStruct.exportMethod = this.methodsStruct.mfilename{mInd};
           settingStruct.editor = this.methodsStruct.settingsEditor{mInd};
           settingStruct.curSettings = this.methodsStruct.settings{mInd};
           settingStruct.infFilename = this.methodsStruct.infFilename;
           settingStruct.infFilename = this.exportInfFilename;  
       end
       
       function didSet = setEDFPathname(this,edfPath)
           if(isdir(edfPath))
               this.userSettings.edfFolder = pathname; %update for the next time..
               set(this.handles.edit_input_directory,'string',pathname);
               set(this.handles.edit_input_directory,'string',edfPath);
               this.updateWidgets();               
               didSet = true;
           else
               didSet = false;
           end
       end
       function edfPathname = getEDFPathname(this)
           edfPathname = get(this.handles.edit_input_directory,'string');
       end

       
       %==========================================================================
       %> @brief Retrieves user configured export settings from the gui as a struct.
       %--------------------------------------------------------------------------
       %> @param Handles to the GUI.
       %> @retval exportSettings is a struct with the following fields
       %> - @c edfPathname Pathname containing EDF files to process.
       %> - @c edfSelectionList Cell of EDF names to use.  Can be empty for all.
       %> - @c methodStruct
       %> -- @c mfilename
       %> -- @c description
       %> -- @c settings
       %> - @c channel_selection
       %> -- @c all True/False If true, then load all channels for each file.
       %> (Optional, Default is True).
       %> -- @c sources Cell of channel labels to use if @c all is false.
       %> - @c exportPathname The path to save export data to.
       %==========================================================================
       function exportSettings = getExportSettings(this)
           
           method_selection_index = get(this.handles.menu_export_method,'value');
           methodFields = fieldnames(this.methodsStruct);
           for m=1:numel(methodFields)
               fname = methodFields{m};
               methodStruct.(fname) = this.methodsStruct.(fname){method_selection_index};
           end
           channelSelection.all = get(this.handles.radio_channelsAll,'value');
           channelSelection.source = this.edfData.labels(this.edfData.selectedIndices);
           
           exportSettings.edfPathname = get(this.handles.edit_input_directory,'string');
           exportSettings.edfSelectionList = [];
           exportSettings.methodStruct = methodStruct;
           exportSettings.channelSelection = channelSelection;
           exportSettings.exportPathname = get(this.handles.edit_export_directory,'string');
           
       end
       
       %==========================================================================
       %> @brief This method controls the batch export process according to the
       %> settings provided.
       %--------------------------------------------------------------------------
       %> @param exportSettings is a struct with the following fields
       %> - @c edfPathname
       %> - @c edfPathname Pathname containing EDF files to process.
       %> - @c edfSelectionList Cell of EDF names to use.  Can be empty for all.
       %> - @c methodStruct
       %> -- @c mfilename
       %> -- @c description
       %> -- @c settings
       %> - @c channelSelection
       %> -- @c all True/False If true, then load all channels for each file.
       %> (Optional, Default is True).
       %> -- @c sources Cell of channel labels to use if @c all is false.
       %> @param playList Optional Px1 cell of EDF filenames (not full filenames) to
       %> process from edfPath instead of using all .EDF files found in edfPath.
       %> - @c exportPathname The path to save export data to.
       %==========================================================================
       function process_export(this, exportSettings)
           
           edfSelectionStruct = CLASS_batch.checkPathForEDFs(exportSettings.edfPathname,exportSettings.edfSelectionList);
           edf_fullfilenames = edfSelectionStruct.edf_fullfilename_list;
           file_count = numel(edf_fullfilenames);
           
           if(strcmpi(exportSettings.edfPathname,exportSettings.exportPathname))
               exportSettings.exportPathname = fullfile(exportSettings.edfPathname,'export');
               if(~isormkdir(exportSettings.exportPathname))
                   warndlg('EDF path and export path should be different.  I tried to create an export folder in your EDF path to help you out, but it did not work :(');
                   return;
               end
           end
           
           if(strcmpi(exportSettings.methodStruct.mfilename,'export_selected_channels') && ...
                   exportSettings.channelSelection.all)
               warndlg(sprintf('Will not export selected channels if all channels are selected.\nTry again with a subsection of the channels.\n'));
               return;
           end
           
           if(file_count>0)
               
               % prep the waitbarHandle and make it look nice
               initializationString = sprintf('%s\n\tInitializing',edfSelectionStruct.statusString);
               waitbarH = CLASS_batch.createWaitbar(initializationString);
               
               files_attempted = zeros(size(edf_fullfilenames));
               files_completed = files_attempted;
               files_failed  = files_attempted;
               files_skipped = files_attempted;
               
               start_clock = clock;  %for etime
               start_time = now;
               timeMessage =sprintf('(Time: 00:00:00\tRemaining: ?)');
               
               for i=1:file_count
                   
                   try
                       fileStartTime = tic;
                       
                       studyInfoStruct = [];  % initialize to empty.
                       
                       studyInfoStruct.edf_filename = edf_fullfilenames{i};
                       [studyInfoStruct.stages_filename, studyInfoStruct.edf_name] = CLASS_codec.getStagesFilenameFromEDF(studyInfoStruct.edf_filename);
                       
                       [~, studyInfoStruct.study_name, studyInfoStruct.study_ext] = fileparts(studyInfoStruct.edf_filename);
                       files_attempted(i)=1;
                       status = sprintf('%s (%i of %i)',studyInfoStruct.edf_name,i,file_count);
                       waitbar(i/(file_count+1),waitbarH,status);
                       
                       %require stages filename to exist.
                       if(isempty(studyInfoStruct.stages_filename) || ~exist(studyInfoStruct.stages_filename,'file'))
                           files_skipped(i) = true;
                           status = sprintf('%s (%i of %i)\nStage file not found!  Skipping!',studyInfoStruct.edf_name,i,file_count);
                           waitbar(i/(file_count+1),waitbarH,status);
                       else
                           didExport = false;
                           if(strcmpi('filename',studyInfoStruct.requires))
                               if(strcmpi(exportSettings.methodStruct.mfilename,'export_selected_channels'))
                                   status = sprintf('%s (%i of %i)',studyInfoStruct.study_name,i,file_count);
                                   waitbar(i/(file_count+0.9),waitbarH,status);
                                   
                                   fullDestFile = fullfile(exportSettings.exportPathname,[studyInfoStruct.study_name,studyInfoStruct.study_ext]);
                                   
                                   didExport = CLASS_converter.writeLiteEDF(studyInfoStruct.edf_filename,fullDestFile,exportSettings.channelSelection.source); %,exportSamplerate);
                               else
                                   didExport = CLASS_converter.exportFromFile(studyInfoStruct.edf_filename,exportSettings.methodStruct,stagesStruct,studyInfoStruct);
                               end
                           else
                               
                               %% Load header
                               studyInfoStruct.edf_header = loadEDF(studyInfoStruct.edf_filename);
                               status = sprintf('%s (%i of %i)\nLoading hypnogram (%s)',studyInfoStruct.edf_name,i,file_count,studyInfoStruct.stages_filename);
                               waitbar(i/(file_count+0.9),waitbarH,status);
                               
                               sec_per_epoch = 30;
                               studyInfo.num_epochs = studyInfoStruct.edf_header.duration_sec/sec_per_epoch;
                               
                               %% load stages
                               stagesStruct = CLASS_codec.loadSTAGES(studyInfoStruct.stages_filename,studyInfo.num_epochs);
                               
                               status = sprintf('%s (%i of %i)\nLoading channels from EDF\n%s',studyInfoStruct.edf_name,i,file_count,timeMessage);
                               waitbar(i/(file_count+0.75),waitbarH,status);
                               
                               %% Load EDF channels
                               if(exportSettings.channelSelection.all)
                                   [~,edfChannels] = loadEDF(studyInfoStruct.edf_filename);
                               else
                                   fprintf(1,'exportSettings.channelSelection.sources has not been tested!\n');
                                   [~,edfChannels] = loadEDF(studyInfoStruct.edf_filename,exportSettings.channelSelection.sources);
                               end
                               
                               status = sprintf('%s (%i of %i)\nApplying export method(s)',studyInfoStruct.edf_name,i,file_count);
                               waitbar(i/(file_count+0.4),waitbarH,status);
                               
                               %% obtain event file name
                               studyInfoStruct.events_filename = CLASS_codec.getEventsFilenameFromEDF(studyInfoStruct.edf_filename);
                               
                               %% obtain export data
                               exportData = CLASS_batch.getExportData(edfChannels,exportSettings.methodStruct,stagesStruct,studyInfoStruct);
                               
                               %% export data to disk
                               
                               if(~isempty(exportData))
                                   status = sprintf('%s (%i of %i)\nSaving output to file',studyInfoStruct.edf_name,i,file_count);
                                   waitbar(i/(file_count+0.2),waitbarH,status);
                                   studyInfoStruct.saveFilename = fullfile(exportSettings.exportPathname,strcat(studyInfoStruct.study_name,'.mat'));
                                   save(studyInfoStruct.saveFilename,'exportData');
                                   exportData = []; %#ok<NASGU>
                                   files_completed(i) = true;
                                   didExport = true;
                               end
                           end
                           
                           if(didExport)
                               files_completed(i) = true;
                           else
                               files_failed(i) = true;
                           end
                           
                           
                           fileStopTime = toc(fileStartTime);
                           fprintf('File %d of %d (%0.2f%%) Completed in %0.2f seconds\n',i,file_count,i/file_count*100,fileStopTime);
                           fileElapsedTime = etime(clock,start_clock);
                           avgFileElapsedTime = fileElapsedTime/i;
                           
                           %                 num_files_completed = randi(1,0,100);
                           num_files_completed = i;
                           remaining_dur_sec = avgFileElapsedTime*(file_count-num_files_completed);
                           est_str = sprintf('%01ihrs %01imin %01isec',floor(mod(remaining_dur_sec/3600,24)),floor(mod(remaining_dur_sec/60,60)),floor(mod(remaining_dur_sec,60)));
                           
                           timeMessage = sprintf('(Time: %s\tRemaining: %s)',datestr(now-start_time,'HH:MM:SS'),est_str);
                           fprintf('%s\n',timeMessage);
                           
                           
                       end
                       
                   catch me
                       showME(me);
                       files_failed(i) = 1;
                   end
                   
               end
               
               %% Summary message and close out
               if(ishandle(waitbarH))
                   % This message will self destruct in 10 seconds
                   delete(waitbarH);
               end
               
               CLASS_batch.showCloseOutMessage(edfSelectionStruct.edf_filename_list,files_attempted,files_completed,files_failed,files_skipped,start_time);
               
           else
               warndlg(sprintf('The check for EDFs in the following directory failed!\n\t%s',exportSettings.edfPathname));
           end
           
       end
    end
    methods(Access=protected)
        
        function ind= getExportMethodIndex(this)          
            ind = get(this.handles.menu_export_method,'value');
        end
        
        function setExportMethodIndex(this,index)
            if(nargin<2)
                index = this.getExportMethodIndex();
            end
            this.methodSelectionIndex = index;
            set(this.handles.menu_export_method,'tooltipstring',this.methodsStruct.description{this.methodSelectionIndex});            
        end
        
        function initWidgetSettings(this)
            this.methodsStruct = CLASS_batch.getExportMethods();
            
            % edf directory
            set(this.handles.push_input_directory,'enable','on');  % start here.
            set([this.handles.edit_input_directory;
                this.handles.text_edfs_to_process],'enable','off');
            
            % file selection
            bgColor = get(this.handles.bg_panel_playlist,'backgroundcolor');
            set(this.handles.radio_processAll,'value',1);
            set([this.handles.radio_processAll;
                this.handles.radio_processList;
                this.handles.edit_selectPlayList],'enable','off');
            set([this.handles.radio_processAll;
                this.handles.radio_processList],'backgroundcolor',bgColor);
            
            % channel selection
            bgColor = get(this.handles.bg_channel_selection,'backgroundcolor');
            set(this.handles.radio_channelsAll,'value',1);
            set([this.handles.radio_channelsAll;
                this.handles.radio_channelsSome;
                this.handles.button_selectChannels],'enable','off');
            set([this.handles.radio_channelsAll;
                this.handles.radio_channelsSome],'backgroundcolor',bgColor);
            
            % export methods
            set([this.handles.push_method_settings
                this.handles.menu_export_method],'enable','off');
            set(this.handles.menu_export_method,'string',this.methodsStruct.label,'value',1,'tooltipstring',this.methodsStruct.description{1},'fontsize',12);
            
            try
                exportPath =  this.userSettings.outputFolder;
                
                if(~exist(exportPath,'file'))
                    exportPath = pwd;
                end
            catch me
                showME(me);
                exportPath = pwd;
            end
            
            set(this.handles.edit_export_directory,'string',exportPath,'enable','inactive');
            set(this.handles.push_export_directory,'enable','on');
            
            % Start
            set(this.handles.push_start,'enable','off');
        end
        
        function initWidgetCallbacks(this)
            set(this.handles.push_input_directory,'callback',@push_edf_directory_Callback);
            set(this.handles.edit_input_directory,'callback',@edit_edf_directory_Callback);
            set(this.handles.edit_selectPlayList,'callback',@edit_selectPlaylist_ButtonDownFcn);
            set(this.handles.button_selectChannels,'callback',@selectChannels_Callback);
            set(this.handles.push_method_settings,'callback',@push_exportMethodSettings_Callback);
            set(this.handles.menu_export_method,'callback',@menu_exportMethodChangeCb);
            set(this.handles.edit_selectPlayList,'buttondownfcn',@edit_selectPlayList_ButtonDownFcn);
            set(this.handles.push_export_directory,'callback',@push_export_directory_Callback);
            set(this.handles.push_start,'callback',@push_start_Callback);
            initWidgetCallbacks@IN_FigureController(this);  % get the close request ones
        end
        
        function updateWidgets(this, edfPathStruct)
            if(nargin<2 || isempty(edfPathStruct))                
                edfPathStruct = CLASS_batch.checkPathForEDFs(this.userSettings.edfFolder);
            end
            set(this.handles.text_edfs_to_process,'string',edfPathStruct.statusString);
            set(this.handles.edit_input_directory,'string',edfPathStruct.edfPathname);
            relevantHandles = [this.handles.push_start
                this.handles.text_edfs_to_process
                this.handles.edit_input_directory
                get(this.handles.bg_channel_selection,'children')];
            if(~isempty(edfPathStruct.edf_filename_list))
                set(relevantHandles,'enable','on');                
                this.edfData.labels = edfPathStruct.firstHDR.label;
                this.edfData.selectedIndices = [];
                set(this.handles.edit_input_directory,'enable','inactive');      %alter this so I don't have to deal with callbacks or changes to the pathname via the edit widget, but still give some visual feedback to the effect that it is ready.         
            else
                set(relevantHandles,'enable','off');
            end
        end
        
        function menu_exportMethodChangeCb(this,hObject, ~)
            this.setExportMethodIndex(get(hObject,'value'));
        end
        
        function push_exportMethodSettings_Callback(this, varargin)    
            settings = this.getMethodSettingsStruct();
            feval(settings.editor,settings.exportMethod, settings.infFilename); %, settings.curSettings);
        end
        
        function selectChannels_Callback(this,varargin)
            userdata = this.edfData;
            outputStruct = montage_dlg(userdata.labels,userdata.selectedIndices);
            
            if(isempty(outputStruct))
                outputStruct.channels_selected= [];
            end
            userdata.selectedIndices = outputStruct.channels_selected;


            if(~any(userdata.selectedIndices))
                set(this.handles.radio_channelsAll,'value',1);
            else
                set(this.handles.radio_channelsSome,'value',1);
            end
        end
        
        function push_input_directory_Callback(this, varargin)

            edfPath = get(this.handles.edit_input_directory,'string');
            
            if(~isdir(edfPath))
                edfPath = this.userSettings.edfFolder; %the edf folder to do a batch job on.
            end
            
            pathname = uigetfulldir(edfPath,'Select the directory containing EDF files to process');
            
            if(~isempty(pathname))
                this.setEDFPathname(pathname);                
            end
        end
        
        function push_export_directory_Callback(this, varargin)
            
            exportPathname = get(this.handles.edit_export_directory,'string');
            exportPathname = uigetfulldir(exportPathname,'Select the directory containing EDF files to process');
            
            if(~isempty(exportPathname))
                set(this.handles.edit_export_directory,'string',exportPathname);
                this.userSettings.outputFolder = exportPathname; 
            end
        end

        function push_start_Callback(this, varargin)
            % hObject    handle to push_start (see GCBO)
            % eventdata  reserved - to be defined in a future version of MATLAB
            % handles    structure with handles and user data (see GUIDATA)
            %
            %This function can only be called when there a valid directory (one which
            %contains EDF files) has been selected.
            %This function grabs the entries from the GUI and puts them into a settings
            %struct which is then passed to the export function.
            exportSettings = this.getExportSettings();
            outputPath = exportSettings.exportPathname;
            if(exist(outputPath,'dir'))
                process_export(exportSettings);
            else
                warndlg(sprintf('Output path (%s) does not exist',outputPath));
            end
        end
        
        
        % --- Executes when selected object is changed in bg_panel_playList.
        function bg_panel_playList_SelectionChangeFcn(this, hObject, eventdata, varargin)
            if(eventdata.NewValue==handles.radio_processList)
                playList = getPlaylist(this.handles);
                if(isempty(playList))
                    playList = getPlaylist(this.handles,'-gui');
                end
                this.playList = playList;
                this.checkPathForEDFs(this.playList);
            end
        end
        
        % --- If Enable == 'on', executes on mouse press in 5 pixel border.
        % --- Otherwise, executes on mouse press in 5 pixel border or over edit_selectPlayList.
        function edit_selectPlayList_ButtonDownFcn(this, varargin)            
            
            filenameOfPlayList = get(this.handles.edit_selectPlayList,'string');
            if(~exist(filenameOfPlayList,'file'))
                filenameOfPlayList = this.getEDFPathname();
            end
            
            
            [this.playList, filenameOfPlayList] = CLASS_batch.getPlayList(filenameOfPlayList,'-gui');
            
            %update the gui
            if(isempty(this.playList))
                set(this.handles.radio_processAll,'value',1);
                set(this.handles.edit_selectPlayList,'string','<click to select play list>');
            else
                this.setEDFPathname(fileparts(filenameOfPlayList));
                set(this.handles.radio_processList,'value',1);
                set(this.handles.edit_selectPlayList,'string',filenameOfPlayList);
            end
            
            CLASS_batch.checkPathForEDFs(this.getEDFPathname(),this.playList);
        end

    end

    methods (Static)
        function pStruct = getDefaults()
             [~, pStruct.exportInfFilename] = CLASS_batch.getExportMethods();
             pStruct.selectedMethod = 1;
             pStruct.outputFolder = '';
             pStruct.edfFolder = '';
        end
    end
end