function sev(varargin)
clear global;
global MARKING;
sev_pathname = sev_pathsetup();

parameters_filename = fullfile(sev_pathname,'_sev.parameters.txt');
sevFigH = sev_main();

figHandles = guidata(sevFigH);
figHandles.user.parameters_filename = parameters_filename;
guidata(sevFigH,figHandles);

try    
    MARKING = CLASS_UI_marking(sevFigH,sev_pathname,parameters_filename);
    
    
    if(numel(varargin)==1)
        if(strcmpi(varargin{1},'batch'))
            MARKING.menu_batch_run_callback();
        elseif(strcmpi(varargin{1},'init_batch_export'))
            MARKING.menu_batch_edfExport_callback();
        else
            MARKING.initializeView(); %don't want to do this if running through batch mode?
        end
    elseif(numel(varargin)>1)
        
        [path, name, ext] = fileparts(varargin{2});
        cur_filename =  strcat(name,ext);
        cur_pathname = path;
        MARKING.initializeView(); %don't want to do this if running through batch mode?
        
        MARKING.loadEDFintoSEV(cur_filename,cur_pathname);
    else
        MARKING.initializeView(); %don't want to do this if running through batch mode?
        
    end
    
catch me
    showME(me);
    fprintf(1,['The default settings file may be corrupted or inaccessible.',...
        '  This can occur when installing the software on a new computer or from editing the settings file externally.',...
        '\nChoose OK in the popup dialog to correct the settings file.\n']);
    reset_defaults_dlg(parameters_filename);
end    
end


