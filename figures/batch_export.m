function varargout = batch_export(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @batch_export_OpeningFcn, ...
    'gui_OutputFcn',  @batch_export_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

end

% --- Executes just before batch_export is made visible.
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to batch_export (see VARARGIN)
function batch_export_OpeningFcn(hObject, eventdata, handles, settingStruct, varargin)
    
    
    if(nargin<4)
        settingStruct = struct('edf_older','.',...
            'output_folder','.');
    end
    handles.user.settings = settingStruct;
    [handles.user.methodsStruct, handles.user.exportInfFilename] = CLASS_batch.getExportMethods();
    
    guidata(hObject,handles);
    
    initializeSettings(hObject);
    initializeCallbacks(hObject)
    try
        edfPath = handles.user.settings.edf_folder; %the edf folder to do a batch job on.
        
        if(~exist(edfPath,'file'))
            edfPath = pwd;
        end
    catch me
        edfPath = pwd;
        showME(me);
    end
    
    updateGUI(CLASS_batch.checkPathForEDFs(edfPath),handles);
    
    % Update handles structure
    guidata(hObject, handles);
    uiwait(hObject);

end

function initializeSettings(hObject)    
    handles = guidata(hObject);

    % edf directory
    set(handles.push_edf_directory,'enable','on');  % start here.
    set([handles.edit_edf_directory;
        handles.text_edfs_to_process],'enable','off');
    
    
    % file selection
    bgColor = get(handles.bg_panel_playlist,'backgroundcolor');
    set(handles.radio_processAll,'value',1);
    set([handles.radio_processAll;
        handles.radio_processList;
        handles.edit_selectPlayList],'enable','off');
    set([handles.radio_processAll;
        handles.radio_processList],'backgroundcolor',bgColor);
    
    % channel selection
    bgColor = get(handles.bg_channel_selection,'backgroundcolor');
    set(handles.radio_channelsAll,'value',1);
    set([handles.radio_channelsAll;
        handles.radio_channelsSome;
        handles.button_selectChannels],'enable','off');
    set([handles.radio_channelsAll;
        handles.radio_channelsSome],'backgroundcolor',bgColor);
    
   
    % export methods
    set([handles.push_method_settings
        handles.menu_export_method],'enable','off');
    set(handles.menu_export_method,'string',handles.user.methodsStruct.description,'value',1);
    
    try
        exportPath = handles.user.settings.output_folder;
        
        if(~exist(exportPath,'file'))
            exportPath = pwd;
        end
    catch me
        showME(me);
        exportPath = pwd;
    end
    
    set(handles.edit_export_directory,'string',exportPath,'enable','inactive');    
    set(handles.push_export_directory,'enable','on');
    
    % Start
    set(handles.push_start,'enable','off');
    
end

function initializeCallbacks(hObject)
    handles = guidata(hObject);
    set(handles.push_edf_directory,'callback',{@push_edf_directory_Callback,guidata(hObject)});
    set(handles.edit_edf_directory,'callback',{@edit_edf_directory_Callback,guidata(hObject)});
	set(handles.edit_selectPlayList,'callback',{@edit_selectPlaylist_ButtonDownFcn,guidata(hObject)});
    set(handles.button_selectChannels,'callback',@selectChannels_Callback);
    set(handles.push_method_settings,'callback',@push_exportMethodSettings_Callback);
    set(handles.menu_export_method,'callback',@push_exportMethodChangeCb);
    set(handles.edit_selectPlayList,'buttondownfcn',{@edit_selectPlayList_ButtonDownFcn,guidata(hObject)});
    set(handles.push_export_directory,'callback',{@push_export_directory_Callback,guidata(hObject)});
    set(handles.push_start,'callback',{@push_start_Callback,guidata(hObject)});
    
end

function ind= getExportMethodIndex(anyH)
    handles = guidata(anyH);
    ind = get(handles.menu_export_method,'value');
end

function setExportMethodIndex(anyH)
    handles = guidata(anyH);
    handles.user.methodSelectionIndex = getExportMethodIndex(anyH);
    guidata(anyH, handles);
end

function push_exportMethodChangeCb(hObject, ~)
    setExportMethodIndex(hObject);
end

function settingStruct = getMethodSettingsStruct(anyH)
    mInd = getExportMethodIndex(anyH);
    methodStructs = getMethodStructs(anyH);
    
    settingStruct.exportMethod = methodStructs.mfilename{mInd};
    settingStruct.editor = methodStructs.settingsEditor{mInd};
    settingStruct.curSettings = methodStructs.settings{mInd};
    settingStruct.infFilename = methodStructs.infFilename;
end

function methodStructs =  getMethodStructs(anyH)
    handles = guidata(anyH);
    methodStructs = handles.user.methodsStruct;
    methodStructs.infFilename = handles.user.exportInfFilename;
    
end

function push_exportMethodSettings_Callback(hObject,varargin)
    
    settings = getMethodSettingsStruct(hObject);
    feval(settings.editor,settings.exportMethod, settings.infFilename); %, settings.curSettings);
    
end

% --- Outputs from this function are returned to the command line.
function varargout = batch_export_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.user.settings;
delete(hObject);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on button press of buttonSelectSource
function selectChannels_Callback(hObject,varargin)
    userdata = get(hObject,'userdata');    
    outputStruct = montage_dlg(userdata.labels,userdata.selectedIndices);
            
    if(isempty(outputStruct))
        outputStruct.channels_selected= [];
    end
    userdata.selectedIndices = outputStruct.channels_selected;
    set(hObject,'userdata',userdata);
    handles = guidata(hObject);
    if(~any(userdata.selectedIndices))
        set(handles.radio_channelsAll,'value',1);
    else
        set(handles.radio_channelsSome,'value',1);
    end
end

% --- Executes on button press in push_edf_directory.
function push_edf_directory_Callback(hObject, eventdata, handles)
% hObject    handle to push_edf_directory (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)    
    
    edfPath = get(handles.edit_edf_directory,'string');
    
    if(~exist(edfPath,'file'))
        edfPath = handles.user.settings.edf_folder; %the edf folder to do a batch job on.
    end
    
    pathname = uigetfulldir(edfPath,'Select the directory containing EDF files to process');
    
    if(~isempty(pathname))
        handles.user.settings.edf_folder = pathname; %update for the next time..
        set(handles.edit_edf_directory,'string',pathname);
        handles.user.settings.edf_folder = pathname;
        guidata(hObject,handles);
        edfPathStruct = CLASS_batch.checkPathForEDFs(pathname);
        updateGUI(edfPathStruct,handles);
    else
        % The user pressed cancel and does not want tchange the pathname.
        
    end
end


% --- Executes on button press in push_export_directory.
function push_export_directory_Callback(hObject, eventdata, handles)

    exportPathname = get(handles.edit_export_directory,'string');    
    exportPathname = uigetfulldir(exportPathname,'Select the directory containing EDF files to process');
    
    if(~isempty(exportPathname))
        set(handles.edit_export_directory,'string',exportPathname);  
        handles.user.settings.output_folder = exportPathname;
        guidata(hObject,handles);
    else
        % The user pressed cancel and does not want tchange the pathname.
        
    end
end


function updateGUI(edfPathStruct,handles)
  set(handles.text_edfs_to_process,'string',edfPathStruct.statusString);
  set(handles.edit_edf_directory,'string',edfPathStruct.edfPathname);
  relevantHandles = [handles.push_start
      handles.text_edfs_to_process
      handles.edit_edf_directory
      get(handles.bg_channel_selection,'children')
      get(handles.panel_exportMethods,'children')];
  if(~isempty(edfPathStruct.edf_filename_list))
      set(relevantHandles,'enable','on');      
      
      userdata.labels = edfPathStruct.firstHDR.label;
      userdata.selectedIndices = [];

      set(handles.button_selectChannels,'userdata',userdata);
      set(handles.edit_edf_directory,'enable','inactive');      %alter this so I don't have to deal with callbacks or changes to the pathname via the edit widget, but still give some visual feedback to the effect that it is ready.
      
  else
      set(relevantHandles,'enable','off');
  end
end


% --- Executes during object creation, after setting all properties.
function edit_edf_directory_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_edf_directory (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes on button press in push_start.
function push_start_Callback(hObject, eventdata, handles)
% hObject    handle to push_start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%
%This function can only be called when there a valid directory (one which
%contains EDF files) has been selected.
%This function grabs the entries from the GUI and puts them into a settings
%struct which is then passed to the export function.
    exportSettings = getExportSettings(handles);
    outputPath = exportSettings.exportPathname;
    if(exist(outputPath,'dir'))        
        process_export(exportSettings);
    else
        warndlg(sprintf('Output path (%s) does not exist',outputPath));
    end
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
function exportSettings = getExportSettings(handles)

    method_selection_index = get(handles.menu_export_method,'value');
    methodFields = fieldnames(handles.user.methodsStruct);
    for m=1:numel(methodFields)
       fname = methodFields{m};
       methodStruct.(fname) = handles.user.methodsStruct.(fname){method_selection_index};
    end
    channelSelection.all = get(handles.radio_channelsAll,'value');
    userData = get(handles.button_selectChannels,'userdata');
    channelSelection.source = userData.labels(userData.selectedIndices);
    
    
    exportSettings.edfPathname = get(handles.edit_edf_directory,'string');
    exportSettings.edfSelectionList = [];
    exportSettings.methodStruct = methodStruct;
    exportSettings.channelSelection = channelSelection;
    exportSettings.exportPathname = get(handles.edit_export_directory,'string');
    
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
function process_export(exportSettings)    

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
                
                [~,studyInfoStruct.study_name,studyInfoStruct.study_ext] = fileparts(studyInfoStruct.edf_filename);
                files_attempted(i)=1;
                status = sprintf('%s (%i of %i)',studyInfoStruct.edf_name,i,file_count);
                waitbar(i/(file_count+1),waitbarH,status);
                
                %require stages filename to exist.                
                if(isempty(studyInfoStruct.stages_filename) || ~exist(studyInfoStruct.stages_filename,'file'))
                    files_skipped(i) = true;
                    status = sprintf('%s (%i of %i)\nStage file not found!  Skipping!',studyInfoStruct.edf_name,i,file_count);
                    waitbar(i/(file_count+1),waitbarH,status);
                else
                    
                    
                    if(strcmpi(exportSettings.methodStruct.mfilename,'export_selected_channels'))
                        status = sprintf('%s (%i of %i)',studyInfoStruct.study_name,i,file_count);
                        waitbar(i/(file_count+0.9),waitbarH,status);
                        
                        fullDestFile = fullfile(exportSettings.exportPathname,[studyInfoStruct.study_name,studyInfoStruct.study_ext]);
                        
                        didExport = CLASS_converter.writeLiteEDF(studyInfoStruct.edf_filename,fullDestFile,exportSettings.channelSelection.source); %,exportSamplerate);
                        if(didExport)
                            files_completed(i) = true;
                        else
                            files_failed(i) = true;
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
                            
                        else
                            
                            files_failed(i) = true;
                            
                        end
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


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

uiresume(hObject);

end


% --- Executes during object creation, after setting all properties.
function edit_selectPlayList_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_selectPlayList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes when selected object is changed in bg_panel_playList.
function bg_panel_playList_SelectionChangeFcn(hObject, eventdata, handles)
    % hObject    handle to the selected object in bg_panel_playList 
    % eventdata  structure with the following fields (see UIBUTTONGROUP)
    %	EventName: string 'SelectionChanged' (read only)
    %	OldValue: handle of the previously selected object or empty if none was selected
    %	NewValue: handle of the currently selected object
    % handles    structure with handles and user data (see GUIDATA)
    if(eventdata.NewValue==handles.radio_processList)
        playList = getPlaylist(handles);
        if(isempty(playList))
            playList = getPlaylist(handles,'-gui');
        end
        handles.user.playList = playList;
        checkPathForEDFs(handles,handles.user.playList);
        guidata(hObject,handles);
        
    end
end

% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over edit_selectPlayList.
function edit_selectPlayList_ButtonDownFcn(hObject, eventdata, handles)
    % hObject    handle to edit_selectPlayList (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % warndlg('This has been implemented, but not yet tested');
    
    
    % if(strcmpi('on',get(handles.radio_processList,'enable')) && get(handles.radio_processList,'value'))
    %     filenameOfPlayList = get(handles.edit_selectPlayList,'string');
    % else
    %     filenameOfPlayList = [];  %just in case this is called unwantedly
    % end
    
    filenameOfPlayList = get(handles.edit_selectPlayList,'string');
    if(~exist(filenameOfPlayList,'file'))
        filenameOfPlayList = getEDFPathname(handles);
    end
      
        
    [handles.user.playList, filenameOfPlayList] = CLASS_batch.getPlayList(filenameOfPlayList,'-gui');
    
    %update the gui
    if(isempty(handles.user.playList))
        set(handles.radio_processAll,'value',1);
        set(handles.edit_selectPlayList,'string','<click to select play list>');
    else
        setEDFPathname(handles,fileparts(filenameOfPlayList));    
        set(handles.radio_processList,'value',1);
        set(handles.edit_selectPlayList,'string',filenameOfPlayList);
    end
    
    CLASS_batch.checkPathForEDFs(getEDFPathname(handles),handles.user.playList);
    
    guidata(hObject,handles);

end
function didSet = setEDFPathname(handles,edfPath)
    if(isdir(edfPath))
        set(handles.edit_edf_directory,'string',edfPath);
        didSet = true;
    else
        didSet = false;
    end
end
function edfPathname = getEDFPathname(handles)
    edfPathname = get(handles.edit_edf_directory,'string');
end

function edit_export_directory_CreateFcn(hObject, eventdata, handles)

    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end
