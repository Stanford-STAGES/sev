function exportStruct = export_selected_channels(data, params, varargin)

% initialize default parameters
defaultParams.samplerate = 0;

% return default parameters if no input arguments are provided.
if(nargin==0)
    exportStruct = defaultParams;
else
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
    
    exportStruct.data = data;    
    exportStruct.paramStruct = [];
end
end