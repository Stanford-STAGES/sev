classdef CLASS_batchExport_figure < IN_FigureController

    properties(Constant)
        figureFcn = @batch_export;
    end
    properties(SetAccess=protected)
        playList;
        methodsStruct;
        pathStruct = struct();
        channelStruct = struct('labels',[],'selectedIndices',[]);
        exportInfFilename = 'export.inf';
    end
    methods
        function this =  CLASS_batchExport_figure(varargin)
            this = this@IN_FigureController(varargin{:});
            this.methodsStruct = CLASS_batch.getExportMethods();
            this.setInputPathname(this.userSettings.inputFolder);            
        end
        
        function methodStruct = getMethodSettings(this, optionalField)
            mInd = this.getExportMethodIndex();
            methodStruct.mfilename = this.methodsStruct.mfilename{mInd};
            methodStruct.editor = this.methodsStruct.settingsEditor{mInd};
            % methodStruct.settings = this.methodsStruct.settings{mInd};
            methodStruct.description = this.methodsStruct.description{mInd};
            methodStruct.requires = this.methodsStruct.requires{mInd};
            
            % psd_pathname, edf_pathname, edf_channel, edf_filename
            sp = strsplit(methodStruct.requires,'_');
            methodStruct.extType = lower(sp{1});
            if(numel(sp)>1)
                methodStruct.fcnInput = sp{2};
            else
                methodStruct.fcnInput = methodStruct.extType;
            end
            
            if(nargin>1 && isfield(methodStruct,optionalField))
                methodStruct = methodStruct.(optionalField);
            end
            
        end
        
        function uSet =  getUserSettings(this)            
           uSet = this.userSettings(); 
        end
        
        function updateInputPathname(this)
            fileExt = this.getMethodSettings('extType');
            inputPath = this.userSettings.inputFolder;
            extType = this.getMethodSettings('extType');
            
            this.pathStruct = CLASS_batch.checkPathForExts(inputPath,extType,this.playList);     
            
            this.channelStruct.labels = this.pathStruct.channelLabels;
            set(this.handles.text_files_to_process,'string',this.pathStruct.statusString);
            set(this.handles.edit_input_directory,'string',this.pathStruct.pathname);
            set(this.handles.push_input_directory,'string',[upper(fileExt), ' Directory'],...
                'callback',{@this.inputDirectoryCb,fileExt});
            this.updateWidgets();
        end
        
        function didSet = setInputPathname(this,inputPath)
            if(isdir(inputPath))
                this.userSettings.inputFolder = inputPath;
                this.updateInputPathname();
                this.channelStruct.selectedIndices = [];

                didSet = true;
            else
                didSet = false;
            end
        end
       
       function inputPathname = getInputPathname(this)
           inputPathname = get(this.handles.edit_input_directory,'string');
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
           
           channelSelection = [];
           if(~isempty(this.channelStruct.labels))               
               if(get(this.handles.radio_channelsAll,'value'))
                   channelSelection = this.channelStruct.labels;
               else
                   channelSelection = this.channelStruct.labels(this.channelStruct.selectedIndices);
               end
           end
           
           exportSettings.inputPathname = get(this.handles.edit_input_directory,'string');
           exportSettings.fileSelectionList = [];
           exportSettings.methodStruct = this.getMethodSettings(); 
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
           if(nargin<2)
               exportSettings = this.getExportSettings();
           end
           
           % pathStruct = CLASS_batch.checkPathForEDFs(exportSettings.edfPathname,exportSettings.edfSelectionList);
           
           fullfilenames = this.pathStruct.fullfilename_list;
           file_count = numel(fullfilenames);
           
           if(strcmpi(exportSettings.inputPathname,exportSettings.exportPathname))
               exportSettings.exportPathname = fullfile(exportSettings.inputPathname,'export');
               if(~isormkdir(exportSettings.exportPathname))
                   warndlg('Source and export paths should be different.  I tried to create an export folder in your source path to help you out, but it did not work :(');
                   return;
               end
           end
           
           if(strcmpi(exportSettings.methodStruct.fcnInput,'pathname'))
               try
                   didExport = CLASS_converter.exportFromPath(exportSettings.inputPathname,exportSettings.exportPathname,...
                       exportSettings.methodStruct,exportSettings.channelSelection);
                   if(didExport)
                       %                        dlgFcn = @msgbox;
                       %                        msg = 'Export complete';
                       dfs=get(groot,'DefaultUIControlFontSize');
                       set(groot,'DefaultUIControlFontSize',12);
                       respBtn = questdlg('Export complete','Export summary',...
                           'Close','See output folder','Close');
                       set(groot,'DefaultUIControlFontSize',dfs);
                       if(strcmpi(respBtn,'See output folder'))
                           openDirectory(exportSettings.exportPathname);
                       end
                                           

                   else
                       dlgFcn = @warndlg;
                       msg = 'The export did not complete!';
                       dlgFcn(msg);
                   end
                   
               catch me
                   showME(me);
                   dlgFcn = @errordlg;
                   msg = 'There were errors during export';
                   dlgFcn(msg);
               end          
               
           % We are exporting channels 'edf_channel' is the other option besides pathname right now.
           elseif(file_count>0)
                   
               % prep the waitbarHandle and make it look nice
               initializationString = sprintf('%s\n\tInitializing',this.pathStruct.statusString);
               waitbarH = CLASS_batch.createWaitbar(initializationString);
               
               files_attempted = zeros(size(fullfilenames));
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
                       
                       studyInfoStruct.filename = fullfilenames{i};
                       studyInfoStruct.edf_filename = studyInfoStruct.filename;
                       [studyInfoStruct.stages_filename, studyInfoStruct.edf_name] = CLASS_codec.getStagesFilenameFromEDF(studyInfoStruct.edf_filename);
                       %                        studyInfoStruct.edf_filename = fullfile(exportSettings.inputPathname,studyInfoStruct.edf_name);
                       [~, studyInfoStruct.study_name, studyInfoStruct.study_ext] = fileparts(studyInfoStruct.filename);
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
                           if(strcmpi('filename',exportSettings.methodStruct.requires))
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
                               [~,edfChannels] = loadEDF(studyInfoStruct.edf_filename,exportSettings.channelSelection);
                               
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
               CLASS_batch.showCloseOutMessage(this.pathStruct.filename_list,files_attempted,files_completed,files_failed,files_skipped,start_time);
           else
               warndlg(sprintf('The check for EDFs in the following directory failed!\n\t%s',exportSettings.edfPathname));
           end
           
       end
    end
    methods(Access=protected)
        
        function ind= getExportMethodIndex(this)          
            ind = get(this.handles.menu_export_method,'value');
        end
        
        function initWidgetSettings(this)
            this.methodsStruct = CLASS_batch.getExportMethods();
            
            % export methods
            set([this.handles.push_method_settings
                this.handles.menu_export_method],'enable','on');
            
            selectionInd = this.userSettings.methodIndex;
            set(this.handles.menu_export_method,'string',this.methodsStruct.label,'value',selectionInd,...
                'tooltipstring',this.methodsStruct.description{selectionInd},'fontsize',12);
            
            
            % edf directory
            set(this.handles.push_input_directory,'enable','on');  
            set(this.handles.text_files_to_process,'enable','off','string','');
            set(this.handles.edit_input_directory,'enable','inactive','string','');

            
            % file selection
            set(this.handles.edit_selectPlayList,'hittest','on','enable','inactive');
            bgColor = get(this.handles.panel_file_selection,'backgroundcolor');
            set(this.handles.radio_processAll,'value',1);
            set([this.handles.radio_processAll;
                this.handles.radio_processList;
                this.handles.edit_selectPlayList],'enable','off');
            set([this.handles.radio_processAll;
                this.handles.radio_processList],'backgroundcolor',bgColor);            
            
            % channel selection
            bgColor = get(this.handles.panel_channel_selection,'backgroundcolor');
            set(this.handles.radio_channelsAll,'value',1);
            set([this.handles.radio_channelsAll;
                 this.handles.radio_channelsSome;                 
                 this.handles.button_selectChannels],'enable','off');
            set([this.handles.radio_channelsAll;
                 this.handles.radio_channelsSome],'backgroundcolor',bgColor);
            
            try
                exportPath = this.userSettings.outputFolder;                
                if(~exist(exportPath,'file') || (~isempty(exportPath) && exportPath(1)=='.'))
                    exportPath = pwd;
                    this.userSettings.outputFolder = exportPath;
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
            set(this.handles.push_input_directory,'callback',{@this.inputDirectoryCb,''});
            % set(this.handles.edit_input_directory,'callback',@this.edit_edf_directory_Callback);
            set(this.handles.button_selectChannels,'callback',@this.selectChannelsCb);
            set(this.handles.push_method_settings,'callback',@this.settingsCb);
            set(this.handles.menu_export_method,'callback',@this.methodChangeCb);
            set(this.handles.edit_selectPlayList,'buttondownfcn',@this.edit_selectPlayList_ButtonDownFcn);
            set(this.handles.panel_file_selection,'selectionchangedfcn',@this.panel_file_selection_SelectionChangeFcn);            
            set(this.handles.push_export_directory,'callback',@this.push_export_directory_Callback);
            set(this.handles.push_start,'callback',@this.startCb);
            initWidgetCallbacks@IN_FigureController(this);  % get the close request ones
        end
        
        function updateWidgets(this)
            
            %this.handles.push_start;
            fileRelevantHandles = [                
                this.handles.text_files_to_process                
                get(this.handles.panel_file_selection,'children')
                this.handles.edit_selectPlayList                
                ];
            
            extType = this.getMethodSettings('extType');
            canStart = numel(this.pathStruct.filename_list)>0;
            switch(extType)
                case 'psd'
                    set(fileRelevantHandles,'enable','off');
                    if(~isempty([]))
                         set(get(this.handles.panel_channel_selection,'children'),'enable','on');
                    end
                case 'edf'
                    if(~isempty(this.channelStruct.labels))            
                        set(fileRelevantHandles,'enable','on'); 
                    end                    
                otherwise            
                    canStart = true;
                    set(fileRelevantHandles,'enable','off');
            end
            if(~isempty(this.channelStruct.labels))
                set(get(this.handles.panel_channel_selection,'children'),'enable','on');
            end
            if(canStart)
                set(this.handles.push_start,'enable','on');
            end
            
        end
        
        function methodChangeCb(this,hObject, ~)
            index = get(hObject,'value');
            toolTip = this.methodsStruct.description{index};
            this.userSettings.methodIndex = index;            
            set(this.handles.menu_export_method,'tooltipstring',toolTip); 
            
            this.updateInputPathname(); % fires update widgets
        end
        
        function settingsCb(this, varargin)    
            settings = this.getMethodSettings();
            infFilename = fullfile('+export/',this.exportInfFilename);
            feval(settings.editor,settings.mfilename, infFilename);
        end
        
        function selectChannelsCb(this,varargin)

            outputStruct = montage_dlg(this.channelStruct.labels,...
                this.channelStruct.selectedIndices);
            
            if(isempty(outputStruct))
                this.channelStruct.selectedIndices= [];
            else
                this.channelStruct.selectedIndices= outputStruct.channels_selected;
            end            
             
            % all or nothing ...
            if(~any(this.channelStruct.selectedIndices) || all(this.channelStruct.selectedIndices))
                set(this.handles.radio_channelsAll,'value',1);
            else
                set(this.handles.radio_channelsSome,'value',1);
            end
        end
        
        function inputDirectoryCb(this, varargin)

            inputPath = get(this.handles.edit_input_directory,'string');            
            if(~isdir(inputPath))
                inputPath = this.userSettings.inputFolder; 
            end            
            methodStruct = this.getMethodSettings();
            pathname = uigetfulldir(inputPath,sprintf('Select the directory containing %s files to process',methodStruct.extType));
            
            if(~isempty(pathname))
                this.setInputPathname(pathname);                
            end
        end
        
        function push_export_directory_Callback(this, varargin)
            methodStruct = this.getMethodSettings();
            exportPathname = get(this.handles.edit_export_directory,'string');
            exportPathname = uigetfulldir(exportPathname,sprintf('Select the directory containing %s files to process',methodStruct.extType));
            
            if(~isempty(exportPathname))
                set(this.handles.edit_export_directory,'string',exportPathname);
                this.userSettings.outputFolder = exportPathname; 
            end
        end

        function startCb(this, varargin)
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
                this.process_export(exportSettings);
            else
                warndlg(sprintf('Output path (%s) does not exist',outputPath));
            end
        end
        
        
        % --- Executes when selected object is changed in panel_file_selection.
        function panel_file_selection_SelectionChangeFcn(this, ~, eventdata, varargin)
            if(eventdata.NewValue==this.handles.radio_processList)
                tmpList = CLASS_batch.getPlayList(this.playList);                
                if(~isempty(tmpList))
                    this.playList = tmpList;
                    CLASS_batch.checkPathForEDFs(this.playList);
                end
            end
        end
        
        % --- If Enable == 'on', executes on mouse press in 5 pixel border.
        % --- Otherwise, executes on mouse press in 5 pixel border or over edit_selectPlayList.
        function edit_selectPlayList_ButtonDownFcn(this, varargin)            
            
            filenameOfPlayList = get(this.handles.edit_selectPlayList,'string');
            if(~exist(filenameOfPlayList,'file'))
                filenameOfPlayList = this.getInputPathname();
            end            
            
            [this.playList, filenameOfPlayList] = CLASS_batch.getPlayList(filenameOfPlayList,'-gui');
            
            %update the gui
            if(isempty(this.playList))
                set(this.handles.radio_processAll,'value',1);
                set(this.handles.edit_selectPlayList,'string','<click to select play list>');
            else
                this.setInputPathname(fileparts(filenameOfPlayList));
                set(this.handles.radio_processList,'value',1);
                set(this.handles.edit_selectPlayList,'string',filenameOfPlayList);
            end
            
            CLASS_batch.checkPathForEDFs(this.getInputPathname(),this.playList);
        end
    end

    methods (Static)
        function pStruct = getDefaults()
             [~, pStruct.exportInfFilename] = CLASS_batch.getExportMethods();
             pStruct.methodIndex = 1;
             pStruct.outputFolder = '.';
             pStruct.inputFolder = '.';
        end
    end
end